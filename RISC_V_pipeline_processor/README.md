# COL216_A2

# Contributors
**Shreya Bhaskar-2023CS10941**     
**Mannat-2023CS10138**  



# RISC-V Processor Simulator 
This project implements two variants of a 5-stage pipelined RISC-V processor simulator in C++:  
Non-forwarding processor: Handles data hazards by stalling the pipeline  
Forwarding processor: Implements data forwarding to minimize stalls  
The simulator reads RISC-V assembly instructions from input files and generates pipeline diagrams showing instruction progression through each stage.  
#
## Project Structure
src/  
├── processor.hpp         # Processor architecture definition/  
├── processor.cpp         # Processor implementation/  
├── no_forward.cpp         # Non-forwarding pipeline implementation/  
├── forward.cpp           # Forwarding pipeline implementation/  
└── Makefile              # Build configuration/    

inputfiles/               # Contains test programs  
outputfiles/              # Contains generated pipeline diagrams  

## Key Features

- **Accurate 5-stage pipeline simulation** (IF, ID, EX, MEM, WB)
- **Two pipeline variants** for comparison
- **Data hazard handling** (both stalling and forwarding)
- **Control hazard handling** for branches
- **Detailed pipeline visualization**
- **Register/memory state tracking**

# Hazard Handling
Non-forwarding version: Detects hazards and inserts pipeline bubbles (stalls)  
Forwarding version: Implements forwarding paths from EX/MEM and MEM/WB stages to EX stage  

**Supported Instructions**  
**Arithmetic*: add, sub, mul, slt, addi  
**Memory*: lw, sw, lb, lh, sb , lb
**Control flow*: beq, bne, bge, bgt, jal, jalr  

# Design Decisions
## Processor Architecture (processor.cpp, processor.hpp)   
--Implements the core processor functionality, including instruction parsing and execution.  
--Uses a structured approach to store and process commands.  
--Maintains a register map to associate register names with indices.  
--Provides methods to validate registers and print register states for debugging.  
--Implements label handling for branch instructions.  
--Uses a constructCommands method to parse instructions from an input file.  
--Handles various error cases such as invalid registers, labels, or memory access. 
--Implements Register Management: Maintains a register file that is updated at the Write Back (WB) stage of execution. Each instruction modifies the appropriate registers based on the operation performed.
--Efficient Register Lookup: Uses a map-based approach to associate register names with indices, ensuring efficient access and updates.
--Debugging & State Tracking: Provides methods to print and verify register values after execution to assist in debugging and validation.

## Instruction Forwarding (forward.cpp)    
--Implements a version of the processor with instruction forwarding to reduce pipeline stalls.  
--Forwarding logic ensures that dependent instructions can execute without waiting for the previous instruction to write back.  
--Reduces execution time and improves performance by handling data hazards efficiently.    

## Non-Forwarding Execution (no_forward.cpp)  
--Implements a basic version of the processor without forwarding.      
--Introduces pipeline stalls when dependencies exist between instructions.      
--Used for comparison against the forwarding implementation to evaluate performance impact.       


## Object-Oriented Design:  
-Base processor architecture defined in processor.hpp/cpp    
-Pipeline variants inherit common functionality while implementing hazard handling differently  

**Latch Design**:
- Used structs (`IF_ID`, `ID_EX`, etc.) to represent pipeline registers  
- Each contains all signals needed between stages  
- Includes NOP flags for bubble insertion  

**Hazard Detection**:
- Implemented configurable hazard checker with different modes:

  ```cpp
  enum HazardCheckType {
      DEFAULT_STALL,    // Checks EX and MEM stages
      EX_STALL,         // Checks only MEM stage  
      LW_SW_STALL,      // Checks for load/store hazards
      BRANCH_STALL      // Full pipeline check for branches
  };

**Forwarding and stalling Implementation**:  
--Bypass paths from later stages to EX or MEM  

--Handles different forwarding scenarios (EX->EX, MEM->EX, EX-> MEM etc.)

-- created explicit **check_stall* and **check bypass** functions handling stalling/No-ops and forwarding explicitly  

# Some known issues
--Branching Not Implemented Properly: The simulator does not check whether a branch should be taken. Instead, it automatically moves to the next instruction without verifying branch conditions. This leads to incorrect execution for conditional branches (beq, bne, bge, etc.).

--Limited Instruction Set: The implementation only supports a subset of RISC-V instructions, covering arithmetic, memory, and control flow operations.

--Overlapping Instruction Representation: When multiple instructions are present in the same pipeline stage (e.g., during jal and jalr execution), the simulator only represents the latest instruction instead of keeping track of all overlapping instructions. This may lead to loss of visibility in the pipeline diagram.

Data Hazards: Complex forwarding logic required for different instruction sequences

# Sources consulted 
--https://marz.utk.edu/my-courses/cosc230/book/example-risc-v-assembly-programs/.    
    Used as a reference to understand different RISC-V instruction types and determine the necessary instructions to include in the simulator.
    
--Chat gpt 
  Consulted for explanations on RISC-V pipeline hazards, forwarding logic, instruction set coverage.
