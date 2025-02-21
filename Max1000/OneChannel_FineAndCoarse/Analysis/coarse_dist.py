import numpy as np
import matplotlib.pyplot as plt

# Folder
timestamp = 'coarse_2025-02-21_11:20:02'

# Read the data from the file
with open(f'./data/{timestamp}/coarse.txt', 'r') as f:
    coarse = np.loadtxt(f, dtype = str, usecols = 0, delimiter=',')
    coarse = [int(i) for i in coarse]
    
# Calculate difference between each value pair. Translate to Hz
diff = np.array([coarse[i+1] - coarse[i] for i in range(0, len(coarse)-1)]) * 1/(12 * 10**6)
diff = 1/diff

# Remove outliers (happens when counter is reset)
diff = diff[diff < 67]
diff = diff[diff > 0]

# Plot the histogram. Result is hist with 3 peaks, meaning that we measure the frequency +- one clock cycle.
plt.hist(diff, bins=25, edgecolor = 'black', linewidth = .1, label=f'Mean: {np.mean(diff):.4f} Hz')
plt.xlabel('Frequency (Hz)')
plt.ylabel('Frequency')
plt.legend()
plt.savefig('coarse_dist.pdf', dpi=300)
plt.show()