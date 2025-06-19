# Spreadsheet Application in C

A simple spreadsheet application implemented in C, supporting formulas, dependencies, and basic spreadsheet operations. The project includes a command-line interface for interacting with the spreadsheet, as well as a test runner for automated testing.

## Features
- 2D spreadsheet with configurable rows and columns
- Cell formulas: support for arithmetic operations, MIN, MAX, AVG, SUM, STDEV, and SLEEP
- Dependency graph for recalculating dependent cells
- Cycle detection to prevent cyclic dependencies
- Error handling for invalid input and cyclic dependencies
- Command-line interface for cell editing and navigation
- Automated test runner with test case and output comparison

## File Structure
- `driver.c`: Main program entry point and user interface
- `dependency_graph_final.c/h`: Core spreadsheet logic, dependency management, and formula evaluation
- `input.c/h`: Input parsing and command processing
- `cell.h`: Cell and spreadsheet data structures
- `hash_table.c/h`: Hash table implementation for dependency management
- `display.c`: Functions for displaying the spreadsheet and cells
- `test_runner.c`: Automated test runner for validating functionality
- `Makefile`: Build and test automation
- `expected_output.txt`, `test_cases.txt`: Test data
- `status_table.txt`: Status codes and messages

## Build Instructions

1. **Build the project:**
   ```sh
   make
   ```
   This will generate the `sheet` executable and the `test_runner`.

2. **Run the spreadsheet:**
   ```sh
   ./sheet <rows> <columns>
   ```
   Example:
   ```sh
   ./sheet 6 6
   ```

3. **Run tests:**
   ```sh
   make test
   ```
   This will run the test cases and compare the output to `expected_output.txt`.

4. **Clean build files:**
   ```sh
   make clean
   ```

## Usage
- Enter cell assignments and formulas at the prompt (e.g., `A1=5`, `B2=SUM(A1:A3)`).
- Use navigation commands (`w`, `s`, etc.) to move the viewport.
- Use `q` to quit.
- Use `disable_output` and `enable_output` to control display output.

## Status Codes
See `status_table.txt` for a list of status codes and their meanings (e.g., `0 OK`, `17 cyclic dependency`).
