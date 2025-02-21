-- Coarse counter for counting clock cycles. The counter is reset after reaching the maximum value.


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY coarse_counter IS
    GENERIC (
        coarse_bits : INTEGER := 8                                  -- Number of bits in the counter
    );
    PORT (
        clk : IN STD_LOGIC;                                         -- Clock signal
        reset : IN STD_LOGIC;                                       -- Asynchronous reset signal
        count : OUT STD_LOGIC_VECTOR(coarse_bits - 1 DOWNTO 0)      -- Counter output
    );
END ENTITY coarse_counter;

ARCHITECTURE rtl OF coarse_counter IS

    -- Counter signal
    SIGNAL counter : UNSIGNED(coarse_bits - 1 DOWNTO 0);

BEGIN

    -- Counter process
    PROCESS (clk, reset)
    BEGIN
        -- Asynchronous reset
        IF reset = '1' THEN
            counter <= (OTHERS => '0');

        -- Update counter on rising edge of the clock
        ELSIF clk'EVENT AND clk = '1' THEN
            -- Reset counter after reaching the maximum value
            IF counter = 2 ** coarse_bits - 1 THEN
                counter <= (OTHERS => '0');
            -- Increment counter
            ELSE
                counter <= counter + 1;
            END IF;
        END IF;
    END PROCESS;

    -- Output the counter value
    count <= STD_LOGIC_VECTOR(counter);

END ARCHITECTURE rtl;