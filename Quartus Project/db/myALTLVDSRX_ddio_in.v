//altddio_in CBX_DECLARE_ALL_CONNECTED_PORTS="OFF" DEVICE_FAMILY="Cyclone V" WIDTH=1 datain dataout_h dataout_l inclock
//VERSION_BEGIN 24.1 cbx_altddio_in 2025:03:05:20:03:09:SC cbx_cycloneii 2025:03:05:20:03:09:SC cbx_maxii 2025:03:05:20:03:09:SC cbx_mgl 2025:03:05:20:10:25:SC cbx_stratix 2025:03:05:20:03:09:SC cbx_stratixii 2025:03:05:20:03:09:SC cbx_stratixiii 2025:03:05:20:03:09:SC cbx_stratixv 2025:03:05:20:03:09:SC cbx_util_mgl 2025:03:05:20:03:09:SC  VERSION_END
//CBXI_INSTANCE_NAME="DE10_NANO_SoC_GHRD_rf215_lvds_rx_u_lvds_rx_myALTLVDSRX_u_lvds_rx_altlvds_rx_ALTLVDS_RX_component_altddio_in_rx_deser_2"
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



//synthesis_resources = IO 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
(* ALTERA_ATTRIBUTE = {"ANALYZE_METASTABILITY=OFF"} *)
module  myALTLVDSRX_ddio_in
	( 
	datain,
	dataout_h,
	dataout_l,
	inclock) /* synthesis synthesis_clearbox=1 */;
	input   [0:0]  datain;
	output   [0:0]  dataout_h;
	output   [0:0]  dataout_l;
	input   inclock;

	wire  [0:0]   wire_ddio_ina_regouthi;
	wire  [0:0]   wire_ddio_ina_regoutlo;

	cyclonev_ddio_in   ddio_ina_0
	( 
	.clk(inclock),
	.datain(datain),
	.regouthi(wire_ddio_ina_regouthi[0:0]),
	.regoutlo(wire_ddio_ina_regoutlo[0:0])
	`ifndef FORMAL_VERIFICATION
	// synopsys translate_off
	`endif
	,
	.areset(1'b0),
	.clkn(1'b0),
	.ena(1'b1),
	.sreset(1'b0)
	`ifndef FORMAL_VERIFICATION
	// synopsys translate_on
	`endif
	// synopsys translate_off
	,
	.devclrn(1'b1),
	.devpor(1'b1),
	.dfflo()
	// synopsys translate_on
	);
	defparam
		ddio_ina_0.async_mode = "none",
		ddio_ina_0.power_up = "low",
		ddio_ina_0.sync_mode = "none",
		ddio_ina_0.use_clkn = "false",
		ddio_ina_0.lpm_type = "cyclonev_ddio_in";
	assign
		dataout_h = wire_ddio_ina_regouthi,
		dataout_l = wire_ddio_ina_regoutlo;
endmodule //myALTLVDSRX_ddio_in
//VALID FILE
