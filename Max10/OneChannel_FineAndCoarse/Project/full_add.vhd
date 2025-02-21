-- Full adder fo two 1 Bit inputs

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY full_add IS
    PORT (
        a : IN STD_LOGIC;       -- First input
        b : IN STD_LOGIC;       -- Second input
        Cin : IN STD_LOGIC;     -- Carry in
        Cout : OUT STD_LOGIC;   -- Carry out
        Sum : OUT STD_LOGIC     -- Sum output
    );
END ENTITY full_add;

ARCHITECTURE behavioral OF full_add IS

BEGIN

    -- Sum and Carry out equations
    Sum <= not (Cin XOR ( a XOR b ));
    Cout <= (a AND b) OR (Cin AND (a XOR b));
  
END ARCHITECTURE behavioral;

