# COL216_CacheSimulator

## Team members  
Shreya Bhaskar - 2023CS10941  
Mannat - 2023CS10138  


## Project Overview  
This repository contains a C++ simulator for a quad-core processor's L1 data cache with MESI cache coherence protocol, along with a Python script to analyze and visualize the simulation results. The  simulator processes memory access traces for four cores, tracks performance metrics, and generates output files for analysis. The Python script (plot_results.py) creates distribution and parameter   variation plots based on the simulation outputs  

## Prerequisites

To compile and run the simulator and generate plots, ensure you have the following installed:

- **C++ Compiler**: `g++` with support for C++17 (e.g., GCC 7.0 or later)
- **Make**: For building the executable using the provided Makefile
- **Python 3**: For running the plotting script
- **Python Libraries**: Install required libraries using:
  ```bash
  pip install pandas matplotlib numpy
## Compilation

To compile the simulator, navigate to the project directory and run:

```bash
make
```
This will create an executable named L1simulate using the provided Makefile. The Makefile uses g++ with C++17 standard and optimization level -O3.  
If you need to clean up the compiled files, run:

```bash
make clean
```
## Running the Simulator 

The simulator (L1simulate) takes command-line arguments to specify the trace files, cache parameters, and output file. The general syntax is:
```bash
./L1simulate -t <trace_prefix> -s <set_bits> -E <associativity> -b <block_bits> -o <outfilename>
```
### Running Multiple Simulations for Distribution Plots
To generate data for distribution plots (10 runs with default parameters), use a loop:
```bash
```for i in {1..10}; do ./L1simulate -t app1 -s 6 -E 2 -b 5 -o output/output_run${i}.csv; done
```
This creates 10 output files (output_run1.csv to output_run10.csv) in the output/ directory

### Running Simulations for Parameter Variation
To analyze the effect of varying cache parameters (cache size, associativity, block size), run the simulator with different values for -s, -E, and -b. Example commands:

* Vary Cache Size (s=6,7,8,9 corresponding to 4KB, 8KB, 16KB, 32KB with E=2, b=5):
  
  ```bash
   ./L1simulate -t app1 -s 6 -E 2 -b 5 -o output/output_s6.csv
   ./L1simulate -t app1 -s 7 -E 2 -b 5 -o output/output_s7.csv
   ./L1simulate -t app1 -s 8 -E 2 -b 5 -o output/output_s8.csv
   ./L1simulate -t app1 -s 9 -E 2 -b 5 -o output/output_s9.csv
  ```
* Vary Associativity (E=1,2,4,8 with s=6, b=5):
     ```bash
   ./L1simulate -t app1 -s 6 -E 1 -b 5 -o output/output_E1.csv
   ./L1simulate -t app1 -s 6 -E 2 -b 5 -o output/output_E2.csv
   ./L1simulate -t app1 -s 6 -E 4 -b 5 -o output/output_E4.csv
   ./L1simulate -t app1 -s 6 -E 8 -b 5 -o output/output_E8.csv
     ```
* Vary Block Size (b=4,5,6,7 corresponding to 16B, 32B, 64B, 128B with s=6, E=2):
    ```bash
  ./L1simulate -t app1 -s 6 -E 2 -b 4 -o output/output_b4.csv
  ./L1simulate -t app1 -s 6 -E 2 -b 5 -o output/output_b5.csv
  ./L1simulate -t app1 -s 6 -E 2 -b 6 -o output/output_b6.csv
  ./L1simulate -t app1 -s 6 -E 2 -b 7 -o output/output_b7.csv
    ```
## Generating Plots
The plot_results.py script analyzes the simulation output CSV files and generates two types of plots:
* **Distribution Plots**: Boxplots showing the distribution of metrics (e.g., total instructions, miss rate, execution cycles) across 10 runs for each core.
* **Parameter Variation Plots**: Line plots showing maximum execution time versus cache size, associativity, and block size.

    
The **output/** directory contains the necessary CSV files generated from the simulation runs (e.g., output_run1.csv to output_run10.csv for distribution plots, and output_s6.csv, output_E1.csv, etc., for parameter variation plots).

### Running the Plotting Script
Navigate to the project directory and run:
```bash
python3 plot_results.py
```
This script:

Reads the output CSV files from the output/ directory

* Generates distribution plots for 10 runs and saves them as plots/distribution_plots.png.
* Generates parameter variation plots for cache size, associativity, and block size, saving them as:
* plots/parameter_plots.png (combined plot)
* plots/max_time_vs_cache_size.png (individual cache size plot)
* plots/max_time_vs_associativity.png (individual associativity plot)
* plots/max_time_vs_block_size.png (individual block size plot)

The plots/ directory is created automatically if it does not exist.
 ### Output
- Distribution Plots: A single PNG file (distribution_plots.png) with boxplots for metrics like total instructions, reads, writes, miss rate, etc., across the four cores.
- Parameter Variation Plots: Four PNG files:
- A combined plot showing maximum execution time versus each parameter.
- Three individual plots for cache size, associativity, and block size, suitable for inclusion in reports (e.g., LaTeX documents).
