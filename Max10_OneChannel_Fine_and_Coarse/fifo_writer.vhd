-- Write fine & coarse timestamp to buffer FIFO

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY fifo_writer IS
    PORT (
        clk : IN STD_LOGIC;                                 -- Clock
        reset : IN STD_LOGIC;                               -- Reset after start of FPGA
        ch_valid : IN STD_LOGIC;                            -- Indicate that the channel data is valid and can be written to the FIFO
        ch_data : IN STD_LOGIC_VECTOR(39 DOWNTO 0);         -- Entire data for one signal: 31 coarse bits (39 downto 9) + 9 fine bits (8 downto 0)
        fifo_full : IN STD_LOGIC;                           -- FIFO full signal
        fifo_wr : OUT STD_LOGIC;                            -- Write enable signal for the FIFO
        written_channels : OUT STD_LOGIC;                   -- Indicate that the data has been written to the FIFO
        fifo_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)        -- Data to be written to the FIFO: 8 bits
    );
END ENTITY fifo_writer;

ARCHITECTURE rtl OF fifo_writer IS

    TYPE state_type IS (IDLE, WRITE_COARSE, RST);
    SIGNAL state, next_state : state_type;

    SIGNAL data_next, data_reg : STD_LOGIC_VECTOR(39 DOWNTO 0);
    SIGNAL fifo_data_reg, fifo_data_next : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL wr_next, wr_reg : STD_LOGIC;

    SIGNAL written_channels_next, written_channels_reg : STD_LOGIC;

    SIGNAL count, count_next : INTEGER range 0 to 4;

BEGIN
    -- FSM core
    PROCESS(clk, reset)
    BEGIN
        -- Reset at start
        IF reset = '1' THEN
            state <= IDLE;
            data_reg <= (OTHERS => '0');
            wr_reg <= '0';
            fifo_data_reg <= (OTHERS => '0');
            written_channels_reg <= '0';
            count <= 0;
        -- Update signals
        ELSIF rising_edge(clk) THEN
            state <= next_state;
            data_reg <= data_next;
            wr_reg <= wr_next;
            fifo_data_reg <= fifo_data_next;
            written_channels_reg <= written_channels_next;
            count <= count_next;
        END IF;
    END PROCESS;

    -- FSM logic
    PROCESS(state, ch_valid, ch_data, fifo_full, data_reg, wr_reg, fifo_data_reg, written_channels_reg, count)
    BEGIN

        -- Default values
        next_state <= state;
        data_next <= data_reg;
        wr_next <= wr_reg;
        fifo_data_next <= fifo_data_reg;
        written_channels_next <= written_channels_reg;
        count_next <= count;

        CASE state IS
            WHEN IDLE =>
                wr_next <= '0';
                written_channels_next <= '0';

                -- Only go to write state if the FIFO is not full
                IF fifo_full = '0' THEN
                    -- Check if data is valid
                    IF ch_valid = '1' THEN
                        next_state <= WRITE_COARSE;
                        data_next <= ch_data;
                    END IF;
                ELSE
                    next_state <= IDLE;
                END IF;

            WHEN WRITE_COARSE =>
                -- Check if the FIFO is full before each writing operation
                -- Write 40 bits of data to the FIFO in 5 cycles of 8 bit words. Start with fine bits.
                IF fifo_full = '0' THEN
                    IF count = 0 THEN
                        fifo_data_next <= data_reg(7 DOWNTO 0);
                        wr_next <= '1';
                        count_next <= count + 1;
                        next_state <= WRITE_COARSE;
                    ELSIF count = 1 THEN
                        fifo_data_next <= data_reg(15 DOWNTO 8);
                        wr_next <= '1';
                        count_next <= count + 1;
                        next_state <= WRITE_COARSE;
                    ELSIF count = 2 THEN
                        fifo_data_next <= data_reg(23 DOWNTO 16);
                        wr_next <= '1';
                        count_next <= count + 1;
                        next_state <= WRITE_COARSE;
                    ELSIF count = 3 THEN
                        fifo_data_next <= data_reg(31 DOWNTO 24);
                        wr_next <= '1';
                        count_next <= count + 1;
                        next_state <= WRITE_COARSE;
                    ELSIF count = 4 THEN
                        fifo_data_next <= data_reg(39 DOWNTO 32);
                        wr_next <= '1';
                        count_next <= 0;
                        written_channels_next <= '1';
                        next_state <= RST;
                    END IF;
                
                -- If FIFO is full, stop writing and wait
                ELSE
                    wr_next <= '0';
                    next_state <= WRITE_COARSE;
                END IF;

            WHEN RST =>
                -- Reset the state machine. Wait for a few cycles to allow time for the delay line to reset
                IF count = 4 THEN
                    next_state <= IDLE;
                    count_next <= 0;
                ELSE
                    count_next <= count + 1; 
                    next_state <= RST;
                END IF;
                wr_next <= '0';

            WHEN OTHERS =>
                next_state <= IDLE;

        END CASE;

    END PROCESS;

    -- Output signals
    fifo_wr <= wr_reg;
    fifo_data <= fifo_data_reg;
    written_channels <= written_channels_reg;

END ARCHITECTURE rtl;