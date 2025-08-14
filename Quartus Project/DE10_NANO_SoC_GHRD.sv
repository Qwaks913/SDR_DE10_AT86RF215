//=====================================================================
//  DE10_NANO_SoC_GHRD  –  top level
//  +  Réception LVDS (AT86RF215 ➜ Cyclone-V) : module rf215_lvds_rx
//=====================================================================

module DE10_NANO_SoC_GHRD
(
    //---------------------------------------------------------------
    //  Horloges carte
    //---------------------------------------------------------------
    input               FPGA_CLK1_50,
    input               FPGA_CLK3_50,

    //---------------------------------------------------------------
    //  DDR3 HPS  (inchangé)
    //---------------------------------------------------------------
    output   [14:0]     HPS_DDR3_ADDR,
    output   [ 2:0]     HPS_DDR3_BA,
    output              HPS_DDR3_CAS_N,
    output              HPS_DDR3_CK_N,
    output              HPS_DDR3_CK_P,
    output              HPS_DDR3_CKE,
    output              HPS_DDR3_CS_N,
    output   [ 3:0]     HPS_DDR3_DM,
    inout    [31:0]     HPS_DDR3_DQ,
    inout    [ 3:0]     HPS_DDR3_DQS_N,
    inout    [ 3:0]     HPS_DDR3_DQS_P,
    output              HPS_DDR3_ODT,
    output              HPS_DDR3_RAS_N,
    output              HPS_DDR3_RESET_N,
    input               HPS_DDR3_RZQ,
    output              HPS_DDR3_WE_N,

    

    //---------------------------------------------------------------
    //  SPI maître (HPS ➜ AT86RF215)
    //---------------------------------------------------------------
    output              spi_MOSI,
    input               spi_MISO,
    output              spi_CLK,
    output              spi_CS,

    //---------------------------------------------------------------
    //  LVDS vers FPGA (AT86RF215 RX)
    //  -> signaux single-ended après IBUF_DIFF
    //---------------------------------------------------------------
    input               LVDS_clk_in,   // 64 MHz
    input               LVDS_data_in   // flux série
);

    //===============================================================
    //  Fils internes
    //===============================================================
    wire        hps_fpga_reset_n;
    wire  [6:0] fpga_led_internal;

    /* SPI internes */
    wire        spi_tx;          // MOSI
    wire        spi_rx;          // MISO
    wire [5:0]  spi_sss;         // chip-selects divers
    wire        spi_clk_int;     // SCLK HPS
    wire        cs_fused_n;      // CS «plat» vers transceiver

    /* --- sortie du récepteur LVDS --- */
    logic [31:0] iq_word;
	// always @(posedge delayedCLK) begin
	//	if (iq_word == 32'b01110000000000000000000000010101) begin
	//		iq_word 	<= 32'b01101100000000000000000000111100;
	//	end else begin
	//		iq_word 	<= 32'b01110000000000000000000000010101;
	//	end
	//end
	
    wire        word_valid;
    wire        sync_ok;

    //===============================================================
    //  Connexions simples
    //===============================================================
    assign spi_MOSI = spi_tx;
    assign spi_rx   = spi_MISO;
    assign spi_CLK  = spi_clk_int;
    assign spi_CS   = cs_fused_n;

    //===============================================================
    //  Instance Platform Designer
    //===============================================================
    soc_system u0
    (
        .clk_clk                    (FPGA_CLK1_50),
        .reset_reset_n              (hps_fpga_reset_n),

        /* DDR3 (inchangé) */
        .memory_mem_a               (HPS_DDR3_ADDR),
        .memory_mem_ba              (HPS_DDR3_BA),
        .memory_mem_ck              (HPS_DDR3_CK_P),
        .memory_mem_ck_n            (HPS_DDR3_CK_N),
        .memory_mem_cke             (HPS_DDR3_CKE),
        .memory_mem_cs_n            (HPS_DDR3_CS_N),
        .memory_mem_ras_n           (HPS_DDR3_RAS_N),
        .memory_mem_cas_n           (HPS_DDR3_CAS_N),
        .memory_mem_we_n            (HPS_DDR3_WE_N),
        .memory_mem_reset_n         (HPS_DDR3_RESET_N),
        .memory_mem_dq              (HPS_DDR3_DQ),
        .memory_mem_dqs             (HPS_DDR3_DQS_P),
        .memory_mem_dqs_n           (HPS_DDR3_DQS_N),
        .memory_mem_odt             (HPS_DDR3_ODT),
        .memory_mem_dm              (HPS_DDR3_DM),
        .memory_oct_rzqin           (HPS_DDR3_RZQ),

        /* reset exporté vers FPGA-fabric */
        .hps_0_h2f_reset_reset_n    (hps_fpga_reset_n),

        /* SPI-M0 (HPS) */
        .hps_0_spim0_f_txd          (spi_tx),
        .hps_0_spim0_f_rxd          (spi_rx),
        .hps_0_spim0_f_ss_in_n      (spi_sss[0]),
        .hps_0_spim0_f_ssi_oe_n     (spi_sss[1]),
        .hps_0_spim0_f_ss_0_n       (spi_sss[2]),
        .hps_0_spim0_f_ss_1_n       (spi_sss[3]),
        .hps_0_spim0_f_ss_2_n       (spi_sss[4]),
        .hps_0_spim0_f_ss_3_n       (spi_sss[5]),
        .hps_0_spim0_sclk_out_f_clk (spi_clk_int),
		  //LVDS
		  .lvds_clk_input_clk (delayedCLK),
		  .lvds_iq_hps_in_new_signal (iq_word),
          .word_valid_word_valid (word_valid)
    );
	 
	 //PLL SIGNALTAP
	 wire clk200;
	 wire pll_locked;
	 
	 signalTAPPLL_0002 mySignalTAPPLL(
	.refclk (FPGA_CLK1_50),
	.rst    (1'b0),
	.outclk_0(clk200),
	.locked(pll_locked)
	);
	
	
	
    //===============================================================
    //  Fusion des fronts CS  (3 brefs fronts → 1 plateau)
    //===============================================================
    cs_fuser_edges #(.NB_SEG(3)) u_cs_fuser
    (
        .clk      (FPGA_CLK1_50),
        .cs_in_n  (spi_sss[2]),   // SS0 maître
        .cs_out_n (cs_fused_n),
        .reset_n  (hps_fpga_reset_n)
    );

    //===============================================================
    //  Réception LVDS   
    //===============================================================
	 
	 wire delayedCLK;
    rf215_lvds_rx u_lvds_rx
    (
        .rst_n      (hps_fpga_reset_n),
        .rxclk      (LVDS_clk_in),     // 64 MHz venant du transceiver
        .rxd        (LVDS_data_in),    // donnée série
        .iq_word    (iq_word),
        .word_valid (word_valid),
        .sync_ok    (sync_ok),
		  .delayedCLKout (delayedCLK)
    );

    //---------------------------------------------------------------
    //  Quelques LEDs de debug
    //---------------------------------------------------------------
    assign fpga_led_internal[0] = sync_ok;      // LED1 = sync OK
    assign fpga_led_internal[1] = word_valid;   // LED2 clignote à 4 MHz /32
    // autres LEDs libres
    assign fpga_led_internal[6:2] = 5'b0;

    

endmodule
