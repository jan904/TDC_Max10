# Overview 
This Repo collects the code for several Variations of a TDC implemented on both a small Max10 and a Max10 Development Kit.

## Max10

### General
The Max 10 is a small, low-price FPGA. Regradless of its size and slow clock of only 12 MHz, the TDC could achieve bin sizes of
roughly 300 ps. Readout works via UART communication

To feed input signals in the Max10, a Waveform Generator was used. Connect the ground to the GND and the input to PIN_L12. Input are rectangular signals with 3.3 V. 

![My Local Image](Max10/Documentation/max1000_pinout.png)

The FPGA is programmed via JTAG. The following driver is needed: 

https://shop.trenz-electronic.de/en/Download/?path=Trenz_Electronic/Software/Drivers/Arrow_USB_Programmer


### One channel, Fine & Coarse
In the folder OneChannel_Fine_and_Coarse you find a project which implements a single delay line plus a coarse counter. The
delay line is forced to be placed in a single line to achieve optimal timing. 

The Python script read_with_coarse.py in Max10/Analysis read the data sent via UART. It creates a new folder for each measurement
and writes the fine and coarse timestamps in seperate .txt files. The name of the serial port might have to be changed.

__Important__: First start running the script, then programm the FPGA and start the measurement. Otherwise the bits are mixed up in the readout.

To analyze the fine bin distribution of the delay line, run one_channel_plot_fine. Provide it with the name of the folder you want to 
analyze. It plots a live histogram during one measurement and also saves the full histogram once closed.
