//altlvds_rx BUFFER_IMPLEMENTATION="RAM" CBX_SINGLE_OUTPUT_FILE="ON" clk_src_is_pll="off" COMMON_RX_TX_PLL="OFF" DATA_RATE=""800.0 Mbps"" DESERIALIZATION_FACTOR=2 ENABLE_DPA_CALIBRATION="ON" ENABLE_DPA_MODE="OFF" ENABLE_SOFT_CDR_MODE="OFF" IMPLEMENT_IN_LES="OFF" INCLOCK_BOOST=0 INCLOCK_PERIOD=50000 INCLOCK_PHASE_SHIFT=0 INPUT_DATA_RATE=800 INTENDED_DEVICE_FAMILY=""Cyclone V"" LPM_TYPE="altlvds_rx" LVDS_RX_REG_SETTING="ON" NUMBER_OF_CHANNELS=1 OUTCLOCK_RESOURCE=""Dual-Regional clock"" PORT_RX_DATA_ALIGN="PORT_UNUSED" REFCLK_FREQUENCY=""20.000000 MHz"" REGISTERED_OUTPUT="ON" SIM_DPA_OUTPUT_CLOCK_PHASE_SHIFT=0 USE_CORECLOCK_INPUT="OFF" USE_EXTERNAL_PLL="OFF" X_ON_BITSLIP="ON" rx_in rx_inclock rx_out
//VERSION_BEGIN 24.1 cbx_mgl 2025:03:05:20:10:25:SC cbx_stratixii 2025:03:05:20:03:09:SC cbx_util_mgl 2025:03:05:20:03:09:SC  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 2025  Altera Corporation. All rights reserved.
//  Your use of Altera Corporation's design tools, logic functions 
//  and other software and tools, and any partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Altera Program License 
//  Subscription Agreement, the Altera Quartus Prime License Agreement,
//  the Altera IP License Agreement, or other applicable license
//  agreement, including, without limitation, that your use is for
//  the sole purpose of programming logic devices manufactured by
//  Altera and sold by Altera or its authorized distributors.  Please
//  refer to the Altera Software License Subscription Agreements 
//  on the Quartus Prime software download page.



//synthesis_resources = altlvds_rx 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  mgjm02
	( 
	rx_in,
	rx_inclock,
	rx_out) /* synthesis synthesis_clearbox=1 */;
	input   [0:0]  rx_in;
	input   rx_inclock;
	output   [1:0]  rx_out;

	wire  [1:0]   wire_mgl_prim1_rx_out;

	altlvds_rx   mgl_prim1
	( 
	.rx_in(rx_in),
	.rx_inclock(rx_inclock),
	.rx_out(wire_mgl_prim1_rx_out));
	defparam
		mgl_prim1.buffer_implementation = "RAM",
		mgl_prim1.clk_src_is_pll = "off",
		mgl_prim1.common_rx_tx_pll = "OFF",
		mgl_prim1.data_rate = ""800.0 Mbps"",
		mgl_prim1.deserialization_factor = 2,
		mgl_prim1.enable_dpa_calibration = "ON",
		mgl_prim1.enable_dpa_mode = "OFF",
		mgl_prim1.enable_soft_cdr_mode = "OFF",
		mgl_prim1.implement_in_les = "OFF",
		mgl_prim1.inclock_boost = 0,
		mgl_prim1.inclock_period = 50000,
		mgl_prim1.inclock_phase_shift = 0,
		mgl_prim1.input_data_rate = 800,
		mgl_prim1.intended_device_family = ""Cyclone V"",
		mgl_prim1.lpm_type = "altlvds_rx",
		mgl_prim1.number_of_channels = 1,
		mgl_prim1.outclock_resource = ""Dual-Regional clock"",
		mgl_prim1.port_rx_data_align = "PORT_UNUSED",
		mgl_prim1.refclk_frequency = ""20.000000 MHz"",
		mgl_prim1.registered_output = "ON",
		mgl_prim1.sim_dpa_output_clock_phase_shift = 0,
		mgl_prim1.use_coreclock_input = "OFF",
		mgl_prim1.use_external_pll = "OFF",
		mgl_prim1.x_on_bitslip = "ON",
		mgl_prim1.lpm_hint = "LVDS_RX_REG_SETTING=ON";
	assign
		rx_out = wire_mgl_prim1_rx_out;
endmodule //mgjm02
//VALID FILE
