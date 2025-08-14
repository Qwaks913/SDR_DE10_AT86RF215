
module soc_system (
	clk_clk,
	hps_0_h2f_reset_reset_n,
	hps_0_spim0_f_txd,
	hps_0_spim0_f_rxd,
	hps_0_spim0_f_ss_in_n,
	hps_0_spim0_f_ssi_oe_n,
	hps_0_spim0_f_ss_0_n,
	hps_0_spim0_f_ss_1_n,
	hps_0_spim0_f_ss_2_n,
	hps_0_spim0_f_ss_3_n,
	hps_0_spim0_sclk_out_f_clk,
	lvds_clk_input_clk,
	lvds_iq_hps_in_new_signal,
	memory_mem_a,
	memory_mem_ba,
	memory_mem_ck,
	memory_mem_ck_n,
	memory_mem_cke,
	memory_mem_cs_n,
	memory_mem_ras_n,
	memory_mem_cas_n,
	memory_mem_we_n,
	memory_mem_reset_n,
	memory_mem_dq,
	memory_mem_dqs,
	memory_mem_dqs_n,
	memory_mem_odt,
	memory_mem_dm,
	memory_oct_rzqin,
	reset_reset_n,
	word_valid_word_valid);	

	input		clk_clk;
	output		hps_0_h2f_reset_reset_n;
	output		hps_0_spim0_f_txd;
	input		hps_0_spim0_f_rxd;
	input		hps_0_spim0_f_ss_in_n;
	output		hps_0_spim0_f_ssi_oe_n;
	output		hps_0_spim0_f_ss_0_n;
	output		hps_0_spim0_f_ss_1_n;
	output		hps_0_spim0_f_ss_2_n;
	output		hps_0_spim0_f_ss_3_n;
	output		hps_0_spim0_sclk_out_f_clk;
	input		lvds_clk_input_clk;
	input	[31:0]	lvds_iq_hps_in_new_signal;
	output	[14:0]	memory_mem_a;
	output	[2:0]	memory_mem_ba;
	output		memory_mem_ck;
	output		memory_mem_ck_n;
	output		memory_mem_cke;
	output		memory_mem_cs_n;
	output		memory_mem_ras_n;
	output		memory_mem_cas_n;
	output		memory_mem_we_n;
	output		memory_mem_reset_n;
	inout	[31:0]	memory_mem_dq;
	inout	[3:0]	memory_mem_dqs;
	inout	[3:0]	memory_mem_dqs_n;
	output		memory_mem_odt;
	output	[3:0]	memory_mem_dm;
	input		memory_oct_rzqin;
	input		reset_reset_n;
	input		word_valid_word_valid;
endmodule
