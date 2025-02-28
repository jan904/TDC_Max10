import serial
import matplotlib.pyplot as plt
import time
import datetime
import os

# Open the serial port
ser = serial.Serial(port = '/dev/serial/by-id/usb-Arrow_Arrow_USB_Blaster_TEI0001_ARA27238-if01-port0', baudrate = 115200, bytesize=8)

timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H:%M:%S")
output_dec = 0
parity = 0
coarse_ = ''

# Create a directory to store the output files
directory = "./data/coarse_" + timestamp
os.mkdir(directory)
with open(f'{directory}/coarse.txt', 'a') as f:
    f.write('')
with open(f'{directory}/fine.txt', 'a') as f:
    f.write('')
    
# Use time to read for certain amount of time
runtime_mins = 1000  # mins
start_time = time.time()
runtime_secs = runtime_mins * 60

coarse = ""

while (time.time() - start_time) < runtime_secs:   
    # Read the serial port 
    c = ser.read()
    # If the read is not empty, decode it and write it to output.txt
    if len(c) != '':
        
        # First byte contain the first 7 fine bits. 
        # Two cases since data is UTF-encoded if in range, after this the data is in hex
        if parity == 0:
            try:
                utf = c.decode()
                bits = ' '.join([f'{i:08b}' for i in utf.encode('utf-8')])
                output_fine= int(bits, 2)
            except:
                c = ('0' + str(c)[3:-1])
                bits = bin(int(c, 16))[2:]
                output_fine = int(c, 16)

            # Reset the coarse value
            parity += 1
            coarse = ''
        
        # Second byte contain the MSB of the fine bits (overflow) and the first 7 coarse bits
        elif parity == 1: 
            try:
                utf = c.decode()
                bits = ' '.join([f'{i:08b}' for i in utf.encode('utf-8')])
            except:
                c = ('0' + str(c)[3:-1])
                bits = bin(int(c, 16))
                bits = bits[2:]

            # Add the overflow to the fine bits
            overflow = bits[-1]
            output_fine = output_fine + int(overflow)*256
            
            # Add the coarse bits
            coarse = (str(bits[:-1])) 
            parity += 1
            
        # The rest of the bytes contain the remaining coarse bits
        elif parity < 5:
            try:
                utf = c.decode()
                bits = ' '.join([f'{i:08b}' for i in utf.encode('utf-8')])
            except:
                c = ('0' + str(c)[3:-1])
                bits = bin(int(c, 16))
                bits = bits[2:]
                
            # Update the coarse bits
            coarse = (str(bits)) + coarse
            
            # Write the coarse and fine bits to the output files when 40 bits are read
            if parity == 4:
                coarse = int(''.join(coarse), 2)
                with open(f'{directory}/coarse.txt', 'a') as f:
                    f.write(str(coarse) + '\n')
                    
                with open(f'{directory}/fine.txt', 'a') as f:
                    f.write(str(output_fine) + '\n')
                
                parity = 0
                
            else:       
                parity += 1

    else:
        print('Empty')
