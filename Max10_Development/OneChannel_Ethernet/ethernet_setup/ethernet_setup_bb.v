
module ethernet_setup (
	altpll_0_areset_conduit_export,
	altpll_0_c2_clk,
	altpll_0_locked_conduit_export,
	clk_clk,
	eth_tse_0_mac_misc_connection_ff_tx_crc_fwd,
	eth_tse_0_mac_misc_connection_ff_tx_septy,
	eth_tse_0_mac_misc_connection_tx_ff_uflow,
	eth_tse_0_mac_misc_connection_ff_tx_a_full,
	eth_tse_0_mac_misc_connection_ff_tx_a_empty,
	eth_tse_0_mac_misc_connection_rx_err_stat,
	eth_tse_0_mac_misc_connection_rx_frm_type,
	eth_tse_0_mac_misc_connection_ff_rx_dsav,
	eth_tse_0_mac_misc_connection_ff_rx_a_full,
	eth_tse_0_mac_misc_connection_ff_rx_a_empty,
	eth_tse_0_mac_rgmii_connection_rgmii_in,
	eth_tse_0_mac_rgmii_connection_rgmii_out,
	eth_tse_0_mac_rgmii_connection_rx_control,
	eth_tse_0_mac_rgmii_connection_tx_control,
	eth_tse_0_mac_status_connection_set_10,
	eth_tse_0_mac_status_connection_set_1000,
	eth_tse_0_mac_status_connection_eth_mode,
	eth_tse_0_mac_status_connection_ena_10,
	eth_tse_0_receive_data,
	eth_tse_0_receive_endofpacket,
	eth_tse_0_receive_error,
	eth_tse_0_receive_empty,
	eth_tse_0_receive_ready,
	eth_tse_0_receive_startofpacket,
	eth_tse_0_receive_valid,
	eth_tse_0_transmit_data,
	eth_tse_0_transmit_endofpacket,
	eth_tse_0_transmit_error,
	eth_tse_0_transmit_empty,
	eth_tse_0_transmit_ready,
	eth_tse_0_transmit_startofpacket,
	eth_tse_0_transmit_valid,
	reset_reset_n);	

	input		altpll_0_areset_conduit_export;
	output		altpll_0_c2_clk;
	output		altpll_0_locked_conduit_export;
	input		clk_clk;
	input		eth_tse_0_mac_misc_connection_ff_tx_crc_fwd;
	output		eth_tse_0_mac_misc_connection_ff_tx_septy;
	output		eth_tse_0_mac_misc_connection_tx_ff_uflow;
	output		eth_tse_0_mac_misc_connection_ff_tx_a_full;
	output		eth_tse_0_mac_misc_connection_ff_tx_a_empty;
	output	[17:0]	eth_tse_0_mac_misc_connection_rx_err_stat;
	output	[3:0]	eth_tse_0_mac_misc_connection_rx_frm_type;
	output		eth_tse_0_mac_misc_connection_ff_rx_dsav;
	output		eth_tse_0_mac_misc_connection_ff_rx_a_full;
	output		eth_tse_0_mac_misc_connection_ff_rx_a_empty;
	input	[3:0]	eth_tse_0_mac_rgmii_connection_rgmii_in;
	output	[3:0]	eth_tse_0_mac_rgmii_connection_rgmii_out;
	input		eth_tse_0_mac_rgmii_connection_rx_control;
	output		eth_tse_0_mac_rgmii_connection_tx_control;
	input		eth_tse_0_mac_status_connection_set_10;
	input		eth_tse_0_mac_status_connection_set_1000;
	output		eth_tse_0_mac_status_connection_eth_mode;
	output		eth_tse_0_mac_status_connection_ena_10;
	output	[31:0]	eth_tse_0_receive_data;
	output		eth_tse_0_receive_endofpacket;
	output	[5:0]	eth_tse_0_receive_error;
	output	[1:0]	eth_tse_0_receive_empty;
	input		eth_tse_0_receive_ready;
	output		eth_tse_0_receive_startofpacket;
	output		eth_tse_0_receive_valid;
	input	[31:0]	eth_tse_0_transmit_data;
	input		eth_tse_0_transmit_endofpacket;
	input		eth_tse_0_transmit_error;
	input	[1:0]	eth_tse_0_transmit_empty;
	output		eth_tse_0_transmit_ready;
	input		eth_tse_0_transmit_startofpacket;
	input		eth_tse_0_transmit_valid;
	input		reset_reset_n;
endmodule
