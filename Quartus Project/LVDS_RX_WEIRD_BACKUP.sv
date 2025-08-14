//=====================================================================
//  AT86RF215  ➜  Cyclone-V  LVDS RX  (4 Msamples/s, 32 bits)
//  Mot complet : 10 I[13:0] 01 Q[13:0]         (§4.5.4)
//  Synchro : I_SYNC attendu 16 bits après Q_SYNC
//            ou après ≥32 zéros                (§4.5.6)
//=====================================================================
module rf215_lvds_rx
#(
    parameter WORD_BITS = 32
)(
    input  wire                 rst_n,      // reset actif bas
    // — LVDS déjà converti en single-ended par les IBUF_DIFF —
    input  wire                 rxclk,      // 64 MHz (centre-aligné)
    input  wire                 rxd,        // bit série RXD±
    // — sorties parallèles —
    output reg  [WORD_BITS-1:0] iq_word,
    output reg                  word_valid,
    output reg                  sync_ok,
    output wire [1:0]           instant_bit_pair
);
	logic [WORD_BITS:0] iq_word_tempo;

    //=================================================================
    // 0. Bufferisation + PLL de retard (½ période ≃ 7,8 ns)
    //=================================================================
    wire myBufferedClock, delayedCLK, pllLOCKED;

    clkbuffer myClkBuffer (
        .inclk  (rxclk),          // entrée 64 MHz
        .outclk (myBufferedClock) // buffer global (routing dédié)
    );

    LVDSPLL_0002 myLVDSPLL (
        .refclk   (myBufferedClock),
        .rst      (1'b0),
        .outclk_0 (delayedCLK),   // horloge 64 MHz retardée de 180°
        .locked   (pllLOCKED)
    );

    //=================================================================
    // 1. Désérialiseur DDR 1:2  — 2 bits / front 64 MHz
    //=================================================================
    wire [1:0] bit_pair;                   // {front↑ , front↓}

    myALTLVDSRX u_lvds_rx (
        .rx_in      (rxd),                // données SLVDS
        .rx_inclock (delayedCLK),         // horloge retardée
        .rx_out     (bit_pair)            // désérialisé
    );

    // TAP debug direct (instantané)
    (* keep = "true", preserve = "true" *)
    reg [1:0] rx_data_dbg /* synthesis noprune */ = 2'b00;
    always @(posedge delayedCLK) rx_data_dbg <= bit_pair;
    assign instant_bit_pair = rx_data_dbg;

    //=================================================================
    // 2. FSM de synchronisation + registre décalant 32 bits
    //=================================================================
    localparam [1:0] HUNT   = 2'd0,   // recherche I_SYNC
                     SYNCED = 2'd1;   // aligné

    reg [1:0] state        = HUNT;
    reg [WORD_BITS-1:0] shift = '0;   // registre 32 bits
    reg [4:0] bit_cnt       = 5'd0;   // 0-15 (16×2 bits = 32)

    wire [WORD_BITS-1:0] next_shift = {shift[WORD_BITS-3:0], bit_pair};

    always @(posedge delayedCLK or negedge rst_n) begin
        if (!rst_n) begin
            state      <= HUNT;
            shift      <= '0;
            bit_cnt    <= 5'd0;
				iq_word_tempo    <= '0;
            word_valid <= 1'b0;
            sync_ok    <= 1'b0;
        end else begin
            // — décalage (2 bits / cycle) —
            shift <= next_shift;
            word_valid <= 1'b0;           // par défaut

            case (state)
            //=========================================================
            // ÉTAT HUNT : attente d’un motif I_SYNC = 10
            //=========================================================
            HUNT: begin
                // I_SYNC valide si :
                //   • après ≥32 zéros, ou
                //   • 16 bits après un Q_SYNC
                if (next_shift[31:30] == 2'b10) begin
                    state   <= SYNCED;
                    bit_cnt <= 5'd0;
                end
            end
            //=========================================================
            // ÉTAT SYNCED : sortie d’un mot toutes les 16 cycles
            //=========================================================
            SYNCED: begin
                bit_cnt <= bit_cnt + 1'b1;

                if (bit_cnt == 5'd15) begin      // 32 bits reçus
                    iq_word_tempo    <= next_shift;
                    word_valid <= 1'b1;
                    bit_cnt    <= 5'd0;

                    // Test des motifs de synchro (§4.5.6)
                    if (next_shift[31:30] == 2'b10 &&
                        next_shift[15:14] == 2'b01) begin
                        sync_ok <= 1'b1;               // mot OK
                    end else if (next_shift == {WORD_BITS{1'b0}}) begin
                        // Zero-word : pas de données, mais toujours aligné
                        sync_ok <= 1'b0;
                    end else begin
                        // motif incorrect : perte de synchro
                        sync_ok <= 1'b0;
                        state   <= HUNT;
                    end
                end
            end
            default: state <= HUNT;
            endcase
        end
    end
	always @(negedge word_valid or negedge rst_n) begin
		if (!rst_n) begin
			iq_word    <= '0;
		end
		else if(sync_ok == 1'b1) begin
			iq_word <= iq_word_tempo;
		end
	end
endmodule
