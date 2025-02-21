-- Top Entity

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY top IS
    GENERIC (
        carry4_count : INTEGER := 72;                                       -- carry4_count * 4: Number of bins in the delay line
        n_output_bits : INTEGER := 9;                                       -- Number of bits for fine timestamp: Chain is longer than 256 bins, so 9 bits are needed
        coarse_bits : INTEGER := 8                                          -- Number of bits for coarse timestamp. Not implemented in this design
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

    SIGNAL signal_out_1, signal_out_2, signal_out_3, signal_out_4 : STD_LOGIC_VECTOR(n_output_bits - 1 DOWNTO 0);
    SIGNAL channels_wr_en : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL channels_written : STD_LOGIC_VECTOR(3 DOWNTO 0);

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

    COMPONENT fifo_writer IS
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            ch_valid : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            ch_data : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
            fifo_full : IN STD_LOGIC;
            fifo_wr : OUT STD_LOGIC;
            written_channels : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
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

    -- Four separate channels. Input Signal is fed into all of them and all outputs are written to a buffer FIFO
    channel_inst_1 : channel
    GENERIC MAP (
        carry4_count => carry4_count,
        n_output_bits => n_output_bits
    )
    PORT MAP (
        clk => clk,
        signal_in => signal_in,
        start_reset => reset_after_start,
        channel_written => channels_written(0),
        signal_out => signal_out_1,
        wr_en_out => channels_wr_en(0)
    );

    channel_inst_2 : channel
    GENERIC MAP (
        carry4_count => carry4_count,
        n_output_bits => n_output_bits
    )
    PORT MAP (
        clk => clk,
        signal_in => signal_in,
        start_reset => reset_after_start,
        channel_written => channels_written(1),
        signal_out => signal_out_2,
        wr_en_out => channels_wr_en(1)
    );

    channel_inst_3 : channel
    GENERIC MAP (
        carry4_count => carry4_count,
        n_output_bits => n_output_bits
    )
    PORT MAP (
        clk => clk,
        signal_in => signal_in,
        start_reset => reset_after_start,
        channel_written => channels_written(2),
        signal_out => signal_out_3,
        wr_en_out => channels_wr_en(2)
    );

    channel_inst_4 : channel
    GENERIC MAP (
        carry4_count => carry4_count,
        n_output_bits => n_output_bits
    )
    PORT MAP (
        clk => clk,
        signal_in => signal_in,
        start_reset => reset_after_start,
        channel_written => channels_written(3),
        signal_out => signal_out_4,
        wr_en_out => channels_wr_en(3)
    );

    -- Write data from all channels to buffer FIFO. 
    -- Each channel has a 9 bit output. Add 7 bits to each output with the channel label for later identification. Very inefficient, but easy to read.
    fifo_writer_inst : fifo_writer
    PORT MAP (
        clk => clk,
        reset => reset_after_start,
        ch_valid => channels_wr_en,
        ch_data => "1100000" & signal_out_4 &  "1000000" & signal_out_3 & "0100000" & signal_out_2 & "0000000" & signal_out_1,
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