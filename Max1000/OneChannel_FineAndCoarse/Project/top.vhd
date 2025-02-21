-- Top Entity

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY top IS
    GENERIC (
        carry4_count : INTEGER := 72;                                       -- carry4_count * 4: Number of bins in the delay line
        n_output_bits : INTEGER := 9;                                       -- Number of bits for fine timestamp: Chain is longer than 256 bins, so 9 bits are needed
        coarse_bits : INTEGER := 31                                         -- Number of bits for coarse timestamp: 31 bits --> (2^31 - 1) * 1/12 MHz = 178 seconds covered before reset
    );
    PORT (
        clk : IN STD_LOGIC;                                                 -- Clock Input: On Max10: PIN_H6, 12 MHz
        signal_in : IN STD_LOGIC;                                           -- Signal Input: On Max10: PIN_L12. GND also needed, see attached Pin locations
        signal_out : OUT STD_LOGIC_VECTOR(n_output_bits - 1 DOWNTO 0);      -- Test Output: If you want to see the output on the board, connect this to a LED
        serial_out : OUT STD_LOGIC                                          -- Serial Output for UART: On Max10: PIN_B4
    );
END ENTITY top;

ARCHITECTURE rtl of top IS

    SIGNAL reset_after_start : STD_LOGIC;

    SIGNAL coarse_count : STD_LOGIC_VECTOR(coarse_bits - 1 DOWNTO 0);

    SIGNAL signal_out_1 : STD_LOGIC_VECTOR(n_output_bits - 1 DOWNTO 0);
    SIGNAL channels_wr_en : STD_LOGIC;
    SIGNAL channels_written : STD_LOGIC;

    SIGNAL fifo_wr : STD_LOGIC;
    SIGNAL fifo_rd : STD_LOGIC;
    SIGNAL fifo_full : STD_LOGIC;
    SIGNAL fifo_empty : STD_LOGIC;
    SIGNAL w_fifo_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL r_fifo_data : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL uart_data_valid : STD_LOGIC;
    SIGNAL data_to_uart : STD_LOGIC_VECTOR(7 DOWNTO 0);

    COMPONENT channel IS
        GENERIC (
            carry4_count : INTEGER := 72;
            n_output_bits : INTEGER := 9
        );
        PORT (
            clk : IN STD_LOGIC;
            signal_in : IN STD_LOGIC;
            start_reset : IN STD_LOGIC;
            channel_written : IN STD_LOGIC;
            signal_out : OUT STD_LOGIC_VECTOR(n_output_bits - 1 DOWNTO 0);
            wr_en_out : OUT STD_LOGIC
        );
    END COMPONENT channel;

    COMPONENT handle_start IS
        PORT (
            clk : IN STD_LOGIC;
            starting : OUT STD_LOGIC
        );
    END COMPONENT handle_start;

    COMPONENT coarse_counter IS
        GENERIC (
            coarse_bits : INTEGER := 8
        );
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            count : OUT STD_LOGIC_VECTOR(coarse_bits - 1 DOWNTO 0)
        );
    END COMPONENT coarse_counter;

    COMPONENT fifo_writer IS
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            ch_valid : IN STD_LOGIC;
            ch_data : IN STD_LOGIC_VECTOR(39 DOWNTO 0);
            fifo_full : IN STD_LOGIC;
            fifo_wr : OUT STD_LOGIC;
            written_channels : OUT STD_LOGIC;
            fifo_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT fifo_writer;

    COMPONENT fifo IS
        GENERIC (
            abits : INTEGER := 4;
            dbits : INTEGER := 8
        );
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            rd : IN STD_LOGIC;
            wr : IN STD_LOGIC;
            w_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            r_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            full : OUT STD_LOGIC;
            empty : OUT STD_LOGIC
        );
    END COMPONENT fifo;

    COMPONENT fifo_reader IS
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            fifo_empty : IN STD_LOGIC;
            fifo_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            fifo_rd : OUT STD_LOGIC;
            data_valid : OUT STD_LOGIC;
            data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT fifo_reader;

    COMPONENT uart IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            we : IN STD_LOGIC;
            din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            tx : OUT STD_LOGIC
        );
    END COMPONENT uart;

BEGIN

    -- Reset every entity after start
    handle_start_inst : handle_start
    PORT MAP (
        clk => clk,
        starting => reset_after_start
    );

    -- Coarse counter for clock cycles
    coarse_counter_inst : coarse_counter
    GENERIC MAP (
        coarse_bits => coarse_bits
    )
    PORT MAP (
        clk => clk,
        reset => reset_after_start,
        count => coarse_count
    );

    -- Actual channel for signal detection
    channel_inst_1 : channel
    GENERIC MAP (
        carry4_count => carry4_count,
        n_output_bits => n_output_bits
    )
    PORT MAP (
        clk => clk,
        signal_in => signal_in,
        start_reset => reset_after_start,
        channel_written => channels_written,
        signal_out => signal_out_1,
        wr_en_out => channels_wr_en
    );

    -- Write data from channel to buffer FIFO
    fifo_writer_inst : fifo_writer
    PORT MAP (
        clk => clk,
        reset => reset_after_start,
        ch_valid => channels_wr_en,
        ch_data => coarse_count & signal_out_1,
        fifo_full => fifo_full,
        fifo_wr => fifo_wr,
        written_channels => channels_written,
        fifo_data => w_fifo_data
    );

    -- Buffer FIFO
    fifo_inst_1 : fifo
    GENERIC MAP (
        abits => 6,
        dbits => 8
    )
    PORT MAP (
        clk => clk,
        rst => reset_after_start,
        rd => fifo_rd,
        wr => fifo_wr,
        w_data => w_fifo_data,
        r_data => r_fifo_data,
        full => fifo_full,
        empty => fifo_empty
    );

    -- Read data from buffer FIFO
    fifo_reader_inst : fifo_reader
    PORT MAP (
        clk => clk,
        reset => reset_after_start,
        fifo_empty => fifo_empty,
        fifo_data => r_fifo_data,
        fifo_rd => fifo_rd,
        data_valid => uart_data_valid,
        data_out => data_to_uart
    );

    -- UART for serial output
    uart_inst : uart
    PORT MAP (
        clk => clk,
        rst => reset_after_start,
        we => uart_data_valid,
        din => data_to_uart,
        tx => serial_out
    );

    -- Output signal for testing
    signal_out <= signal_out_1;

END rtl;