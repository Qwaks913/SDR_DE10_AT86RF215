	component soc_system is
		port (
			clk_clk                    : in    std_logic                     := 'X';             -- clk
			hps_0_h2f_reset_reset_n    : out   std_logic;                                        -- reset_n
			hps_0_spim0_f_txd          : out   std_logic;                                        -- txd
			hps_0_spim0_f_rxd          : in    std_logic                     := 'X';             -- rxd
			hps_0_spim0_f_ss_in_n      : in    std_logic                     := 'X';             -- ss_in_n
			hps_0_spim0_f_ssi_oe_n     : out   std_logic;                                        -- ssi_oe_n
			hps_0_spim0_f_ss_0_n       : out   std_logic;                                        -- ss_0_n
			hps_0_spim0_f_ss_1_n       : out   std_logic;                                        -- ss_1_n
			hps_0_spim0_f_ss_2_n       : out   std_logic;                                        -- ss_2_n
			hps_0_spim0_f_ss_3_n       : out   std_logic;                                        -- ss_3_n
			hps_0_spim0_sclk_out_f_clk : out   std_logic;                                        -- clk
			lvds_clk_input_clk         : in    std_logic                     := 'X';             -- clk
			lvds_iq_hps_in_new_signal  : in    std_logic_vector(31 downto 0) := (others => 'X'); -- new_signal
			memory_mem_a               : out   std_logic_vector(14 downto 0);                    -- mem_a
			memory_mem_ba              : out   std_logic_vector(2 downto 0);                     -- mem_ba
			memory_mem_ck              : out   std_logic;                                        -- mem_ck
			memory_mem_ck_n            : out   std_logic;                                        -- mem_ck_n
			memory_mem_cke             : out   std_logic;                                        -- mem_cke
			memory_mem_cs_n            : out   std_logic;                                        -- mem_cs_n
			memory_mem_ras_n           : out   std_logic;                                        -- mem_ras_n
			memory_mem_cas_n           : out   std_logic;                                        -- mem_cas_n
			memory_mem_we_n            : out   std_logic;                                        -- mem_we_n
			memory_mem_reset_n         : out   std_logic;                                        -- mem_reset_n
			memory_mem_dq              : inout std_logic_vector(31 downto 0) := (others => 'X'); -- mem_dq
			memory_mem_dqs             : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs
			memory_mem_dqs_n           : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs_n
			memory_mem_odt             : out   std_logic;                                        -- mem_odt
			memory_mem_dm              : out   std_logic_vector(3 downto 0);                     -- mem_dm
			memory_oct_rzqin           : in    std_logic                     := 'X';             -- oct_rzqin
			reset_reset_n              : in    std_logic                     := 'X';             -- reset_n
			word_valid_word_valid      : in    std_logic                     := 'X'              -- word_valid
		);
	end component soc_system;

	u0 : component soc_system
		port map (
			clk_clk                    => CONNECTED_TO_clk_clk,                    --                    clk.clk
			hps_0_h2f_reset_reset_n    => CONNECTED_TO_hps_0_h2f_reset_reset_n,    --        hps_0_h2f_reset.reset_n
			hps_0_spim0_f_txd          => CONNECTED_TO_hps_0_spim0_f_txd,          --          hps_0_spim0_f.txd
			hps_0_spim0_f_rxd          => CONNECTED_TO_hps_0_spim0_f_rxd,          --                       .rxd
			hps_0_spim0_f_ss_in_n      => CONNECTED_TO_hps_0_spim0_f_ss_in_n,      --                       .ss_in_n
			hps_0_spim0_f_ssi_oe_n     => CONNECTED_TO_hps_0_spim0_f_ssi_oe_n,     --                       .ssi_oe_n
			hps_0_spim0_f_ss_0_n       => CONNECTED_TO_hps_0_spim0_f_ss_0_n,       --                       .ss_0_n
			hps_0_spim0_f_ss_1_n       => CONNECTED_TO_hps_0_spim0_f_ss_1_n,       --                       .ss_1_n
			hps_0_spim0_f_ss_2_n       => CONNECTED_TO_hps_0_spim0_f_ss_2_n,       --                       .ss_2_n
			hps_0_spim0_f_ss_3_n       => CONNECTED_TO_hps_0_spim0_f_ss_3_n,       --                       .ss_3_n
			hps_0_spim0_sclk_out_f_clk => CONNECTED_TO_hps_0_spim0_sclk_out_f_clk, -- hps_0_spim0_sclk_out_f.clk
			lvds_clk_input_clk         => CONNECTED_TO_lvds_clk_input_clk,         --         lvds_clk_input.clk
			lvds_iq_hps_in_new_signal  => CONNECTED_TO_lvds_iq_hps_in_new_signal,  --         lvds_iq_hps_in.new_signal
			memory_mem_a               => CONNECTED_TO_memory_mem_a,               --                 memory.mem_a
			memory_mem_ba              => CONNECTED_TO_memory_mem_ba,              --                       .mem_ba
			memory_mem_ck              => CONNECTED_TO_memory_mem_ck,              --                       .mem_ck
			memory_mem_ck_n            => CONNECTED_TO_memory_mem_ck_n,            --                       .mem_ck_n
			memory_mem_cke             => CONNECTED_TO_memory_mem_cke,             --                       .mem_cke
			memory_mem_cs_n            => CONNECTED_TO_memory_mem_cs_n,            --                       .mem_cs_n
			memory_mem_ras_n           => CONNECTED_TO_memory_mem_ras_n,           --                       .mem_ras_n
			memory_mem_cas_n           => CONNECTED_TO_memory_mem_cas_n,           --                       .mem_cas_n
			memory_mem_we_n            => CONNECTED_TO_memory_mem_we_n,            --                       .mem_we_n
			memory_mem_reset_n         => CONNECTED_TO_memory_mem_reset_n,         --                       .mem_reset_n
			memory_mem_dq              => CONNECTED_TO_memory_mem_dq,              --                       .mem_dq
			memory_mem_dqs             => CONNECTED_TO_memory_mem_dqs,             --                       .mem_dqs
			memory_mem_dqs_n           => CONNECTED_TO_memory_mem_dqs_n,           --                       .mem_dqs_n
			memory_mem_odt             => CONNECTED_TO_memory_mem_odt,             --                       .mem_odt
			memory_mem_dm              => CONNECTED_TO_memory_mem_dm,              --                       .mem_dm
			memory_oct_rzqin           => CONNECTED_TO_memory_oct_rzqin,           --                       .oct_rzqin
			reset_reset_n              => CONNECTED_TO_reset_reset_n,              --                  reset.reset_n
			word_valid_word_valid      => CONNECTED_TO_word_valid_word_valid       --             word_valid.word_valid
		);

