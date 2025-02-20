# This script generates the location assignment for the delay line and the flip-flops in the channel.
# The location assignment is written to a file called loc_assign.txt.

# The full adders are placed in a chain with the corresponding readout FFs placed in the same LE as the adder. 

n_carry4 = 72

with open('loc_assign.txt', 'w') as f:
    y = 20
    n = 0
    for i in range(4*n_carry4):

        text = 'set_location_assignment LCCOMB_X18_Y' + str(y) +'_N' + str(n) + ' -to "channel:channel_inst_1|delay_line:delay_line_inst|unlatched_signal[' + str(i) + ']" \n'
        f.write(text)
        
        # n labels the LEs within one LAB (Logic Array Block). Arriving at the end of one LAB, reset n and move one LAB further. There are 30 LUTs/Registers in one LAB.
        # Even n's label LUTs while odd n's label Registers --> Increment by 2
        if n == 30: 
            y -= 1
            n = 0
        else:
            n += 2


    y = 20
    n = 1
    for i in range(4*n_carry4):
        
        text_ = 'set_location_assignment FF_X18_Y' + str(y) +'_N' + str(n) + ' -to "channel:channel_inst_1|delay_line:delay_line_inst|fdr:\\\latch_1:' + str(i) + ':ff1|q" \n'
        f.write(text_)
        
        # Same as above
        if n == 31:
            y -= 1
            n = 1
        else:
            n += 2
            
 