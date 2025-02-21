-- Tapped delay line 
--
-- Tapped delay line with a configurable number of stages.
-- The delay line is implemented using a chain of full adders. The inputs to 
-- the adders are '0' and '1', such that the carry-in propagates through
-- the chain of cells. The carry-in of the first cell is driven by the trigger signal. If a '1' comes in
-- as a trigger, this one propagates through the chain of cells.
-- One the rising edge of the clock signal, the carry-out signals are stored using FFs. 
-- The number of ones in the latched signal indicates the number of stages that the input signal has been 
-- propagated through and thus gives timing information. The output of the latches should be perfect thermometer code.
-- Two rows of FFs for stability reasons.


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY delay_line IS
    GENERIC (
        stages : INTEGER := 8                                   -- Number of bins in the delay line
    );
    PORT (
        reset : IN STD_LOGIC;                                   -- Reset delay line: Set to '1' when the TDC is ready for a new signal
        trigger : IN STD_LOGIC;                                 -- Input signal that triggers the delay line
        clock : IN STD_LOGIC;                                   -- Clock signal
        signal_running : IN STD_LOGIC;                          -- Signal that indicates that the delay chain is busy with a signal: Used for locking the FFs
        therm_code : OUT STD_LOGIC_VECTOR(stages - 1 DOWNTO 0)  -- Thermometer code output
    );
END delay_line;


ARCHITECTURE rtl OF delay_line IS

    SIGNAL unlatched_signal : STD_LOGIC_VECTOR(stages - 1 DOWNTO 0);
    SIGNAL latched_once : STD_LOGIC_VECTOR(stages - 1 DOWNTO 0);

    SIGNAL a : STD_LOGIC;
    SIGNAL b : STD_LOGIC;


    COMPONENT full_add IS
        PORT (
            a : IN STD_LOGIC;
            b : IN STD_LOGIC;
            Cin : IN STD_LOGIC;
            Cout : OUT STD_LOGIC;
            Sum : OUT STD_LOGIC
        );
    END COMPONENT full_add;

    COMPONENT fdr
        PORT (
            rst : IN STD_LOGIC;
            clk : IN STD_LOGIC;
            lock : IN STD_LOGIC;
            t : IN STD_LOGIC;
            q : OUT STD_LOGIC
        );
    END COMPONENT;
	
    -- Keep attribute to prevent synthesis tool from optimizing away the signals
	ATTRIBUTE keep : boolean;
    ATTRIBUTE keep OF unlatched_signal : SIGNAL IS TRUE;
    ATTRIBUTE keep OF a : SIGNAL IS TRUE;
    ATTRIBUTE keep OF b : SIGNAL IS TRUE;
	
BEGIN

    -- Constant Inputs to the adders
    a <= '0';
    b <= '1';
   
    -- Instantiate the full adder chain
    inst_delay_line : FOR ii IN 0 TO stages - 1 GENERATE

        -- First full adder: Connect the trigger signal to the carry-in
        first_fa : IF ii = 0 GENERATE
        BEGIN
            first_fa : full_add port map (
                a => a,
                b => b,
                Cin => trigger,
                Cout => unlatched_signal(ii),
                Sum => open
            );
        END GENERATE first_fa;

        -- Next full adders: Connect the carry-out of the previous cell to the carry-in of the next cell
        next_fa : IF ii > 0 GENERATE
        BEGIN
            inst_fa : full_add port map (
                a => a,
                b => b,
                Cin => unlatched_signal(ii - 1),
                Cout => unlatched_signal(ii),
                Sum => open
            );
        END GENERATE next_fa;
    
    END GENERATE inst_delay_line;

    -- Instantiate the FlipFlops. 
    -- The FFs are locked once a signal is recorded in order to process the output and then are reset once the readout is done.
    latch_1 : FOR i IN 0 TO stages - 1 GENERATE
    BEGIN

        -- First row of FlipFlops
        ff1 : fdr
        PORT MAP(
            rst => reset,
            lock => signal_running,
            clk => clock,
            t => unlatched_signal(i),
            q => latched_once(i)
        );

        -- Second row of FlipFlops
        ff2 : fdr
        PORT MAP(
            rst => reset,
            lock => signal_running,
            clk => clock,
            t => latched_once(i),
            q => therm_code(i)
        );
    END GENERATE latch_1;

END ARCHITECTURE rtl;