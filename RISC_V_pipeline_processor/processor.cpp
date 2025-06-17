#include "processor.hpp"
#include <sstream>
#include <iomanip> // For std::setw



bool RISCV_Architecture::checkRegister(std::string r)
{
    return registerMap.find(r) != registerMap.end();
}



void RISCV_Architecture::printRegisters()
{
    std::cout << "Registers:\n";
    for (const auto &reg : registerMap)
     {   
       
        std::cout << reg.first << ": " << registers[reg.second] << "\n";
    }
}
void RISCV_Architecture::parseCommand(const std::string &line)
{
    // Strip comments
    // std::cout << "Line: " << line << '\n';
    std::string strippedLine = line.substr(0, line.find('#'));
    if (strippedLine.empty())
        return;

    // Split the line into tokens using a stringstream
    std::istringstream stream(strippedLine);
    std::string token;
    std::vector<std::string> tokens;

    while (stream >> token)
        tokens.push_back(token);

    // Handle empty or invalid lines
    if (tokens.size() < 2)
        return;

    // Extract the last column (instruction and operands)
    std::string instructionPart;
    for (size_t i = 1; i < tokens.size(); ++i) // Skip the first two columns (address and machine code)
    {
        if (!instructionPart.empty())
            instructionPart += " ";
        instructionPart += tokens[i];
    }
    // std::cout << "Instruction Part: " << instructionPart << '\n';

    // Tokenize the instruction part into opcode and operands
    std::istringstream instructionStream(instructionPart);
    std::vector<std::string> command;
    while (instructionStream >> token)
        command.push_back(token);

    std::cout << "Command: " << command[0] << " " << command[1] << " " << command[2] << " " <<'\n';

    // Handle labels (if the first token ends with ':')
    if (!command.empty() && command[0].back() == ':')
    {
        std::string label = command[0].substr(0, command[0].size() - 1);
        if (address.find(label) == address.end())
            address[label] = commands.size();
        else
            address[label] = -1;
        command.erase(command.begin());
    }


    


    // Resize and store the command
    if (command.size() > 4)
    {
        for (size_t i = 4; i < command.size(); ++i)
            command[3] += " " + command[i];
    }
    
    command.resize(4, ""); // Ensure the command has exactly 4 components
    commands.push_back(command);
    std::cout << "Command: " << command[0] << " " << command[1] << " " << command[2] << " " << command[3] << '\n';
}

// Construct commands from the input file
void RISCV_Architecture::constructCommands(const std::string &fileName)
{
    std::ifstream file(fileName);
    if (!file.is_open())
    {
        std::cerr << "Error: Could not open file " << fileName << "\n";
        exit(EXIT_FAILURE);
    }
    else {
        std::cout << "File opened successfully\n";
    }

    std::string line;
    while (getline(file, line))
       { std::cout << line << '\n';
        parseCommand(line);}

    file.close();
    commandCount.assign(commands.size(), 0);
}

// Handle exit codes
void RISCV_Architecture::handleExit(exit_code code, int cycleCount)
{
    std::cout << '\n';
    switch (code)
    {
    case INVALID_REGISTER:
        std::cerr << "Invalid register provided or syntax error in providing register\n";
        break;
    case INVALID_LABEL:
        std::cerr << "Label used not defined or defined too many times\n";
        break;
    case INVALID_ADDRESS:
        std::cerr << "Unaligned or invalid memory address specified\n";
        break;
    case SYNTAX_ERROR:
        std::cerr << "Syntax error encountered\n";
        break;
    case MEMORY_ERROR:
        std::cerr << "Memory limit exceeded\n";
        break;
    default:
        break;
    }

    if (code != SUCCESS)
    {
        std::cerr << "Error encountered at:\n";
        for (const auto &s : commands[PCcurr])
            std::cerr << s << ' ';
        std::cerr << '\n';
    }
}

