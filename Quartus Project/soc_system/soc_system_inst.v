	soc_system u0 (
		.clk_clk                    (<connected-to-clk_clk>),                    //                    clk.clk
		.hps_0_h2f_reset_reset_n    (<connected-to-hps_0_h2f_reset_reset_n>),    //        hps_0_h2f_reset.reset_n
		.hps_0_spim0_f_txd          (<connected-to-hps_0_spim0_f_txd>),          //          hps_0_spim0_f.txd
		.hps_0_spim0_f_rxd          (<connected-to-hps_0_spim0_f_rxd>),          //                       .rxd
		.hps_0_spim0_f_ss_in_n      (<connected-to-hps_0_spim0_f_ss_in_n>),      //                       .ss_in_n
		.hps_0_spim0_f_ssi_oe_n     (<connected-to-hps_0_spim0_f_ssi_oe_n>),     //                       .ssi_oe_n
		.hps_0_spim0_f_ss_0_n       (<connected-to-hps_0_spim0_f_ss_0_n>),       //                       .ss_0_n
		.hps_0_spim0_f_ss_1_n       (<connected-to-hps_0_spim0_f_ss_1_n>),       //                       .ss_1_n
		.hps_0_spim0_f_ss_2_n       (<connected-to-hps_0_spim0_f_ss_2_n>),       //                       .ss_2_n
		.hps_0_spim0_f_ss_3_n       (<connected-to-hps_0_spim0_f_ss_3_n>),       //                       .ss_3_n
		.hps_0_spim0_sclk_out_f_clk (<connected-to-hps_0_spim0_sclk_out_f_clk>), // hps_0_spim0_sclk_out_f.clk
		.lvds_clk_input_clk         (<connected-to-lvds_clk_input_clk>),         //         lvds_clk_input.clk
		.lvds_iq_hps_in_new_signal  (<connected-to-lvds_iq_hps_in_new_signal>),  //         lvds_iq_hps_in.new_signal
		.memory_mem_a               (<connected-to-memory_mem_a>),               //                 memory.mem_a
		.memory_mem_ba              (<connected-to-memory_mem_ba>),              //                       .mem_ba
		.memory_mem_ck              (<connected-to-memory_mem_ck>),              //                       .mem_ck
		.memory_mem_ck_n            (<connected-to-memory_mem_ck_n>),            //                       .mem_ck_n
		.memory_mem_cke             (<connected-to-memory_mem_cke>),             //                       .mem_cke
		.memory_mem_cs_n            (<connected-to-memory_mem_cs_n>),            //                       .mem_cs_n
		.memory_mem_ras_n           (<connected-to-memory_mem_ras_n>),           //                       .mem_ras_n
		.memory_mem_cas_n           (<connected-to-memory_mem_cas_n>),           //                       .mem_cas_n
		.memory_mem_we_n            (<connected-to-memory_mem_we_n>),            //                       .mem_we_n
		.memory_mem_reset_n         (<connected-to-memory_mem_reset_n>),         //                       .mem_reset_n
		.memory_mem_dq              (<connected-to-memory_mem_dq>),              //                       .mem_dq
		.memory_mem_dqs             (<connected-to-memory_mem_dqs>),             //                       .mem_dqs
		.memory_mem_dqs_n           (<connected-to-memory_mem_dqs_n>),           //                       .mem_dqs_n
		.memory_mem_odt             (<connected-to-memory_mem_odt>),             //                       .mem_odt
		.memory_mem_dm              (<connected-to-memory_mem_dm>),              //                       .mem_dm
		.memory_oct_rzqin           (<connected-to-memory_oct_rzqin>),           //                       .oct_rzqin
		.reset_reset_n              (<connected-to-reset_reset_n>),              //                  reset.reset_n
		.word_valid_word_valid      (<connected-to-word_valid_word_valid>)       //             word_valid.word_valid
	);

