#include <iostream>
#include <fstream>
#include <vector>
#include <queue>
#include <map>
#include <cmath>
#include <functional>
#include <iomanip>
#include <algorithm>
#include <getopt.h>
#include <cstdint> 

// thsi is to describe the states 

enum class MESIState { INVALID, SHARED, EXCLUSIVE, MODIFIED };
// this is to update the bus opertion 
enum class BusOperation { BUS_READ, BUS_READX, BUS_UPDATE, INVALIDATE, FLUSH };


// this is the struct defining elemsents for each cache line
struct CacheLine {
    uint32_t tag;
    bool valid;
    bool dirty;
    MESIState state;
    uint32_t lru_counter;
    std::vector<uint8_t> data;
};


// this is the parameetrs for a bus transaction which is updated after snooping adn my instruction is processed accordingly 
struct BusTransaction {
    BusOperation operation;
    uint32_t address;
    int originating_core;
    int remaining_cycles;
    std::vector<uint8_t> data;
    BusTransaction() : operation(BusOperation::BUS_UPDATE), address(0), originating_core(-1), remaining_cycles(0) {}
};


// this si to keep track of statistics fo all cores throughout the process
struct CoreStats {
    uint64_t read_count = 0;
    uint64_t write_count = 0;
    uint64_t hit_count = 0;
    uint64_t miss_count = 0;
    uint64_t eviction_count = 0;
    uint64_t writeback_count = 0;
    uint64_t idle_cycles = 0;
    uint64_t total_cycles = 0;
    uint64_t invalidations = 0;
    uint64_t data_traffic = 0;
};


// this is my cache class , it includes all the parametrs along with the functions i need to access the cache and update it
// and also to handle the bus transactions
class Cache {
public:
    int core_id;
    uint32_t sets;
    uint32_t associativity;
    uint32_t block_size;
    uint32_t index_bits;
    uint32_t block_offset_bits;
    std::vector<std::vector<CacheLine>> cache_lines;
    CoreStats stats;
    uint32_t current_lru_counter;

public:
// this defines by cache basic structure with tis assosciativity adn block slze adn no. of blocks
    Cache(int id, uint32_t s, uint32_t E, uint32_t b) 
        : core_id(id), sets(1 << s), associativity(E), block_size(1 << b),
          index_bits(s), block_offset_bits(b), current_lru_counter(0) {
        cache_lines.resize(sets, std::vector<CacheLine>(associativity));
        for (auto& set : cache_lines) {
            for (auto& line : set) {
                line.valid = false;
                line.dirty = false;
                line.state = MESIState::INVALID;
                line.lru_counter = 0;
                line.data.resize(block_size);
            }
        }
    }


// this function is used for hits adn misses in my caches and return that if i need to access the bus or not , it getes retured value to function cycle

    std::pair<bool,int> access(uint32_t address, bool is_write, BusTransaction& bus_trans,bool bus_empty) {
        uint32_t tag = address >> (index_bits + block_offset_bits);
        uint32_t index = (address >> block_offset_bits) & ((1 << index_bits) - 1);
        if (index >= sets) {
            std::cerr << "Core " << core_id << ": Invalid cache index " << index << " for address 0x" << std::hex << address << std::dec << "\n";
            return {false, 1};
        }

        bus_trans.operation = BusOperation::BUS_UPDATE;

        for (auto& line : cache_lines[index]) {
            if (line.valid && line.tag == tag) {
                line.lru_counter = ++current_lru_counter;
                if (is_write) {
                    if (line.state == MESIState::SHARED) {
                        if(bus_empty){
                        bus_trans.operation = BusOperation::INVALIDATE;
                        bus_trans.address = address;
                        line.state = MESIState::MODIFIED;
                        line.dirty = true;
                        return {true, 1};
                    }
                    else {
                        line.lru_counter = --current_lru_counter;
                        bus_trans.address = address;
                        return {false, 1};
                    }
                    }
                    else {
                        line.state = MESIState::MODIFIED;
                        line.dirty = true;
                    }
                }
                return {true, 1};
            }
        }

        // stats.miss_count++;
        bus_trans.operation = is_write ? BusOperation::BUS_READX : BusOperation::BUS_READ;
        bus_trans.address = address;
        return {false, 1};
    }


    // this function is called by handle_nus_read and in this i am updating the snooping operation , i.e checking for each core it is called 
    void handle_bus_transaction(BusTransaction& trans, BusTransaction& response) {
        uint32_t tag = trans.address >> (index_bits + block_offset_bits);
        uint32_t index = (trans.address >> block_offset_bits) & ((1 << index_bits) - 1);
        if (index >= sets) {
            std::cerr << "Core " << core_id << ": Invalid bus transaction index " << index << " for address 0x" << std::hex << trans.address << std::dec << "\n";
            return;
        }

        for (auto& line : cache_lines[index]) {
            if (line.valid && line.tag == tag) {
                switch (trans.operation) {
                    case BusOperation::BUS_READ:
                        if (line.state == MESIState::MODIFIED) {
                            stats.writeback_count++;
                            response.operation = BusOperation::FLUSH;
                            response.data = line.data;
                            line.state = MESIState::SHARED;
                            // stats.data_traffic += block_size;
                        } else if (line.state == MESIState::EXCLUSIVE || line.state == MESIState::SHARED) {
                            response.data = line.data;
                            line.state = MESIState::SHARED;
                            // stats.data_traffic += block_size;
                        }
                        break;
                    case BusOperation::BUS_READX:
                        line.state = MESIState::INVALID;
                        line.valid = false;
                        if (line.dirty) {
                            stats.writeback_count++;
                            response.operation = BusOperation::FLUSH;
                            response.data = line.data;
                            // stats.data_traffic += block_size;
                        }
                        break;
                    case BusOperation::INVALIDATE:
                        line.state = MESIState::INVALID;
                        line.valid = false;
                        stats.invalidations++;
                        // stats.invalidations++;
                        break;
                    default:
                        break;
                }
                return;
            }
        }
    }


    // it is used to install the block in the cache and update the stats accordingly and also checks for cache evictions if needed 
    int install_block(uint32_t address, const std::vector<uint8_t>& data, MESIState state,  uint64_t* total_bus_traffic) {
        uint32_t tag = address >> (index_bits + block_offset_bits);
        uint32_t index = (address >> block_offset_bits) & ((1 << index_bits) - 1);
        if (index >= sets) {
            std::cerr << "Core " << core_id << ": Invalid install index " << index << " for address 0x" << std::hex << address << std::dec << "\n";
            return 0;
        }

        CacheLine* target = nullptr;
        for (auto& line : cache_lines[index]) {
            if (!line.valid) {
                target = &line;
                break;
            }
            if (!target || line.lru_counter < target->lru_counter) {
                target = &line;
            }
        }

        int eviction_cycles = 0;
        if (target->valid) {
            stats.eviction_count++;
            if (target->dirty) {
                stats.writeback_count++;
                eviction_cycles += 100;
            }
        }

        target->valid = true;
        target->tag = tag;
        target->dirty = false;
        target->state = state;
        target->lru_counter = ++current_lru_counter;
        target->data = data;
        stats.data_traffic += block_size*8;
        total_bus_traffic += block_size*8;

        return eviction_cycles;
    }
};


// this is the core class which includes the cache and the instructions queue and also the stall cycles and bus transactions
// this is the main class which is used to load the traces and run the cycles
class Core {
public:
    int id;
    Cache cache;
    std::queue<std::pair<bool, uint32_t>> instructions;
    int stall_cycles = 0;
    bool waiting_for_bus = false;
    BusTransaction pending_bus_trans;

public:
    Core(int id, uint32_t s, uint32_t E, uint32_t b) : id(id), cache(id, s, E, b) {}
// here i am loadaing the trace files along with W and R and updating the total instructions, write instructions adn read instructions
    size_t load_trace(const std::string& filename) {
        std::ifstream file(filename);
        char op;
        uint32_t addr;
        size_t count = 0;
        while (file >> op >> std::hex >> addr) {
            if (op != 'R' && op != 'W') {
                std::cerr << "Invalid operation " << op << " in " << filename << "\n";
                continue;
            }
            if(op == 'R') {
                cache.stats.read_count++;
            } else {
                cache.stats.write_count++;
            }

            instructions.emplace(op == 'W', addr);
            count++;
        }
        return count;
    }

    // it is to check if current core is stalled 
    bool is_stalled() { return stall_cycles > 0; }

    // it is check if my current core hasd further instructions to be executed or not
    bool has_next_instruction() const { return !instructions.empty(); }

    // it is called at the first and by each core , it calls access to finally  update if i got a miss or hit and returns that to run function where i process it further 
    std::pair<bool, BusTransaction> cycle(bool bus_empty) {
    if (stall_cycles >0) {
        // cache.stats.idle_cycles++;
        return {false, BusTransaction()};
    }

    if (instructions.empty()) {
        // cache.stats.idle_cycles++;
        return {false, BusTransaction()};
    }

    auto [is_write, addr] = instructions.front();
    auto [hit, latency] = cache.access(addr, is_write, pending_bus_trans,bus_empty);

    // returning updated state both in acse of hit and miss
    if (hit) {
        instructions.pop();
        cache.stats.hit_count++;
        pending_bus_trans.originating_core = id;
        return {true, pending_bus_trans};
    } else {
        pending_bus_trans.originating_core = id;
        // waiting_for_bus = true;
        return {false,pending_bus_trans};
    }
}

    int get_id() const { return id; }
};


// this is the main simulator class which includes all the cores and the bus transactions and the global cycle and the stats for each core
// this is the main class which runs the simulation and handles the bus transactions and the cores and also the stats
// in my bus i can contain only one instruction at a time 
class Simulator {
public:
    std::vector<Core> cores;
    std::queue<BusTransaction> bus_queue;
    BusTransaction current_bus_trans;
    int bus_busy_cycles = 0;
    uint64_t global_cycle = 0;
    uint64_t total_bus_transactions = 0;
    uint64_t total_invalidations = 0;
    uint64_t total_bus_traffic = 0;
    std::string trace_prefix;
    uint32_t set_index_bits;
    uint32_t associativity;
    uint32_t block_bits;
    uint32_t block_size;
    uint32_t num_sets;
    double cache_size_kb;

public:
// here it calls each core to set up its cacahe and load the traces
    Simulator(uint32_t s, uint32_t E, uint32_t b, const std::vector<std::string>& trace_files, const std::string& prefix)
        : trace_prefix(prefix), set_index_bits(s), associativity(E), block_bits(b), block_size(1 << b),
          num_sets(1 << s), cache_size_kb((1 << s) * E * (1 << b) / 1024.0) {
        for (int i = 0; i < 4; i++) {
            cores.emplace_back(i, s, E, b);
            size_t count = cores[i].load_trace(trace_files[i]);
            // std::cerr << "Core " << i << " loaded " << count << " instructions from " << trace_files[i] << "\n";
            // if (count == 0) {
            //     std::cerr << "Warning: No instructions loaded for Core " << i << "\n";
            // }
        }
    }
// it is to check at last if all cores are finished 
    bool all_cores_finished() const {
        for (const auto& core : cores) {
            if (core.has_next_instruction()) return false;
        }
        return bus_queue.empty() && bus_busy_cycles == 0;
    }

    // it is to handle the bus read and update the stats accordingly and also check for the data provided or not
    // it calls handle_bus_transactions adn it tellls it what to do, it accordingly updates the bus_busy_cyclre adn stall cyles for the required cores and also the data traffic
    // it also updates the final state of the cache line and also the data provided if any
    int handle_bus_read() {
        bool data_provided = false;
        std::vector<uint8_t> response_data;
        MESIState final_state = MESIState::SHARED;
        int total_cycles = 0;
        int installing_cycles=0;

        for (auto& core : cores) {
            if (core.get_id() == current_bus_trans.originating_core) {

                if(current_bus_trans.operation == BusOperation::INVALIDATE){
                    total_invalidations++;
                    cores[current_bus_trans.originating_core].cache.stats.invalidations++;
                    total_bus_transactions++;
                    cores[current_bus_trans.originating_core].instructions.pop();
                    // cores[current_bus_trans.originating_core].waiting_for_bus = false;
                }
                continue;
            }
            BusTransaction response;
            core.cache.handle_bus_transaction(current_bus_trans, response);

            if (current_bus_trans.operation == BusOperation::BUS_READ) {
                if (response.operation == BusOperation::FLUSH) {
                    response_data = response.data;
                    data_provided = true;
                    core.stall_cycles = 100 + 2*(block_size / 4); 
                    core.cache.stats.data_traffic += block_size*8;
                    cores[current_bus_trans.originating_core].stall_cycles = 2*(block_size / 4);
                    total_cycles += 100 + 2 * (block_size / 4);
                    final_state = MESIState::SHARED;
                    total_bus_traffic += block_size*8;
                    break;
                } else if (!response.data.empty()) {
                    response_data = response.data;
                    data_provided = true;
                    total_cycles += 2 * (block_size / 4);
                    core.cache.stats.data_traffic += block_size*8;
                    cores[current_bus_trans.originating_core].cache.stats.data_traffic += block_size*8;
                    core.stall_cycles = 2*(block_size / 4);
                    cores[current_bus_trans.originating_core].stall_cycles = 2*(block_size / 4);
                    final_state = MESIState::SHARED;
                    // total_bus_traffic += block_size;
                    break;
                }
            } else if (current_bus_trans.operation == BusOperation::BUS_READX) {
                if (response.operation == BusOperation::FLUSH) {
                    total_cycles += 100;
                    core.stall_cycles = 100;  // dusra core ko next 100 ke liye stall karna hai just chaneg it after wards 
                    core.cache.stats.data_traffic += block_size*8;
                    cores[current_bus_trans.originating_core].stall_cycles=100;
                    total_bus_traffic += block_size*8;
                }
                final_state = MESIState::MODIFIED;
            }
 
        }
        if(current_bus_trans.operation != BusOperation::INVALIDATE){
        if (!data_provided) {
            // if(current_bus_trans.originating_core ==0){
            //     printf(" i am here\n");
            // }
            response_data = std::vector<uint8_t>(block_size, 0);
            total_cycles += 100;
            cores[current_bus_trans.originating_core].cache.stats.data_traffic += block_size*8;
            cores[current_bus_trans.originating_core].stall_cycles += 100;
            final_state = (current_bus_trans.operation == BusOperation::BUS_READX) ? 
                          MESIState::MODIFIED : MESIState::EXCLUSIVE;
            total_bus_traffic += block_size;
        }

        installing_cycles += cores[current_bus_trans.originating_core].cache.install_block(
            current_bus_trans.address, response_data, final_state, & total_bus_traffic);
        total_cycles += installing_cycles;
        cores[current_bus_trans.originating_core].stall_cycles += installing_cycles;

        }

        return total_cycles;
    }

    // this is the main function which runs the simulation and handles the bus transactions and the cores and also the stats
    void run() {
        while (!all_cores_finished()) {
            // picking up each core 
            for (auto& core : cores) {
                // if it is waiting for bus , i need to update the idle cycles
                if(core.waiting_for_bus){
                    core.cache.stats.idle_cycles++;
                }
                // if(core.get_id()==0 &&core.stall_cycles>0){
                //     printf("%ld %d %d\n" , global_cycle, core.stall_cycles,bus_busy_cycles);
                // }
                // if the core is stalled , i wont be processing it and that would count in execution since stalling heer means when it is transfering block or is reading from memory 
                if (core.is_stalled()){
                    core.stall_cycles--;
                    // core.cache.stats.idle_cycles++;
                    core.cache.stats.total_cycles++;
                    continue;
                }

                // here i send  it to cycle to check for hit or miss
                auto [progress, bus_trans] = core.cycle(bus_queue.empty());
                // here i got a miss -> in this case i only need to update the invalidate operation and for that i will get the miss only if the bus is empty 
                // i reach to each core adn invalidate if the block is present there
                if(progress  && bus_trans.originating_core != -1){
                    core.cache.stats.total_cycles++;
                    if (bus_trans.operation == BusOperation::INVALIDATE) {
                        bus_queue.push(bus_trans);
                        bus_busy_cycles=1;
                        total_bus_transactions++;
                        for (auto& other_core : cores) {
                            if (other_core.get_id() != bus_trans.originating_core) {
                                BusTransaction response;
                                other_core.cache.handle_bus_transaction(bus_trans, response);
                            }
                        }
                        total_invalidations++;
                        cores[bus_trans.originating_core].cache.stats.invalidations++;
                        cores[bus_trans.originating_core].stall_cycles=0;
                        // cores[bus_trans.originating_core].instructions.pop();
                        // cores[bus_trans.originating_core].waiting_for_bus = false;
                        cores[bus_trans.originating_core].pending_bus_trans = BusTransaction();
                        
                    } 

                }
                // heer if i got a miss , i check i my bus is empty or not , if not i declare that it will now wait for bus and if yes it gets loaded ont he bus 
                else if (!progress && bus_trans.originating_core != -1) {
                    // if(core.get_id()==0){
                    //     printf("%ld %d" , global_cycle, core.stall_cycles);
                    // }
                        if (bus_queue.empty()){
                        core.cache.stats.miss_count++;
                        bus_queue.push(bus_trans);
                        total_bus_transactions++;
                        core.waiting_for_bus = false ;
                        }
                        else {
                            // printf("Core %d: Waiting for bus\n", core.get_id());
                            core.waiting_for_bus = true;
                        }
                }
            }


// here bus operates on the transactions and if it was last cycle of bus it updaets teh instruction adn pops it out since it is now processed 
            if (bus_busy_cycles > 0) {
                bus_busy_cycles--;
                if (bus_busy_cycles == 0 && current_bus_trans.originating_core != -1) {
                        bus_queue.pop();
                        auto& core = cores[current_bus_trans.originating_core];
                        if (!core.instructions.empty()) {
                            auto [is_write, addr] = core.instructions.front();
                            core.instructions.pop();
                        }
                        // core.waiting_for_bus = false;
                        core.stall_cycles=0;
                        current_bus_trans = BusTransaction();
                    }
                else if (!bus_queue.empty() && bus_busy_cycles == 0 ) {
                    bus_queue.pop();
                }
            } 
             // here it is when the bus first fetches the bus instruction and checks fo tit , snoops for it and next state are updated accordingly 
            else if (!bus_queue.empty() && bus_busy_cycles == 0) {
                current_bus_trans = bus_queue.front();
                // bus_queue.pop();
                if (current_bus_trans.originating_core < 0 || current_bus_trans.originating_core >= 4) {
                    std::cerr << "Invalid originating core " << current_bus_trans.originating_core << "\n";
                    continue;
                }
                switch (current_bus_trans.operation) {
                    case BusOperation::INVALIDATE:
                        break;
                    case BusOperation::BUS_READ:
                    case BusOperation::BUS_READX:
                        bus_busy_cycles = handle_bus_read();
                        cores[current_bus_trans.originating_core].stall_cycles=bus_busy_cycles;
                        cores[current_bus_trans.originating_core].cache.stats.data_traffic += block_size*8;
                        total_bus_traffic += block_size*8;
                        break;
                    case BusOperation::FLUSH:
                        bus_busy_cycles = 100;
                        cores[current_bus_trans.originating_core].stall_cycles=bus_busy_cycles;
                        cores[current_bus_trans.originating_core].cache.stats.data_traffic += block_size*8;   
                        total_bus_traffic += block_size*8;
                        break;
                    default:
                        std::cerr << "Invalid bus operation\n";
                        break;
                }
            }
            global_cycle++;
        }
        // for (auto& core : cores) {
        //     core.cache.stats.total_cycles = global_cycle;
        // }

    }

// updating the max execution time for each core and returning the max cycles
    uint64_t get_max_execution_time() const {
            uint64_t max_cycles = 0;
            for (const auto& core : cores) {
                max_cycles = std::max(max_cycles, core.cache.stats.total_cycles+core.cache.stats.idle_cycles);
            }
            return max_cycles;
        }
// this is used to print the stats in csv format or normal format as required
// it includes all the parameters and the stats for each core and also the overall bus summary
    void print_stats(std::ostream& out, bool csv_format) const {
    if (csv_format) {
        out << "Parameter,Value\n";
        out << "Trace_Prefix," << trace_prefix << "\n";
        out << "Set_Index_Bits," << set_index_bits << "\n";
        out << "Associativity," << associativity << "\n";
        out << "Block_Bits," << block_bits << "\n";
        out << "Block_Size_Bytes," << block_size << "\n";
        out << "Number_of_Sets," << num_sets << "\n";
        out << "Cache_Size_KB_per_core," << std::fixed << std::setprecision(2) << cache_size_kb << "\n";
        out << "MESI_Protocol,Enabled\n";
        out << "Write_Policy,Write-back Write-allocate\n";
        out << "Replacement_Policy,LRU\n";
        out << "Bus,Central snooping bus\n";
        out << "\nCore,Total_Instructions,Reads,Writes,Total_Execution_Cycles,Idle_Cycles,Misses,Miss_Rate,Evictions,Writebacks,Invalidations,Data_Traffic\n";
        for (int i = 0; i < 4; i++) {
            const auto& stats = cores[i].cache.stats;
            uint64_t total_instructions = stats.read_count + stats.write_count;
            double miss_rate = (stats.hit_count + stats.miss_count) > 0 ?
                (double)stats.miss_count / (stats.hit_count + stats.miss_count) * 100 : 0;
            out << i << ","
                << total_instructions << ","
                << stats.read_count << ","
                << stats.write_count << ","
                << stats.total_cycles << ","
                << stats.idle_cycles << ","
                << stats.miss_count << ","
                << std::fixed << std::setprecision(2) << miss_rate << ","
                << stats.eviction_count << ","
                << stats.writeback_count << ","
                << stats.invalidations << ","
                << stats.data_traffic << "\n";
        }
        out << "\nOverall_Bus_Summary,Value\n";
        out << "Total_Bus_Transactions," << total_bus_transactions << "\n";
        out << "Total_Bus_Traffic_Bytes," << total_bus_traffic << "\n";
        out << "Max_Execution_Time," << get_max_execution_time() << "\n"; // Added Max_Execution_Time
    } else {
        out << "Simulation Parameters:\n";
        out << "Trace Prefix: " << trace_prefix << "\n";
        out << "Set Index Bits: " << set_index_bits << "\n";
        out << "Associativity: " << associativity << "\n";
        out << "Block Bits: " << block_bits << "\n";
        out << "Block Size (Bytes): " << block_size << "\n";
        out << "Number of Sets: " << num_sets << "\n";
        out << "Cache Size (KB per core): " << std::fixed << std::setprecision(2) << cache_size_kb << "\n";
        out << "MESI Protocol: Enabled\n";
        out << "Write Policy: Write-back, Write-allocate\n";
        out << "Replacement Policy: LRU\n";
        out << "Bus: Central snooping bus\n";
        for (int i = 0; i < 4; i++) {
            const auto& stats = cores[i].cache.stats;
            uint64_t total_instructions = stats.read_count + stats.write_count;
            double miss_rate = (stats.hit_count + stats.miss_count) > 0 ?
                (double)stats.miss_count / (stats.hit_count + stats.miss_count) * 100 : 0;
            out << "\nCore " << i << " Statistics:\n";
            out << "Total Instructions: " << total_instructions << "\n";
            out << "Total Reads: " << stats.read_count << "\n";
            out << "Total Writes: " << stats.write_count << "\n";
            out << "Total Execution Cycles: " << stats.total_cycles << "\n";
            out << "Idle Cycles: " << stats.idle_cycles << "\n";
            out << "Cache Misses: " << stats.miss_count << "\n";
            out << "Cache Miss Rate: " << std::fixed << std::setprecision(2) << miss_rate << "%\n";
            out << "Cache Evictions: " << stats.eviction_count << "\n";
            out << "Writebacks: " << stats.writeback_count << "\n";
            out << "Bus Invalidations: " << stats.invalidations << "\n";
            out << "Data Traffic (Bytes): " << stats.data_traffic << "\n";
        }
        out << "\nOverall Bus Summary:\n";
        out << "Total Bus Transactions: " << total_bus_transactions << "\n";
        out << "Total Bus Traffic (Bytes): " << total_bus_traffic << "\n";
        out << "Maximum Execution Time: " << get_max_execution_time() << "\n"; // Added Max_Execution_Time
    }
}
};

// this is the main function which takes the command line arguments and sets up the simulator and runs it
int main(int argc, char* argv[]) {
    std::string trace_prefix;
    uint32_t s = 0, E = 0, b = 0;
    std::string outfilename;
    bool help_flag = false;

    int opt;
    while ((opt = getopt(argc, argv, "ht:s:E:b:o:")) != -1) {
        switch (opt) {
            case 'h':
                help_flag = true;
                break;
            case 't':
                trace_prefix = optarg;
                break;
            case 's':
                try {
                    s = std::stoul(optarg);
                } catch (...) {
                    std::cerr << "Error: Invalid value for -s\n";
                    return 1;
                }
                break;
            case 'E':
                try {
                    E = std::stoul(optarg);
                } catch (...) {
                    std::cerr << "Error: Invalid value for -E\n";
                    return 1;
                }
                break;
            case 'b':
                try {
                    b = std::stoul(optarg);
                } catch (...) {
                    std::cerr << "Error: Invalid value for -b\n";
                    return 1;
                }
                break;
            case 'o':
                outfilename = optarg;
                break;
            default:
                std::cerr << "Usage: " << argv[0] << " -t <trace_prefix> -s <set_bits> -E <associativity> -b <block_bits> [-o <outfilename>] [-h]\n";
                return 1;
        }
    }

    if (help_flag) {
        std::cout << "Usage: " << argv[0] << " -t <trace_prefix> -s <set_bits> -E <associativity> -b <block_bits> [-o <outfilename>] [-h]\n"
                  << "-t <tracefile>: name of parallel application (e.g., app1)\n"
                  << "-s <s>: number of set index bits (sets = 2^s)\n"
                  << "-E <E>: associativity (lines per set)\n"
                  << "-b <b>: number of block bits (block size = 2^b)\n"
                  << "-o <outfilename>: log output to file\n"
                  << "-h: print this help message\n";
        return 0;
    }

    if (trace_prefix.empty() || s == 0 || E == 0 || b == 0) {
        std::cerr << "Error: Missing required arguments\n"
                  << "Usage: " << argv[0] << " -t <trace_prefix> -s <set_bits> -E <associativity> -b <block_bits> [-o <outfilename>] [-h]\n";
        return 1;
    }

    std::vector<std::string> trace_files = {
        trace_prefix + "_proc0.trace",
        trace_prefix + "_proc1.trace",
        trace_prefix + "_proc2.trace",
        trace_prefix + "_proc3.trace"
    };

    for (const auto& file : trace_files) {
        std::ifstream f(file);
        if (!f.good()) {
            std::cerr << "Error: Trace file " << file << " does not exist or cannot be opened\n";
            return 1;
        }
    }

    Simulator simulator(s, E, b, trace_files, trace_prefix);
    simulator.run();

    if (!outfilename.empty()) {
        std::ofstream outfile(outfilename);
        if (!outfile) {
            std::cerr << "Error: Cannot open output file " << outfilename << "\n";
            return 1;
        }
        simulator.print_stats(outfile, true);
        outfile.close();
    }
    simulator.print_stats(std::cout, false);

    return 0;
}