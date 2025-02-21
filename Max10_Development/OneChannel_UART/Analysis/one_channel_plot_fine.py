import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation


# Skiprows needed since the data is read in chunks of 1000 for live histogram
skiprows_next : int = 0

# Folder to read data from
timestamp = 'coarse_2025-02-21_11:20:02'

# Channels to plot
channels = ['fine']
full_data = {channel: [] for channel in channels}

# Read the data from the file in chunks of 1000
def get_data(skiprows : int, directory, channel) -> list[int]:
    with open(f'./data/{directory}/{channel}.txt', 'r') as f:
        data = np.loadtxt(f, dtype = str, usecols = 0, max_rows = 1000, delimiter=',', skiprows = skiprows)
        data = [int(i) for i in data]   
    return data


fig = plt.figure(figsize=(12, 12))

# Update the histogram with the new data
def update_hist(frame):

    global skiprows_next
    
    # If 1000 new values are found, update the histogram
    for i, channel in enumerate(channels):
        data = get_data(skiprows_next, timestamp, channel)
        if len(data) < 1000:
            return
        full_data[channel].extend(data)
    
        ax = plt.subplot(1, 1, i+1)
        
        ax.clear()
        ax.set_xlabel('bins')
        ax.set_ylabel('frequency')
        ax.hist(full_data[channel], bins=300, range=(0, 300), width=1, edgecolor = 'black', linewidth = .1)
        ax.set_xlim(-2, 300)
    skiprows_next += 1000
    
    # Save the histogram
    plt.savefig(f'./data/{timestamp}/histogram.pdf', dpi=300)

# Animate the histogram
ani = FuncAnimation(fig, update_hist, interval=.1)
plt.show()






