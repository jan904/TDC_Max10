import numpy as np
import matplotlib.pyplot as plt

# Specify the file to read
timestamp = 'coarse_2025-02-21_11:20:02'

# Read the data from the file
with open(f'./data/{timestamp}/fine.txt', 'r') as f:
    data = np.loadtxt(f, dtype = str, usecols = 0, delimiter=',')
    data = [int(i) for i in data]
    
freq = 12e6

# Find maximum bin that was filled
max_bin = np.max(data)

# Find the number of entries in each bin
_, counts = np.unique(data, return_counts=True)

# Find number of entries
entries = len(data)
bins = []

# Fill each bin with corresponding entries. Translate to ns
for i in range(max_bin):
    bins.append(counts[i]/entries * 1/freq)
    
# Rescale for better readability
bins_ns = np.array(bins) * 1e9

# Mean 
mean_width = np.mean(bins_ns)

# Plot each bin with its width
plt.bar(range(max_bin), bins_ns, width=1, edgecolor = 'black', linewidth = .5, align='edge')
plt.xlabel('Bins')
plt.ylabel('Bin width [ns]')
plt.title('Bin width in ns')
plt.legend([f'Entries = {entries} \n Max bin = {max_bin} '])
plt.savefig('bin_distr_ns.pdf', dpi=300)
plt.show()

# Plot the distribution of bin widths
plt.hist(bins_ns, range = (0, .8), bins = 30, edgecolor = 'black', linewidth = .5)
plt.xlabel('Bin width [ns]')
plt.ylabel('Entries')
plt.title('Distribution of bin widths in ns')
plt.legend([f'Mean bin width = {mean_width:.2f} ns'])
plt.savefig('bin_distr_hist_ns.pdf', dpi=300)
plt.show()
