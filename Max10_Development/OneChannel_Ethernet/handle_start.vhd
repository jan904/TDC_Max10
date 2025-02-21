-- Handle start after starting the fpga
--
-- This module is used to send a signal for one clock cycle after the FPGA has
-- been started for initializing the other modules.
-- Implemented using a state machine with possibility to reset the state machine using user push buttons.
-- There are two reset signals: starting and sending. Everything after the FIFO uses sending as rst, all other modules use starting as rst.
-- Sending is activated for two clock cycles after the FPGA has started. Starting is activated for one clock cycle after the FPGA has started.
 
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY handle_start IS
    PORT (
        clk : IN STD_LOGIC;                 -- Clock signal
        pll_locked : IN STD_LOGIC;          -- Signal indicating that the PLL is locked
        reset_outside : IN STD_LOGIC;       -- Reset signal from outside
        restart_outside : IN STD_LOGIC;     -- Restart signal from outside
        starting : OUT STD_LOGIC;           -- Reset signal for 1 clock cycle
        sending : OUT STD_LOGIC             -- Reset signal for 2 clock cycles
    );
END ENTITY handle_start;


ARCHITECTURE fsm_arch OF handle_start IS

    -- Define the states of the state machine
    TYPE state_type IS (reset_state, starting_state, running_state, waiting_state);
    SIGNAL current_state, next_state : state_type;

    -- Output signal updated by the state machine
    SIGNAL starting_reg, starting_next : STD_LOGIC;
    SIGNAL sending_reg, sending_next : STD_LOGIC;

BEGIN

    -- fsm core
    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            current_state <= next_state;
            starting_reg <= starting_next;
            sending_reg <= sending_next;
        END IF;
    END PROCESS;

    -- fsm logic
    PROCESS (next_state, starting_reg, current_state, pll_locked, sending_reg, reset_outside, restart_outside)
    BEGIN

        -- Default values
        starting_next <= starting_reg;
        sending_next <= sending_reg;

        CASE current_state IS
            WHEN reset_state =>

                -- If the PLL is locked, start the next state. Send starting signal for one clock cycle
                IF pll_locked = '1' THEN
                    starting_next <= '1';
                    next_state <= starting_state;
                ELSE
                    starting_next <= '0';
                    next_state <= reset_state;
                END IF;

            -- Send a sending signal for one clock cycle
            WHEN starting_state =>
                starting_next <= '0';
                sending_next <= '1';
                next_state <= running_state;

            -- Stay in this state until a reset signal is received
            WHEN running_state =>
                sending_next <= '0';
                IF reset_outside = '1' THEN
                    next_state <= waiting_state;
                ELSE
                    next_state <= running_state;
                END IF; 

            -- Stay in this waiting state and send reset signals until a restart signal is received
            WHEN waiting_state =>
                IF restart_outside = '1' THEN
                    next_state <= reset_state;
                    starting_next <= '1';
                    sending_next <= '0';
                ELSE
                    next_state <= waiting_state;
                    starting_next <= '1';
                    sending_next <= '1';
                END IF;

            WHEN OTHERS =>
                next_state <= reset_state;

        END CASE;
    END PROCESS;

    starting <= starting_reg;
    sending <= sending_reg or starting_reg;

END ARCHITECTURE fsm_arch;