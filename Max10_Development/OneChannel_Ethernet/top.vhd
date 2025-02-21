LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY top IS
    GENERIC (
        carry4_count : INTEGER := 72;
        n_output_bits : INTEGER := 9;
        coarse_bits : INTEGER := 31
    );
    PORT (
        clk25 : IN STD_LOGIC;
        signal_in : IN STD_LOGIC;
        reset_outside : IN STD_LOGIC;
        restart_outside : IN STD_LOGIC;
        rgmii_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        rgmii_in_ctrl : IN STD_LOGIC;
        signal_out : OUT STD_LOGIC_VECTOR(n_output_bits - 1 DOWNTO 0);
        serial_out : OUT STD_LOGIC;
        rgmii_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        rgmii_out_ctrl : OUT STD_LOGIC;
        phy_tx_clk : OUT STD_LOGIC
    );
END ENTITY top;

ARCHITECTURE rtl of top IS

    SIGNAL clk : STD_LOGIC;
    SIGNAL clk125 : STD_LOGIC;
    SIGNAL pll_locked : STD_LOGIC;
    SIGNAL pll_locked_ethernet : STD_LOGIC;

    SIGNAL reset_after_start : STD_LOGIC;
    SIGNAL sending_after_start : STD_LOGIC;

    SIGNAL coarse_count : STD_LOGIC_VECTOR(coarse_bits - 1 DOWNTO 0);
    SIGNAL coarse_set : STD_LOGIC_VECTOR(coarse_bits - 1 DOWNTO 0);

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

    COMPONENT pll IS
        PORT (
            inclk0 : IN STD_LOGIC;
            c0 : OUT STD_LOGIC;
            locked : OUT STD_LOGIC
        );
    END COMPONENT pll;

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
            pll_locked : IN STD_LOGIC;
            reset_outside : IN STD_LOGIC;
            restart_outside : IN STD_LOGIC;
            starting : OUT STD_LOGIC;
            sending : OUT STD_LOGIC
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

    COMPONENT time_batches IS
        GENERIC (
            coarse_bits : INTEGER := 31
        );
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            wrt_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            written : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            coarse_in : IN STD_LOGIC_VECTOR(coarse_bits - 1 DOWNTO 0);
            coarse_out : OUT STD_LOGIC_VECTOR(coarse_bits - 1 DOWNTO 0)
        );
    END COMPONENT time_batches;

    COMPONENT fifo_writer IS
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            ch_valid : IN STD_LOGIC;
            ch_data : IN STD_LOGIC_VECTOR(39 DOWNTO 0);
            fifo_full : IN STD_LOGIC;
            fifo_wr : OUT STD_LOGIC;
            written_channels : OUT STD_LOGIC;
            fifo_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            sop : OUT STD_LOGIC;
            eop : OUT STD_LOGIC
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

    COMPONENT dual_fifo IS
        PORT (
            aclr : IN STD_LOGIC;
            data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            rdclk : IN STD_LOGIC;
            rdreq : IN STD_LOGIC;
            wrclk : IN STD_LOGIC;
            wrreq : IN STD_LOGIC;
            q : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            rdempty : OUT STD_LOGIC;
            wrfull : OUT STD_LOGIC
        );
    END COMPONENT dual_fifo;

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
        GENERIC (
            mhz : INTEGER := 12
        );
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            we : IN STD_LOGIC;
            din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            tx : OUT STD_LOGIC
        );
    END COMPONENT uart;

    component ethernet_setup is
		port (
			altpll_0_areset_conduit_export              : in  std_logic                     := 'X';             -- export
			altpll_0_locked_conduit_export              : out std_logic;                                        -- export
			clk_clk                                     : in  std_logic                     := 'X';             -- clk
			eth_tse_0_mac_misc_connection_ff_tx_crc_fwd : in  std_logic                     := 'X';             -- ff_tx_crc_fwd
			eth_tse_0_mac_misc_connection_ff_tx_septy   : out std_logic;                                        -- ff_tx_septy
			eth_tse_0_mac_misc_connection_tx_ff_uflow   : out std_logic;                                        -- tx_ff_uflow
			eth_tse_0_mac_misc_connection_ff_tx_a_full  : out std_logic;                                        -- ff_tx_a_full
			eth_tse_0_mac_misc_connection_ff_tx_a_empty : out std_logic;                                        -- ff_tx_a_empty
			eth_tse_0_mac_misc_connection_rx_err_stat   : out std_logic_vector(17 downto 0);                    -- rx_err_stat
			eth_tse_0_mac_misc_connection_rx_frm_type   : out std_logic_vector(3 downto 0);                     -- rx_frm_type
			eth_tse_0_mac_misc_connection_ff_rx_dsav    : out std_logic;                                        -- ff_rx_dsav
			eth_tse_0_mac_misc_connection_ff_rx_a_full  : out std_logic;                                        -- ff_rx_a_full
			eth_tse_0_mac_misc_connection_ff_rx_a_empty : out std_logic;                                        -- ff_rx_a_empty
			eth_tse_0_mac_rgmii_connection_rgmii_in     : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- rgmii_in
			eth_tse_0_mac_rgmii_connection_rgmii_out    : out std_logic_vector(3 downto 0);                     -- rgmii_out
			eth_tse_0_mac_rgmii_connection_rx_control   : in  std_logic                     := 'X';             -- rx_control
			eth_tse_0_mac_rgmii_connection_tx_control   : out std_logic;                                        -- tx_control
			eth_tse_0_mac_status_connection_set_10      : in  std_logic                     := 'X';             -- set_10
			eth_tse_0_mac_status_connection_set_1000    : in  std_logic                     := 'X';             -- set_1000
			eth_tse_0_mac_status_connection_eth_mode    : out std_logic;                                        -- eth_mode
			eth_tse_0_mac_status_connection_ena_10      : out std_logic;                                        -- ena_10
			eth_tse_0_receive_data                      : out std_logic_vector(31 downto 0);                    -- data
			eth_tse_0_receive_endofpacket               : out std_logic;                                        -- endofpacket
			eth_tse_0_receive_error                     : out std_logic_vector(5 downto 0);                     -- error
			eth_tse_0_receive_empty                     : out std_logic_vector(1 downto 0);                     -- empty
			eth_tse_0_receive_ready                     : in  std_logic                     := 'X';             -- ready
			eth_tse_0_receive_startofpacket             : out std_logic;                                        -- startofpacket
			eth_tse_0_receive_valid                     : out std_logic;                                        -- valid
			eth_tse_0_transmit_data                     : in  std_logic_vector(31 downto 0) := (others => 'X'); -- data
			eth_tse_0_transmit_endofpacket              : in  std_logic                     := 'X';             -- endofpacket
			eth_tse_0_transmit_error                    : in  std_logic                     := 'X';             -- error
			eth_tse_0_transmit_empty                    : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- empty
			eth_tse_0_transmit_ready                    : out std_logic;                                        -- ready
			eth_tse_0_transmit_startofpacket            : in  std_logic                     := 'X';             -- startofpacket
			eth_tse_0_transmit_valid                    : in  std_logic                     := 'X';             -- valid
			reset_reset_n                               : in  std_logic                     := 'X';             -- reset_n
            altpll_0_c2_clk                             : out std_logic                     := 'X'              -- export     
		);
	end component ethernet_setup;

    SIGNAL ethernet_tx_a_empty : STD_LOGIC;
    SIGNAL ethernet_tx_a_full : STD_LOGIC;

    SIGNAL tx_sop : STD_LOGIC;
    SIGNAL tx_eop : STD_LOGIC;

    SIGNAL ethernet_pll_locked : STD_LOGIC;

    SIGNAL ethernet_tx_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL ethernet_tx_rdy : STD_LOGIC;

BEGIN

    -- Ethernet IP as explained in Documentation. Setup and edit the IP in Platform Designer.
    -- Only tx is needed, therefore rx is not connected.
    ethernet_inst: ethernet_setup
    PORT MAP (
        altpll_0_areset_conduit_export => reset_after_start,
        altpll_0_locked_conduit_export => ethernet_pll_locked,
        clk_clk => clk25,
        eth_tse_0_mac_misc_connection_ff_tx_crc_fwd => not tx_eop,
        eth_tse_0_mac_misc_connection_ff_tx_septy => ethernet_tx_a_full,
        eth_tse_0_mac_misc_connection_tx_ff_uflow => ethernet_tx_a_empty,
        eth_tse_0_mac_misc_connection_ff_tx_a_full => open,
        eth_tse_0_mac_misc_connection_ff_tx_a_empty => open,
        eth_tse_0_mac_misc_connection_rx_err_stat => open,
        eth_tse_0_mac_misc_connection_rx_frm_type => open,
        eth_tse_0_mac_misc_connection_ff_rx_dsav => open,
        eth_tse_0_mac_misc_connection_ff_rx_a_full => open,
        eth_tse_0_mac_misc_connection_ff_rx_a_empty => open,
        eth_tse_0_mac_rgmii_connection_rgmii_in => rgmii_in,
        eth_tse_0_mac_rgmii_connection_rgmii_out => rgmii_out,
        eth_tse_0_mac_rgmii_connection_rx_control => rgmii_in_ctrl,
        eth_tse_0_mac_rgmii_connection_tx_control => rgmii_out_ctrl,
        eth_tse_0_mac_status_connection_set_10 => '0',
        eth_tse_0_mac_status_connection_set_1000 => '1',
        eth_tse_0_mac_status_connection_eth_mode => open,
        eth_tse_0_mac_status_connection_ena_10 => open,
        eth_tse_0_receive_data => open,
        eth_tse_0_receive_endofpacket => open,         
        eth_tse_0_receive_error => open,                     
        eth_tse_0_receive_empty => open,                    
        eth_tse_0_receive_ready => '0',         
        eth_tse_0_receive_startofpacket => open,            
        eth_tse_0_receive_valid => open,                    
        eth_tse_0_transmit_data => ethernet_tx_data,                
        eth_tse_0_transmit_endofpacket => tx_eop,        
        eth_tse_0_transmit_error => '0',              
        eth_tse_0_transmit_empty => (others => '0'),
        eth_tse_0_transmit_ready => ethernet_tx_rdy,
        eth_tse_0_transmit_startofpacket => tx_sop,            
        eth_tse_0_transmit_valid => fifo_wr,
        reset_reset_n => reset_after_start or not reset_outside,
        altpll_0_c2_clk => open
    );

    -- Generate 125 MHz clock from 25 MHz clock
    pll_inst : pll
    PORT MAP (
        inclk0 => clk25,
        c0 => clk,
        locked => pll_locked
    );

    -- Handle start signal. Also reset logic through push buttons
    handle_start_inst : handle_start
    PORT MAP (
        clk => clk,
        pll_locked => pll_locked,
        reset_outside => not reset_outside,
        restart_outside => not restart_outside,
        starting => reset_after_start,
        sending => sending_after_start
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

    signal_out <= signal_out_1;

    -- Write data from channel to buffer FIFO
    fifo_writer_inst : fifo_writer
    PORT MAP (
        clk => clk,
        reset => reset_after_start,
        ch_valid => channels_wr_en,
        ch_data => coarse_count & signal_out_1,
        fifo_full => not(ethernet_tx_rdy and not ethernet_tx_a_full),
        fifo_wr => fifo_wr,
        written_channels => channels_written,
        fifo_data => w_fifo_data,
        sop => tx_sop,
        eop => tx_eop
    );

    -- Buffer FIFO
    fifo_inst_1 : fifo
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
        reset => sending_after_start,
        fifo_empty => fifo_empty,
        fifo_data => r_fifo_data,
        fifo_rd => fifo_rd,
        data_valid => uart_data_valid,
        data_out => data_to_uart
    );

    -- UART for sending data to PC. Not needed since data is sent to Ethernet, but used for testing
    uart_inst : uart
    GENERIC MAP (
        mhz => 12
    )
    PORT MAP (
        clk => clk,
        rst => sending_after_start,
        we => uart_data_valid,
        din => data_to_uart,
        tx => serial_out
    );

    -- 125MHz clock for phy 
    phy_tx_clk <= clk125;
        

END rtl;