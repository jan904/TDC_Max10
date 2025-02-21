-- Thermometer to binary encoder

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY encoder IS
    GENERIC (
        n_bits_bin : POSITIVE;                                              -- Number of bits in the binary output  
        n_bits_therm : POSITIVE                                             -- Number of bits in the thermometer code           
    );
    PORT (
        clk : IN STD_LOGIC;
        thermometer : IN STD_LOGIC_VECTOR((n_bits_therm - 1) DOWNTO 0);     -- Thermometer code input
        count_bin : OUT STD_LOGIC_VECTOR((n_bits_bin - 1) DOWNTO 0)         -- Binary count output
    );
END ENTITY encoder;


ARCHITECTURE rtl OF encoder IS
BEGIN

    PROCESS (clk)
        -- Variable to store the count
       VARIABLE count : unsigned(n_bits_bin - 1 DOWNTO 0); 

    BEGIN
        
        IF rising_edge(clk) THEN
            -- Reset the count after each clock cycle --> Lock logic could be added here
            count := (OTHERS => '0');

            -- Loop over the thermometer code and count the number of '1's
            FOR i IN 0 TO n_bits_therm - 1 LOOP
                IF thermometer(i) = '1' THEN
                    count := count + 1;
                END IF;
            END LOOP;

            -- Assign the count to the output
            count_bin <= STD_LOGIC_VECTOR(count);
        END IF;
    END PROCESS;

END ARCHITECTURE rtl;