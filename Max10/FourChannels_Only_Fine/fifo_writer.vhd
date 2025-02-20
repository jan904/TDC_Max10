-- Write data from 4 channels into fifo

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY fifo_writer IS
    PORT (
        clk : IN STD_LOGIC;                                     -- Clock
        reset : IN STD_LOGIC;                                   -- Reset after start of FPGA
        ch_valid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);             -- Indicates if the data for the respective channels is valid: Each bit corresponds to a channel
        ch_data : IN STD_LOGIC_VECTOR(63 DOWNTO 0);             -- Data for the channels: 16 bits for each channel (7 identifications bits + 9 fine bits)
        fifo_full : IN STD_LOGIC;                               -- FIFO full signal
        fifo_wr : OUT STD_LOGIC;                                -- Write enable signal for the FIFO
        written_channels : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);    -- Indicate that the data has been written to the FIFO: Each bit corresponds to a channel
        fifo_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)            -- Data to be written to the FIFO: 8 bits
    );
END ENTITY fifo_writer;

ARCHITECTURE rtl OF fifo_writer IS

    TYPE state_type IS (IDLE, WRITE_FIRST_BYTE, WRITE_SECOND_BYTE);
    SIGNAL state, next_state : state_type;

    SIGNAL channel_next, channel_reg : INTEGER range 0 to 3;
    SIGNAL data_next, data_reg : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL fifo_data_reg, fifo_data_next : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL wr_next, wr_reg : STD_LOGIC;

    SIGNAL written_channels_next, written_channels_reg : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN
    -- FSM core
    PROCESS(clk, reset)
    BEGIN
        -- Reset at start
        IF reset = '1' THEN
            state <= IDLE;
            channel_reg <= 0;
            data_reg <= (OTHERS => '0');
            wr_reg <= '0';
            fifo_data_reg <= (OTHERS => '0');
            written_channels_reg <= (OTHERS => '0');
        
        -- Update signals
        ELSIF rising_edge(clk) THEN
            state <= next_state;
            channel_reg <= channel_next;
            data_reg <= data_next;
            wr_reg <= wr_next;
            fifo_data_reg <= fifo_data_next;
            written_channels_reg <= written_channels_next;
        END IF;
    END PROCESS;

    -- FSM logic
    PROCESS(state, ch_valid, ch_data, fifo_full, channel_reg, data_reg, wr_reg, fifo_data_reg, written_channels_reg)
    BEGIN

        -- Default values
        next_state <= state;
        channel_next <= channel_reg;
        data_next <= data_reg;
        wr_next <= wr_reg;
        fifo_data_next <= fifo_data_reg;
        written_channels_next <= written_channels_reg;

        CASE state IS
            WHEN IDLE =>
                wr_next <= '0';
                written_channels_next <= "0000";

                -- Check if the FIFO is full
                IF fifo_full = '0' THEN
                    -- Check if data of currently selected channel is valid
                    IF ch_valid(channel_reg) = '1' THEN
                        -- Store bits of respective channel in data_next and go to WRITE_FIRST_BYTE state
                        next_state <= WRITE_FIRST_BYTE;
                        data_next <= ch_data((16 * channel_reg) + 15 DOWNTO 16 * channel_reg);

                    -- If data is not valid, select next channel
                    ELSE 
                        channel_next <= (channel_reg + 1) mod 4;
                    END IF;
                ELSE
                    next_state <= IDLE;
                END IF;

            WHEN WRITE_FIRST_BYTE =>
                -- If FIFO is not full, write the first byte of the data to the FIFO (channel identification & overflow)
                IF fifo_full = '0' THEN
                    fifo_data_next <= data_reg(15 DOWNTO 8);
                    written_channels_next(channel_reg) <= '1';
                    wr_next <= '1';
                    next_state <= WRITE_SECOND_BYTE;
                
                -- If FIFO is full, stay in WRITE_FIRST_BYTE state
                ELSE
                    next_state <= WRITE_FIRST_BYTE;
                END IF;

            WHEN WRITE_SECOND_BYTE =>
                -- If FIFO is not full, write the second byte of the data to the FIFO (channel output)
                IF fifo_full = '0' THEN
                    fifo_data_next <= data_reg(7 DOWNTO 0);
                    wr_next <= '1';

                    -- Select next channel
                    channel_next <= (channel_reg + 1) mod 4;
                    next_state <= IDLE;
                ELSE
                    next_state <= WRITE_SECOND_BYTE;
                END IF;

            WHEN OTHERS =>
                next_state <= IDLE;

        END CASE;

    END PROCESS;

    -- Output signals
    fifo_wr <= wr_reg;
    fifo_data <= fifo_data_reg;
    written_channels <= written_channels_reg;

END ARCHITECTURE rtl;