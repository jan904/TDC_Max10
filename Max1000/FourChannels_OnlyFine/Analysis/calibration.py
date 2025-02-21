import numpy as np
import matplotlib.pyplot as plt
import ROOT

freq = 12e6

# Folder
timestamp = '2024-11-25_16:35:04'

# Channels to use
channels = ['00', '01', '10', '11']

all_bins = {channel: [] for channel in channels}
all_timestamps = {channel: [] for channel in channels}
all_data = {channel: [] for channel in channels}
all_overflow = {channel: [] for channel in channels}

# Read the data from the file
def get_data(directory, channel) -> list[int]:
    with open(f'./data/{directory}/{channel}.txt', 'r') as f:
        data = np.loadtxt(f, dtype = str, usecols = 0, delimiter=',')
        data = [int(i) for i in data]   
    return data

# Calculate the calibration
def plot_calib(dir, channels):
    
    plt.figure(figsize=(12, 12))
    
    # For each channel
    for i, channel in enumerate(channels):
        
        # Read data of channel, find max bin (overflow bin)
        data = get_data(dir, channel)
        vals = np.unique(data)
        max_data = vals[-1]

        # Save data and positions of overflow bins
        all_data[channel] = data
        all_overflow[channel] = np.where(np.array(data) == max_data)[0]
        
    # Find all overflow bins across the channels
    overflow = np.unique(np.concatenate([all_overflow[channel] for channel in channels]))
    
    # Remove overflow bins in each file. Has to be done in each file to ensure that the remaining values match
    for channel in channels:
        all_data[channel] = np.delete(all_data[channel], overflow)
        
    # For each channel
    for i, channel in enumerate(channels):
        
        # Read data
        data = all_data[channel]
        entries = len(data)
        bins = []
        
        # Find unique values and counts
        vals, counts = np.unique(data, return_counts=True)
        max_data = vals[-1]

        # Fill in missing bins with 0. Nessessary to ensure that the bins are in the correct order even if one stayed empty
        full_range = np.arange(max_data)
        missing = np.setdiff1d(full_range, vals)
        for m in missing:
            counts = np.insert(counts, m, 0)
    
        # Calculate the bin width in ns
        for j in range(max_data + 1):
            bins.append((counts[j]/entries) * 1/freq)

        # Rescale for better readability
        bins = np.array(bins) * 1e9
        
        # Calculate the timestamps of each bin
        timestamps = np.cumsum(bins)
        
        # Save the data
        all_bins[channel] = bins
        all_timestamps[channel] = timestamps
        
        # Plot distribution of bin widths
        plt.subplot(2, 2, i+1)
        plt.bar(range(max_data+1), bins, width=1, edgecolor = 'black', linewidth = .5, align='edge')
        plt.xlabel('Bins')
        plt.ylabel('Bin width [ns]')
        plt.title(f'Channel {int(channel, 2)}')
        
    plt.savefig(f'./data/{timestamp}/calibration.pdf', dpi=300)
    
    return all_data, all_bins, all_timestamps


# Coincidence plot
def coincidence(timestamps, data, channels, mean):
    
    times = {channel: [] for channel in channels}
    
    lens = [len(data[channel]) for channel in channels]
    
    # For each channel
    for channel in channels:
        data[channel] = np.array(data[channel])
        
        # Cut everything longer than the shortest channel. Useful if one channel stopped earlier
        data[channel] = data[channel][:min(lens)]
        
        # Convert arrival bins to arrival times
        timestamps[channel] = np.array(timestamps[channel])
        times[channel] = timestamps[channel][data[channel]]
    
    # If mean --> Use mean of two channels and then calculate coincidence
    if mean == True:
        
        # Sync the channels. Not quite sure why channel 1 is off by one, but it is
        times['00'] = times['00'][1:]  
        times['01'] = times['01'][:-1]
        times['10'] = times['10'][:-1]
        times['11'] = times['11'][:-1]
        
        # Calculate the mean of the two channels
        mean1 = np.mean([times['00'], times['01']], axis=0)
        mean2 = np.mean([times['10'], times['11']], axis=0)
        
        # Calculate the difference
        diff = mean1 - mean2
        
    # If not mean --> Calculate the difference between the first two channels
    else:
        
        # Sync the channels, as above
        times['00'] = times['00'][1:]  
        times['01'] = times['01'][:-1]
        
        # Calculate the difference
        diff = times['00'] - times['01']
        
    # Correct for overflows
    mask = diff < 0
    diff[mask] = diff[mask] + 1/freq * 1e9
    
    mask = diff > 80
    diff[mask] = diff[mask] - 1/freq * 1e9

    # Remove outliers
    mask = diff < 3
    diff = diff[mask]
    
    # Plot the histogram of the differences (convert to ps)
    plot_hist(diff*1e3)
    
# Plot the histogram and fit a gaussian
def plot_hist(data):
    
    # Find the range of the data
    range_ = [int(np.min(data)//100 * 100) - 50 ,int((np.max(data)) + 100)//100 * 100 + 50]
    length_ = int((range_[1] - range_[0])/100)

    # Create the histogram
    hist = ROOT.TH1F('Statistics', 'Coincidence with mean', length_ + 2, range_[0] - 100, range_[1] + 100)
    
    # Fill the histogram and scale it
    for i in data:
        hist.Fill(i)
    hist.Scale(1/hist.Integral("width"))
    
    # Find the quantiles for suitable fit range (fit within 1% and 99%)
    q_ = np.zeros(2)
    hist.GetQuantiles(2, q_, np.array([0.01, 0.99]))
    q0 = q_[0]
    q1 = q_[1]
    
    # Fit the histogram with a gaussian
    func = ROOT.TF1('func', 'ROOT::Math::normal_pdf(x, [0], [1])', q0, q1)   
    func.SetParameters(hist.GetRMS(), hist.GetMean())
    func.SetParNames('#sigma', '#mu')
    hist.Fit('func', 'Q')
    
    # Plot
    fit_max = func.GetMaximum() * 1.1
    hist.GetYaxis().SetRangeUser(0, fit_max)
    hist.GetXaxis().SetTitle('Time difference [ps]')
    hist.GetYaxis().SetTitle('Abundance')
    
    ROOT.gStyle.SetOptFit(1)
    ROOT.gStyle.SetOptStat(11)
    
    c = ROOT.TCanvas('c', 'c', 800, 600)
    hist.Draw("hist")
    func.Draw('same')
    c.SaveAs(f'./data/{timestamp}/fit.pdf')
    

data_, bins_, timestamps_ = plot_calib(timestamp, channels)
coincidence(timestamps_, data_, channels, True)