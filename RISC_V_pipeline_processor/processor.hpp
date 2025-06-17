#ifndef __RISCV_PROCESSOR_HPP__
 #define __RISCV_PROCESSOR_HPP__
 
 #include <unordered_map>
 #include <string>
 #include <functional>
 #include <vector>
 #include <fstream>
 #include <exception>
 #include <iostream>
 #include <iomanip> // For std::setw


struct RISCV_Architecture{

     int registers[32] = {0}, PCcurr = 0, PCnext;
    //  std::unordered_map<std::string, std::function<int(RISCV_Architecture &, std::string, std::string, std::string)>> instructions;
     std::unordered_map<std::string, int> registerMap, address;
     static const int MAX = (1 << 20);
     int data[MAX >> 2] = {0};
    //  std::unordered_map<int, int> memoryDelta;
     std::vector<std::vector<std::string>> commands;
     std::vector<int> commandCount;

     enum exit_code
     {
         SUCCESS = 0,
         INVALID_REGISTER,
         INVALID_LABEL,
         INVALID_ADDRESS,
         SYNTAX_ERROR,
         MEMORY_ERROR
    };

    RISCV_Architecture(const std::string &fileName)
    {
    constructCommands(fileName);

    for (int i = 0; i < 32; ++i)
    registerMap["x" + std::to_string(i)] = i;

    // RISC-V register ABI names
    registerMap["zero"] = 0;  // Hard-wired zero
    registerMap["ra"] = 1;    // Return address
    registerMap["sp"] = 2;    // Stack pointer
    registerMap["gp"] = 3;    // Global pointer
    registerMap["tp"] = 4;    // Thread pointer

    // Temporary registers
    registerMap["t0"] = 5;
    registerMap["t1"] = 6;
    registerMap["t2"] = 7;

    // Saved registers
    registerMap["s0"] = 8;    // Also fp (frame pointer)
    registerMap["fp"] = 8;
    registerMap["s1"] = 9;

    // Function arguments
    for (int i = 0; i < 8; ++i)
        registerMap["a" + std::to_string(i)] = i + 10;

    // More saved registers
    for (int i = 2; i < 12; ++i)
        registerMap["s" + std::to_string(i)] = i + 16;

    // More temporaries
    for (int i = 3; i < 7; ++i)
        registerMap["t" + std::to_string(i)] = i + 25;
    }
    
     // Constructor

    void printRegisters();

    bool checkRegister(std::string r);
    //  bool checkRegisters(std::vector<std::string> regs);

     // Parse and construct commands
    void parseCommand(const std::string &line);
    void constructCommands(const std::string &fileName);
 
     // Handle exit codes
    void handleExit(exit_code code, int cycleCount);
 
     // Print registers and memory changes
    //  void printRegistersAndMemoryDelta(int clockCycle);

};

 #endif