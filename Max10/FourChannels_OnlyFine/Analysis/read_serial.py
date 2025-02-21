import serial
import matplotlib.pyplot as plt
import time
import datetime
import os

# Open the serial port
ser = serial.Serial(port = '/dev/serial/by-id/usb-Arrow_Arrow_USB_Blaster_TEI0001_ARA27238-if01-port0', baudrate = 115200, bytesize=8)

timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
output_dec = " "
parity = 0

# Create a directory to store the output files
directory = "./data/" + timestamp
os.mkdir(directory)
with open(f'{directory}/00.txt', 'a') as f:
    f.write('')
with open(f'{directory}/01.txt', 'a') as f:
    f.write('')
with open(f'{directory}/10.txt', 'a') as f:
    f.write('')
with open(f'{directory}/11.txt', 'a') as f:
    f.write('')

# Use time to read for certain amount of time
runtime_mins = 1000  # mins
start_time = time.time()
runtime_secs = runtime_mins * 60

while (time.time() - start_time) < runtime_secs:   
    # Read the serial port 
    c = ser.read()
    # If the read is not empty, decode it. The output of one channel for one input signal are two bytes.
    # The first byte contains the channel ID and the overflow bit. The second byte contains the 8-bit data.
    # Always alternate between the two bytes.
    if len(c) != '':
        # Two cases since data is UTF-encoded if in range, after this the data is in hex.
        # First two bits are the channel ID, the last bit is the overflow bit.
        if parity == 0:
            try:
                utf = c.decode()
                bits = ' '.join([f'{i:08b}' for i in utf.encode('utf-8')])
                channel = bits[0:2]
                overflow = bits[-1]
            except:
                c = ('0' + str(c)[3:-1])
                bits = bin(int(c, 16))
                channel = bits[2:4]
                overflow = bits[-1]  
            parity = 1
                
        # Remaining fine bits
        elif parity == 1:
            try:
                utf = c.decode()
                bits = ' '.join([f'{i:08b}' for i in utf.encode('utf-8')])
                output_dec = (int(bits, 2))
            except:
                c = ('0' + str(c)[3:-1])
                output_dec = int(c, 16)
            output_dec += 256 * int(overflow)
            parity = 0

            # Write
            with open(f'{directory}/{channel}.txt', 'a') as f:
                f.write(str(output_dec) + '\n')
    else:
        print('Empty')
