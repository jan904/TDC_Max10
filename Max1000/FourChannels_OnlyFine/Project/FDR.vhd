-- Flip Flop with Reset and Lock. The output is updated on the
-- rising edge of the clock signal, unless the lock signal is set to 1. In that
-- case, the output is not updated.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY fdr IS
    PORT (
        rst : IN STD_LOGIC;         -- Reset
        lock : IN STD_LOGIC;        -- Lock 
        clk : IN STD_LOGIC;         -- Clock 
        t : IN STD_LOGIC;           -- Input
        q : OUT STD_LOGIC           -- Output
    );
END fdr;


ARCHITECTURE rtl OF fdr IS
BEGIN

    PROCESS (clk, rst)
    BEGIN

        -- Set output to 0 on reset
        IF rst = '1' THEN
            q <= '0';
            
        -- Update output on rising edge of clock if not locked
        ELSIF clk'event AND clk = '1' THEN
            IF lock = '0' THEN
                q <= t;
            END IF;
        END IF;
    END PROCESS;
    
END rtl;
