import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from scipy.optimize import curve_fit



skiprows_next : int = 0
channels = ['fine']
timestamp = 'coarse_2025-02-20_13:34:46'
full_data = {channel: [] for channel in channels}

def get_data(skiprows : int, directory, channel) -> list[int]:
    with open(f'./data/{directory}/{channel}.txt', 'r') as f:
        data = np.loadtxt(f, dtype = str, usecols = 0, max_rows = 1000, delimiter=',', skiprows = skiprows)
        data = [int(i) for i in data]   
    return data


fig = plt.figure(figsize=(12, 12))


def update_hist(frame):

    global skiprows_next
    
    for i, channel in enumerate(channels):
        data = get_data(skiprows_next, timestamp, channel)
        if len(data) < 1000:
            return
        full_data[channel].extend(data)
    
        ax = plt.subplot(2, 2, i+1)
        
        ax.clear()
        ax.set_xlabel('bins')
        ax.set_ylabel('frequency')
        ax.hist(full_data[channel], bins=300, range=(0, 300), width=1, edgecolor = 'black', linewidth = .1)
        ax.set_xlim(-2, 300)
    skiprows_next += 1000
    plt.savefig(f'./data/{timestamp}/histogram.pdf', dpi=300)

ani = FuncAnimation(fig, update_hist, interval=.1)
plt.show()






