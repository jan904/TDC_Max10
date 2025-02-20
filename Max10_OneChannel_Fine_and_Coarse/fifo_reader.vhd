-- Read data from buffer FIFO and send it to UART

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY fifo_reader IS
    PORT (
        clk : IN STD_LOGIC;                             -- Clock
        reset : IN STD_LOGIC;                           -- Reset after start of FPGA
        fifo_empty : IN STD_LOGIC;                      -- FIFO empty signal
        fifo_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);    -- Data read from the FIFO
        fifo_rd : OUT STD_LOGIC;                        -- Read enable signal for the FIFO
        data_valid : OUT STD_LOGIC;                     -- Indicate that the output data is valid    
        data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)     -- Data to be sent to the UART
    );
END ENTITY fifo_reader;

ARCHITECTURE rtl OF fifo_reader IS

    TYPE state_type IS (IDLE, READ_DATA);
    SIGNAL state, next_state : state_type;

    SIGNAL rd_next, rd_reg : STD_LOGIC;
    SIGNAL data_out_next, data_out_reg : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL data_valid_next, data_valid_reg : STD_LOGIC;

BEGIN

    -- FSM core
    PROCESS(clk, reset)
    BEGIN
        -- Reset at start
        IF reset = '1' THEN
            state <= IDLE;
            rd_reg <= '0';
            data_valid_reg <= '0';
            data_out_reg <= (OTHERS => '0');
        -- Update signals
        ELSIF rising_edge(clk) THEN
            state <= next_state;
            rd_reg <= rd_next;
            data_valid_reg <= data_valid_next;
            data_out_reg <= data_out_next;
        END IF;
    END PROCESS;

    -- FSM logic
    PROCESS(state, fifo_empty, fifo_data, rd_reg, data_out_reg, data_valid_reg)
    BEGIN

        -- Default values
        next_state <= state;
        rd_next <= rd_reg;
        data_valid_next <= data_valid_reg;
        data_out_next <= data_out_reg;

        CASE state IS
            WHEN IDLE =>
                -- If FIFO is not empty, read data
                IF fifo_empty = '0' THEN
                    data_valid_next <= '0';
                    rd_next <= '1';
                    next_state <= READ_DATA;

                -- If FIFO is empty, do nothing
                ELSE
                    data_valid_next <= '0';
                    next_state <= IDLE;
                END IF;

            -- Output read data from FIFO and set data_valid signal to '1'. Then go back to IDLE state
            WHEN READ_DATA =>
                rd_next <= '0';
                data_valid_next <= '1';
                data_out_next <= fifo_data;
                next_state <= IDLE;

            WHEN OTHERS =>
                next_state <= IDLE;
        END CASE;

    END PROCESS;

    -- Output signals
    fifo_rd <= rd_reg;
    data_out <= data_out_reg;
    data_valid <= data_valid_reg;

END ARCHITECTURE rtl;
        
            