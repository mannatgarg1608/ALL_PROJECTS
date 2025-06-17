// --------------------- Header Files ------------------------------------------
#include "./processor.hpp"
#include <string>
#include <functional>
#include <filesystem>
#include <fstream>
// --------------------- Structures of Latches ---------------------------------
// The latch after the IF stage
struct IF_ID
{
	std::vector<std::string> command = {"", "", "", ""};
	int PCnext=0;
	bool nop_sw = false;
	bool nop;
};

// The latch after the ID stage
struct ID_EX
{
	std::vector<std::string> command = {"", "", "", ""};
	int PCnext =0;
	int store_address;

	std::string rd = "";
	std::string rs = "";
	int ReadData1;
	std::string rt = "";
	int ReadData2;
	std::string offset;


	bool MemRead;
	bool MemWrite;
	bool writeRegister;
	int type;
 
	bool nop;
};

// The latch after the EX stage
struct EX_MEM
{
	std::vector<std::string> command = {"", "", "", ""};
	int PCnext;
	int store_address;

	int ALUresult;
	std::string rd;
	std::string rt;
	// std::string return_address;

	int MemRead;
	int MemWrite;
	int writeRegister;

	bool nop;
};

// The latch after the MEM stage
struct MEM_WB
{
	std::vector<std::string> command = {"", "", "", ""};
	int PCnext;
	int store_address;

	std::string rd;
	int ALUresult;

	int writeRegister;

	bool nop;
};

// The state of the processor
struct state
{
	bool to_fetch = true; // for the branches and jumps
	IF_ID if_id;
	ID_EX id_ex;
	EX_MEM ex_mem;
	MEM_WB mem_wb;

	std::vector<std::vector<std::string>> pipelineTable;
};
constexpr unsigned int strHash(const char* str, int h = 0) {
    return !str[h] ? 5381 : (strHash(str, h + 1) * 33) ^ str[h];
}
enum HazardCheckType {
    DEFAULT_STALL,    // Checks EX and MEM stages (original check_stall)
    EX_STALL,         // Checks only MEM stage (original check_stall_ex)
    LW_SW_STALL,      // Checks EX and MEM stages for rt only (original check_stall_lw_sw)
    BRANCH_STALL      // Checks ID, EX, and MEM stages (original check_stall_bq)
};

bool check_stall(const std::string& rs, const std::string& rt, state& s, HazardCheckType type = DEFAULT_STALL) {
    bool hazard = false;
    
    auto check_register = [&](const std::string& reg) {
        if (reg.empty() || reg.find('(') != std::string::npos) {
            return false; // Not a valid register
        }
        
        bool local_hazard = false;
        
        switch (type) {
            case EX_STALL:
                // Only check MEM stage
                local_hazard = s.mem_wb.writeRegister && s.mem_wb.rd == reg;
                break;
                
            case LW_SW_STALL:
                // Check EX and MEM stages (but this type is only called for rt)
                local_hazard = (s.ex_mem.writeRegister && s.ex_mem.rd == reg) || 
                              (s.mem_wb.writeRegister && s.mem_wb.rd == reg);
                break;
                
            case BRANCH_STALL:
                // Check ID, EX, and MEM stages
                local_hazard = (s.id_ex.writeRegister && s.id_ex.rd == reg) ||
                              (s.ex_mem.writeRegister && s.ex_mem.rd == reg) || 
                              (s.mem_wb.writeRegister && s.mem_wb.rd == reg);
                break;
                
            case DEFAULT_STALL:
            default:
                // Check EX and MEM stages
                local_hazard = (s.ex_mem.writeRegister && s.ex_mem.rd == reg) || 
                              (s.mem_wb.writeRegister && s.mem_wb.rd == reg);
                break;
        }
        
        return local_hazard;
    };

    // For LW_SW_STALL, we only check rt (as in original check_stall_lw_sw)
    if (type == LW_SW_STALL) {
		if (!rt.empty()) hazard = check_register(rt);
    } 
	else if (type == EX_STALL){
		if (!rs.empty()) hazard = check_register(rs);
	}
    else {
        // For all other types, check both registers
        if (!rs.empty()) hazard = hazard || check_register(rs);
        if (!rt.empty()) hazard = hazard || check_register(rt);
    }

    return hazard;
}


// --------------------- Fetch Stage ------------------------------------------
int IF(struct RISCV_Architecture *arch, state &s)
{
	// If can be fetched
	if (s.to_fetch)
	{
		// PC is less than max size
		if (arch->PCcurr < arch->commands.size())
		{    
	

			s.if_id.command = arch->commands[arch->PCcurr];
			//std::cout << s.if_id.command[0] <<"I was in IF" << std::endl;
			s.if_id.PCnext = arch->PCcurr; // Points to itself
			arch->PCnext = arch->PCcurr + 1;  
	
		    s.if_id.nop = false;

		}
		else
		{  
			// std::cout<<"hello"  << std::endl;
			s.if_id.nop = true;
		}
	}
	else
	{
		s.if_id.nop = true;
	}


	if (s.if_id.command[0] == "beq" || s.if_id.command[0] == "bne" || s.if_id.command[0] =="bgt" || s.if_id.command[0]=="bge")
		{
			if (check_stall(s.if_id.command[1],s.if_id.command[2], s,BRANCH_STALL))
			{   //std :: cout << "Stalled_bq" << std ::endl;
				arch->PCcurr = s.if_id.PCnext;
				arch->PCnext = arch->PCcurr;
				// std::cout << "Stalled" << std::endl;
				s.to_fetch = true;
				return 0;
			}
			
		}
		
}

// --------------------- Decode Stage -----------------------------------------
int ID(struct RISCV_Architecture *arch, state &s)
{   
	
	if (s.if_id.nop)
	{
		s.id_ex.command = s.if_id.command;
		s.id_ex.PCnext = s.if_id.PCnext; // Points to itself
		s.id_ex.nop = true;
		s.id_ex.rd = "";
		s.id_ex.rs = "";
		s.id_ex.rt = "";


		s.if_id.command = {"", "", "", ""};
        
		return 0;
	}
   
	//std :: cout << "ID_entered " << std :: endl;
	
	if((s.ex_mem.nop) && (s.ex_mem.command[0] == "sw"||s.ex_mem.command[0] == "sb") && check_stall(s.ex_mem.rd,s.ex_mem.rt, s,EX_STALL)){
		// update nothing
		s.id_ex.command = s.ex_mem.command; // Copying the command
		s.id_ex.PCnext =s.ex_mem.PCnext;
	}
	else {
		s.id_ex.command = s.if_id.command; // Copying the command
		s.id_ex.PCnext = s.if_id.PCnext;   // Points to itself

	}
		// Setting the registers
		// s.pipelineTable[s.id_ex.PCnext][arch->commandCount[s.id_ex.PCnext]] = "ID";

		s.id_ex.rd = s.id_ex.command[1];
		s.id_ex.rs = s.id_ex.command[2];
		s.id_ex.rt = s.id_ex.command[3];
	

	   s.id_ex.nop = false;			   // Not a nop

	//std :: cout << s.if_id.command[0] <<  "I was in ID "<< std :: endl;
    unsigned int hash = strHash(s.id_ex.command[0].c_str());
	switch (hash) {
    case strHash("add"):
    case strHash("sub"):
    case strHash("mul"):
    case strHash("slt"):
	case strHash("sll"):
        s.id_ex.ReadData1 = arch->registers[arch->registerMap[s.id_ex.rs]];
        s.id_ex.ReadData2 = arch->registers[arch->registerMap[s.id_ex.rt]];
        s.id_ex.type = 0;
        break;

    case strHash("addi"):
	case strHash("slli"):
        s.id_ex.ReadData1 = arch->registers[arch->registerMap[s.id_ex.rs]];
        s.id_ex.ReadData2 = std::stoi(s.id_ex.rt);
        s.id_ex.type = 1;
        break;

    case strHash("lw"):
    case strHash("sw"):
    case strHash("lb"):
    case strHash("sb"):
        {
            // Separating register from offset
            std::string location = s.id_ex.rs;
            int lparen = location.find('(');
            s.id_ex.offset = (lparen == 0 ? "0" : location.substr(0, lparen));
            s.id_ex.rt = location.substr(lparen + 1, location.length() - lparen - 2);

            s.id_ex.ReadData1 = arch->registers[arch->registerMap[s.id_ex.rd]]; // Value to store/update
            s.id_ex.ReadData2 = arch->registers[arch->registerMap[s.id_ex.rt]] + std::stoi(s.id_ex.offset); // Memory address
            if (s.id_ex.ReadData2 > arch->MAX >> 2) return 3;
            s.id_ex.type = 2;
        }
        break;

    case strHash("beq"):
    case strHash("bne"):
    case strHash("bge"):
    case strHash("bgt"):
        s.id_ex.type = 3;
        s.id_ex.ReadData1 = arch->registers[arch->registerMap[s.id_ex.rd]];
        s.id_ex.ReadData2 = arch->registers[arch->registerMap[s.id_ex.rs]];
        break;

    case strHash("jal"):
        s.id_ex.type = 4;
        s.id_ex.offset = s.id_ex.rs; // Offset is in rs (2nd operand)
        arch->PCcurr = s.id_ex.PCnext + std::stoi(s.id_ex.offset) / 4;
        arch->PCnext = arch->PCcurr;
        s.to_fetch = false; // Pause fetching
        break;

    case strHash("jalr"):
        s.id_ex.type = 4;
        {
            std::string location = s.id_ex.rs;
            int lparen = location.find('(');
            s.id_ex.offset = (lparen == 0 ? "0" : location.substr(0, lparen));
            s.id_ex.rt = location.substr(lparen + 1, location.length() - lparen - 2);

            arch->PCcurr = s.id_ex.PCnext + (arch->registers[arch->registerMap[s.id_ex.rt]] + std::stoi(s.id_ex.offset)) / 4;
            arch->PCnext = arch->PCcurr;
            s.to_fetch = false; // Pause fetching
        }
        break;

    default:
        // Handle unknown opcodes (optional)
        break;
}


	// Setting the control signals200
	if (s.id_ex.command[0] == "lw"||s.id_ex.command[0] == "lb")
	{
		s.id_ex.MemRead = 1;
		s.id_ex.MemWrite = 0;
		s.id_ex.writeRegister = 1;
	}
	else if (s.id_ex.command[0] == "sw"||s.id_ex.command[0] == "sb")
	{
		s.id_ex.MemRead = 0;
		s.id_ex.MemWrite = 1;
		s.id_ex.writeRegister = 0;
	}
	else if (s.id_ex.type != 3)
	{
		s.id_ex.MemRead = 0;
		s.id_ex.MemWrite = 0;
		s.id_ex.writeRegister = 1;
	}
	else
	{
		s.id_ex.MemRead = 0;
		s.id_ex.MemWrite = 0;
		s.id_ex.writeRegister = 0;
	}

	// // Stalling Check
	if (s.id_ex.command[0] == "lw"||s.id_ex.command[0] == "lb" )
	{
		if (check_stall(s.id_ex.rd,s.id_ex.rt, s,LW_SW_STALL))
		{
			s.id_ex.nop = true;
			arch->PCcurr = s.id_ex.PCnext;
			arch->PCnext = arch->PCcurr;
			// std::cout << "Stalled" << std::endl;
		}
	}
	else if (s.id_ex.command[0] == "sw"||s.id_ex.command[0]=="sb")
	{
		if (check_stall(s.id_ex.rd,s.id_ex.rt, s,LW_SW_STALL))
		{
			s.id_ex.nop = true;
			arch->PCcurr = s.id_ex.PCnext;
			arch->PCnext = arch->PCcurr;
			std::cout << "Stalled" << std::endl;
		}
	}
	else if (s.id_ex.command[0] == "beq" || s.id_ex.command[0] == "bne" || s.id_ex.command[0] =="bgt" || s.id_ex.command[0]=="bge")
	{
       // has to be doen before ID stage 
	}
	else if (s.id_ex.command[0] == "jal" || s.id_ex.command[0] == "jalr")
	{
		// no register to check
	}
	else if (check_stall(s.id_ex.rs,s.id_ex.rt, s,DEFAULT_STALL))
	{
		s.id_ex.nop = true;
		arch->PCcurr = s.id_ex.PCnext;
		arch->PCnext = arch->PCcurr;
		// std::cout << "Stalled";
	}

	if(s.ex_mem.nop && (s.id_ex.command[0] == "sw"||s.ex_mem.command[0] == "sb") && check_stall(s.id_ex.rd,s.id_ex.rt, s,EX_STALL)){
		arch->PCcurr = s.if_id.PCnext;
		arch->PCnext = arch->PCcurr;

	}


}

// ---------------------------- Execution Stage -------------------------------
int EX(struct RISCV_Architecture *arch, state &s)
{   
	// std::cout << "EX" << std::endl;
	if (s.id_ex.nop)
	{   
		s.ex_mem.command = s.id_ex.command;
		s.ex_mem.PCnext = s.id_ex.PCnext; // Points to itself
		s.ex_mem.nop = true;
		s.ex_mem.writeRegister = false;
		s.ex_mem.MemWrite = false;
		s.ex_mem.MemRead = false;

		s.id_ex.command = {"", "", "", ""};
		s.id_ex.rd = "";
		s.id_ex.rs = "";
		s.id_ex.rt = "";

		return 0;
	}
	  


	std :: cout << s.id_ex.command[0] <<  "I was in EX "<< std :: endl;
	// Calculating the ALUresult
	switch (s.id_ex.type) {
    case 0:  // R-type instructions (add, sub, mul, slt)
        {
            // Hash the command string for switch-case (since C++ doesn't support string switches)
            unsigned int cmdHash = strHash(s.id_ex.command[0].c_str());
            switch (cmdHash) {
                case strHash("add"):
                    s.ex_mem.ALUresult = s.id_ex.ReadData1 + s.id_ex.ReadData2;
                    break;
                case strHash("sub"):
                    s.ex_mem.ALUresult = s.id_ex.ReadData1 - s.id_ex.ReadData2;
                    break;
                case strHash("mul"):
                    s.ex_mem.ALUresult = s.id_ex.ReadData1 * s.id_ex.ReadData2;
                    break;
                case strHash("slt"):
                    s.ex_mem.ALUresult = s.id_ex.ReadData1 < s.id_ex.ReadData2;
                    break;
				case strHash("sll"):
                    s.ex_mem.ALUresult = s.id_ex.ReadData1 << s.id_ex.ReadData2;
                    break;
                default:
                    // Handle unknown R-type commands (optional)
                    break;
            }
        }
        break;

    case 1:  // addi (I-type)
       {

        unsigned int cmdHash = strHash(s.id_ex.command[0].c_str());
        switch (cmdHash) {
            case strHash("addi"):
                s.ex_mem.ALUresult = s.id_ex.ReadData1 + s.id_ex.ReadData2;
                break;
            case strHash("slli"):
                s.ex_mem.ALUresult = s.id_ex.ReadData1 << s.id_ex.ReadData2;
                break;
            default:
                // Handle unknown R-type commands (optional)
            break;
        }
       }
	   break;
    case 2:  // Memory ops (lw, sw, lb, lh, sb)
        s.ex_mem.ALUresult = s.id_ex.ReadData2;  // Memory address
        break;

    case 3:  // Branch instructions (beq, bne, bge, bgt)
        // No ALU action needed here (handled in branch logic)
        break;

    case 4:  // Jump instructions (jal, jalr)
        {
            unsigned int cmdHash = strHash(s.id_ex.command[0].c_str());
            switch (cmdHash) {
                case strHash("jal"):
                    s.ex_mem.store_address = s.id_ex.PCnext + std::stoi(s.id_ex.offset) / 4;
                    s.ex_mem.ALUresult = s.id_ex.PCnext + 1;  // Return address (PC+4)
                    break;
                case strHash("jalr"):
                    s.ex_mem.store_address = s.id_ex.PCnext + 
                                             (arch->registers[arch->registerMap[s.id_ex.rt]] + 
                                             std::stoi(s.id_ex.offset)) / 4;
                    s.ex_mem.ALUresult = s.id_ex.PCnext + 1;  // Return address (PC+4)
                    break;
                default:
                    // Handle unknown jump commands (optional)
                    break;
            }
        }
        break;

    default:
        // Handle unknown instruction types (optional)
        break;
}


	// Setting the control signals
	s.ex_mem.command = s.id_ex.command;


	s.ex_mem.PCnext = s.id_ex.PCnext;
    s.ex_mem.rt= s.id_ex.rt;
	s.ex_mem.rd = s.id_ex.rd;
	s.ex_mem.MemRead = s.id_ex.MemRead;
	s.ex_mem.MemWrite = s.id_ex.MemWrite;
	s.ex_mem.writeRegister = s.id_ex.writeRegister;

	s.ex_mem.nop = false;

	
		
	if ((s.ex_mem.command[0] == "sw"||s.ex_mem.command[0] == "sb") && check_stall(s.ex_mem.rd,s.ex_mem.rt, s,EX_STALL))
	{  
		s.ex_mem.nop = true;
		// arch->PCcurr = s.ex_mem.PCnext;
		std ::cout << s.ex_mem.PCnext << std ::endl;
		// arch->PCnext = arch->PCcurr;
		std::cout << "Stalled2" << std::endl;
	
		
	}

		

	// s.pipelineTable[s.ex_mem.PCnext][arch->commandCount[s.ex_mem.PCnext]] = "EX";
}

// ---------------------------- Memory stage ----------------------------
int MEM(struct RISCV_Architecture *arch, state &s)
{
	// If the previous stage is a nop, then this stage is a nop
	if (s.ex_mem.nop)
	{
		s.mem_wb.command = s.ex_mem.command;
		s.mem_wb.PCnext = s.ex_mem.PCnext; // Points to itself
		s.mem_wb.store_address = s.ex_mem.store_address;
		s.mem_wb.ALUresult = s.ex_mem.ALUresult;
		s.mem_wb.nop = true;
		s.mem_wb.writeRegister = false;

		s.ex_mem.command = {"", "", "", ""};
		s.ex_mem.rd = "";
		s.ex_mem.rt = "";
        std ::cout << s.mem_wb.PCnext << " I was noped"<< std ::endl;
		return 0;
	}


	std :: cout << s.ex_mem.command[0] <<  "I was in MEM "<< std :: endl;
	// Uses control signals to determine what to do
	if (s.ex_mem.MemRead)
	{  
		std ::cout<< "yes i was here "<<"\n";
		s.mem_wb.ALUresult = arch->data[s.ex_mem.ALUresult];
	}
	else if (s.ex_mem.MemWrite)
	{  
		std ::cout<< "yes i was not here "<<"\n";
		std::string r = s.ex_mem.rd;
		int address = s.ex_mem.ALUresult;
        std ::cout<< address <<"\n";
		// if (!arch->checkRegister(r))
		// 	return 1;

		// if (arch->data[address] != arch->registers[arch->registerMap[r]])
		// 	arch->memoryDelta[address] = arch->registers[arch->registerMap[r]];
		arch->data[address] = arch->registers[arch->registerMap[r]];
	}
	else if (s.ex_mem.command[0] == "beq" || s.ex_mem.command[0] == "bne" || s.ex_mem.command[0] == "bge" || s.ex_mem.command[0] == "bgt")
	{
	
	}
	else if (s.ex_mem.command[0]=="jal" || s.ex_mem.command[0]=="jalr")
	{
		
		// s.to_fetch = true;
	}
	else
		s.mem_wb.ALUresult = s.ex_mem.ALUresult;

	// Setting the control signals
	s.mem_wb.command = s.ex_mem.command;
	s.mem_wb.PCnext = s.ex_mem.PCnext;

	s.mem_wb.writeRegister = s.ex_mem.writeRegister;
	s.mem_wb.rd = s.ex_mem.rd;

	s.mem_wb.nop = false;

	// s.pipelineTable[s.mem_wb.PCnext][arch->commandCount[s.mem_wb.PCnext]] = "MEM";
}

// ---------------------------- Writeback stage ----------------------------
int WB(struct RISCV_Architecture *arch, state &s)
{
	// If the previous stage is a nop, then this stage is a nop
	if (s.mem_wb.nop)
	{
		s.mem_wb.command = {"", "", "", ""};
		return 0;
	}
	std :: cout << s.mem_wb.command[0] <<  "I was in WB "<< std :: endl;
	// if writeRegister is true, then write the value to the register
	if (s.mem_wb.writeRegister)
	{
		std::string r = s.mem_wb.rd;
		int value = s.mem_wb.ALUresult;

		if (!arch->checkRegister(r))
			return 1;

		arch->registers[arch->registerMap[r]] = value;


	}

	// s.pipelineTable[s.mem_wb.PCnext][arch->commandCount[s.mem_wb.PCnext]] = "WB";
}


void printPipelineTable(const std::vector<std::vector<std::string>> &pipelineTable, const std::vector<std::vector<std::string>> &commands, int clockCycles, std::ofstream &outputFile)
{
    // Iterate through each instruction and its pipeline stages
    for (size_t i = 0; i < pipelineTable.size(); ++i)
    {
        // Print the instruction
        outputFile << commands[i][0] << " " << commands[i][1] << " " << commands[i][2] << " " << commands[i][3] << ";";

        // Print the pipeline stages for the instruction
        for (size_t j = 0; j < clockCycles; ++j)
        {
            if (!pipelineTable[i][j].empty())
            {
                if (j > 0 && pipelineTable[i][j] == pipelineTable[i][j - 1])
                {
                    outputFile << "-";
                }
                else
                {
                    outputFile << pipelineTable[i][j];
                }
            }
            else
            {
                outputFile << "  "; // Print a dash for stalls or empty cycles
            }

            if (j < clockCycles - 1)
            {
                outputFile << ";"; // Separate stages with semicolons
            }
        }

        outputFile << "\n"; // Move to the next instruction
    }
}





// ---------------------------- Execute commands ----------------------------

	// If the number of commands is greater than the maximum number of commands allowed, then exit
void executeCommandsPipelined(struct RISCV_Architecture *arch, int cycleCount, std::ofstream &outputFile)
{   


	 // Initialize the variables
	 int clockCycles = 0;
	 state s;
	 s.to_fetch = true;
	 s.if_id.nop = false;
	 s.id_ex.nop = true;
	 s.ex_mem.nop = true;
	 s.mem_wb.nop = true;
 
	 // Resize the pipeline table to store pipeline stages
	 s.pipelineTable.resize(arch->commands.size(), std::vector<std::string>(cycleCount+5));
 
	 // Print the initial state of registers
	//  std::cout << "Initial Registers:\n";
	//  arch->printRegisters();

	int if_index = -1, id_index = 0, ex_index = -1, mem_index = -1, wb_index = -1;
 
	 // While the program is not finished, keep executing commands
	 while ((arch->PCcurr < arch->commands.size()) || !(s.if_id.nop && s.id_ex.nop && s.ex_mem.nop && s.mem_wb.nop))
	 {

        if(clockCycles > cycleCount){
			break;
		}
		 
		
		 ++clockCycles;
		 std::cout << "\nClock Cycle: " << clockCycles << "\n";
		 std::cout << arch->PCcurr << "\n";
		 std::cout << arch->PCnext << "\n";

		 // Write Back Stage
		 if (!s.mem_wb.nop)
		 {
			 wb_index = s.mem_wb.PCnext;
			 s.pipelineTable[wb_index][clockCycles - 1] = "WB";
		 }
        std :: cout << "WB" << std ::endl;
		 // Memory Stage
		 if (!s.ex_mem.nop)
		 {
			 mem_index = s.ex_mem.PCnext;
			 s.pipelineTable[mem_index][clockCycles - 1] = "MEM";
		 }
		std :: cout << "MEM" << std ::endl;
		 // Execute Stage
		 if (!s.id_ex.nop)
		 {
			 ex_index = s.id_ex.PCnext;
			 s.pipelineTable[ex_index][clockCycles - 1] = "EX";
		 }
        std :: cout << "EX" << std ::endl;
		 // Decode Stage
		 if (!s.if_id.nop)
			{
				id_index = s.if_id.PCnext;
				if (id_index >= 0 && id_index < s.pipelineTable.size() && clockCycles - 1 >= 0 && clockCycles - 1 < s.pipelineTable[0].size())
				{
					s.pipelineTable[id_index][clockCycles - 1] = "ID";
				}
				
			}
        std :: cout << "ID" << std ::endl;
		 // Fetch Stage
		 if (s.to_fetch && arch->PCcurr < arch->commands.size())
		 {
			 if_index = arch->PCcurr;
			 s.pipelineTable[if_index][clockCycles - 1] = "IF";
		 }

 
		 // Execute pipeline stages in reverse order
		 WB(arch, s);  // Write Back
		 MEM(arch, s); // Memory Access
		 EX(arch, s);  // Execute
		 ID(arch, s);  // Instruction Decode
		 IF(arch, s);  // Instruction Fetch
         s.to_fetch = true;
		 // Print the current state of registers after each cycle
		// arch->printRegisters();

		 arch->PCcurr = arch->PCnext;
	 }
 
	 // Print the final pipeline table
	 printPipelineTable(s.pipelineTable, arch->commands, cycleCount,outputFile);
 
	 // Handle successful execution
	 arch->handleExit(arch->SUCCESS, clockCycles);
}

// ---------------------------- Main ----------------------------
int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        std::cerr << "Required arguments: file_name cycle_count\n./noforward <file name> <cycle count>\n";
        return 0;
    }
    
    std::string fileName = argv[1];
    int cycleCount = std::stoi(argv[2]);
    
    // Platform-independent directory creation
    #if defined(__APPLE__)
        // macOS specific filesystem namespace
        std::__fs::filesystem::create_directory("outputfiles");
    #elif __has_include(<filesystem>)
        // Standard C++17 filesystem
        std::filesystem::create_directory("outputfiles");
    #elif __has_include(<experimental/filesystem>)
        // Experimental filesystem (pre-C++17)
        std::experimental::filesystem::create_directory("outputfiles");
    #else
        // Fallback using system command
        system("mkdir -p outputfiles");
    #endif

    // Extract base filename without extension
    size_t lastSlash = fileName.find_last_of("/\\");
    std::string baseName = (lastSlash == std::string::npos) ? fileName : fileName.substr(lastSlash + 1);
    size_t dotPos = baseName.find_last_of(".");
    if (dotPos != std::string::npos) {
        baseName = baseName.substr(0, dotPos);
    }

    // Create output filename
    std::string outputFileName = "outputfiles/" + baseName + "_noforward_out.txt";

    // Open output file
    std::ofstream outFile(outputFileName);
    if (!outFile.is_open()) {
        std::cerr << "Error: Could not open output file " << outputFileName << std::endl;
        return 1;
    }
    
    RISCV_Architecture *riscv = new RISCV_Architecture(fileName);
    executeCommandsPipelined(riscv, cycleCount, outFile);
    outFile.close();

    std::cout << "Output written to " << outputFileName << std::endl;
    return 0;
}