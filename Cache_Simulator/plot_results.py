import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os

# Create output and plots directories
os.makedirs('output', exist_ok=True)
os.makedirs('plots', exist_ok=True)

# 1. Distribution plots for 10 runs
runs = range(1, 11)
# miss_rates = []
# cycles = []
metrics = {
    'Total_Instructions': [],
    'Reads': [],
    'Writes': [],
    'Total_Execution_Cycles': [],
    'Idle_Cycles': [],
    'Misses': [],
    'Miss_Rate': [],
    'Evictions': [],
    'Writebacks': [],
    'Invalidations': [],
    'Data_Traffic': []
}

# Column names for core statistics section
core_columns = [
    'Core', 'Total_Instructions', 'Reads', 'Writes', 'Total_Execution_Cycles',
    'Idle_Cycles', 'Misses', 'Miss_Rate', 'Evictions', 'Writebacks',
    'Invalidations', 'Data_Traffic'
]

for run in runs:
    try:
        # Read core statistics section (skip parameter section, read 4 rows for 4 cores)
        df_core = pd.read_csv(f'output/output_run{run}.csv', skiprows=12, nrows=4, names=core_columns, header=0)
        print(f"Run {run} core data:\n{df_core}\n")
        if len(df_core) != 4:
            raise ValueError(f"Expected 4 rows for core stats in output_run{run}.csv, got {len(df_core)}")
        for metric in metrics:
            metrics[metric].append(df_core[metric].values)
    except Exception as e:
        print(f"Error reading output_run{run}.csv: {e}")
        raise

# Transpose metrics to group by core instead of run
for metric in metrics:
    metrics[metric] = np.transpose(metrics[metric]).tolist()  # Now: 4 lists, each with 10 values
    print(f"{metric}: {len(metrics[metric])} cores, each with {len(metrics[metric][0])} values")

# Plot distributions
plt.figure(figsize=(15, 20))
for i, metric in enumerate(metrics, 1):
    plt.subplot(6, 2, i)
    plt.boxplot(metrics[metric], tick_labels=[f'Core {j}' for j in range(4)])
    plt.title(f'{metric} Distribution')
    plt.xlabel('Core')
    plt.ylabel(metric.replace('_', ' '))
    plt.tight_layout()

plt.savefig('plots/distribution_plots.png')
plt.close()


# 2. Parameter variation plots
# Cache size (corrected to actual sizes: 4, 8, 16, 32 KB for s=6,7,8,9 with E=2, b=5)
cache_sizes = [4, 8, 16, 32]  # KB
max_times_s = []
for s in [6, 7, 8, 9]:
    try:
        df = pd.read_csv(f'output/output_s{s}.csv', skiprows=18, header=0)
        max_time = float(df[df['Overall_Bus_Summary'] == 'Max_Execution_Time']['Value'].iloc[0])
        max_times_s.append(max_time)
        print(f"Cache size s={s}: Max_Execution_Time={max_time}")
    except Exception as e:
        print(f"Error reading output_s{s}.csv: {e}")
        raise

plt.figure(figsize=(12, 4))
plt.subplot(1, 3, 1)
plt.plot(cache_sizes, max_times_s, marker='o')
plt.title('Max Time vs. Cache Size')
plt.xlabel('Cache Size (KB)')
plt.ylabel('Max Execution Time (Cycles*10000000)')

# Associativity
assoc = [1, 2, 4, 8]
max_times_E = []
for E in [1, 2, 4, 8]:
    try:
        df = pd.read_csv(f'output/output_E{E}.csv', skiprows=18, header=0)
        max_time = float(df[df['Overall_Bus_Summary'] == 'Max_Execution_Time']['Value'].iloc[0])
        max_times_E.append(max_time)
        print(f"Associativity E={E}: Max_Execution_Time={max_time}")
    except Exception as e:
        print(f"Error reading output_E{E}.csv: {e}")
        raise

plt.subplot(1, 3, 2)
plt.plot(assoc, max_times_E, marker='o')
plt.title('Max Time vs. Associativity')
plt.xlabel('Associativity')
plt.ylabel('Max Execution Time (Cycles*10000000)')

# Block size
block_sizes = [16, 32, 64, 128]  # Bytes
max_times_b = []
for b in [4, 5, 6, 7]:
    try:
        df = pd.read_csv(f'output/output_b{b}.csv', skiprows=18, header=0)
        max_time = float(df[df['Overall_Bus_Summary'] == 'Max_Execution_Time']['Value'].iloc[0])
        max_times_b.append(max_time)
        print(f"Block size b={b}: Max_Execution_Time={max_time}")
    except Exception as e:
        print(f"Error reading output_b{b}.csv: {e}")
        raise

plt.subplot(1, 3, 3)
plt.plot(block_sizes, max_times_b, marker='o')
plt.title('Max Time vs. Block Size')
plt.xlabel('Block Size (Bytes)')
plt.ylabel('Max Execution Time (Cycles*10000000)')

plt.tight_layout()
plt.savefig('plots/parameter_plots.png')
plt.close()

# Individual plots for LaTeX
plt.figure(figsize=(4, 3))
plt.plot(cache_sizes, max_times_s, marker='o')
plt.title('Max Time vs. Cache Size')
plt.xlabel('Cache Size (KB)')
plt.ylabel('Max Execution Time (Cycles)')
plt.savefig('plots/max_time_vs_cache_size.png')
plt.close()

plt.figure(figsize=(4, 3))
plt.plot(assoc, max_times_E, marker='o')
plt.title('Max Time vs. Associativity')
plt.xlabel('Associativity')
plt.ylabel('Max Execution Time (Cycles*10000000)')
plt.savefig('plots/max_time_vs_associativity.png')
plt.close()

plt.figure(figsize=(4, 3))
plt.plot(block_sizes, max_times_b, marker='o')
plt.title('Max Time vs. Block Size')
plt.xlabel('Block Size (Bytes)')
plt.ylabel('Max Execution Time (Cycles*10000000)')
plt.savefig('plots/max_time_vs_block_size.png')
plt.close()