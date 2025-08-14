//=====================================================================
// rf215_lvds_rx – version clean : un seul always, détection sur head
//=====================================================================
module rf215_lvds_rx
#(
    parameter WORD_BITS = 32,
    // Si les bits DDR sont inversés, passe SWAP_DDR=1
    parameter SWAP_DDR  = 1'b0  
)(
    input  wire                 rst_n,         // reset actif bas
    input  wire                 rxclk,         // 64 MHz centre-aligné
    input  wire                 rxd,           // SLVDS bit série
    output reg  [WORD_BITS-1:0] iq_word,       // ne s’update que sur mots valides
    output reg                  word_valid,    // pulse 1 cycle delayedCLK
    output reg                  sync_ok,       // 1 = mot data valide, 0 = zero‐word ou framing
    output wire [1:0]           instant_bit_pair,
	 output wire					  delayedCLKout
);

    //=================================================================
    // 0) Clock buffer + PLL de retard (optionnel si SKEWDRV)
    //=================================================================
    wire clk_buf, delayedCLK, pll_locked;
	 assign delayedCLKout = delayedCLK;
    clkbuffer     u_buf  (.inclk(rxclk),      .outclk(clk_buf));
    LVDSPLL_0002  u_pll  (.refclk(clk_buf),   .rst(1'b0),
                          .outclk_0(delayedCLK), .locked(pll_locked));

    //=================================================================
    // 1) ALTLVDS_RX DDR → 2 bits/cycle
    //=================================================================
    wire [1:0] raw_pair;
    // swap si nécessaire
    wire [1:0] bit_pair = SWAP_DDR ? {raw_pair[0], raw_pair[1]}
                                   : raw_pair;

    myALTLVDSRX u_rx (
        .rx_in      (rxd),
        .rx_inclock (delayedCLK),
        .rx_out     (raw_pair)
    );

    // debug TAP
    (* keep, preserve *) reg [1:0] dbg_pair;
    always @(posedge delayedCLK) dbg_pair <= bit_pair;
    assign instant_bit_pair = dbg_pair;

    //=================================================================
    // 2) FSM HUNT / SYNCED + registre 32 bits
    //=================================================================
    localparam HUNT   = 1'b0,
               SYNCED = 1'b1;

    reg        state     = HUNT;
    reg [4:0]  bit_cnt   = 5'd0;            // compte 0..15
    reg [31:0] shift_reg = 32'h0;           // registre de 32 bits

    // on concatène 2 bits à chaque front
    wire [31:0] next_shift = { shift_reg[29:0], bit_pair };

    always @(posedge delayedCLK or negedge rst_n) begin
        if (!rst_n) begin
            state      <= HUNT;
            shift_reg  <= 32'h0;
            bit_cnt    <= 5'd0;
            iq_word    <= 32'h0;
            word_valid <= 1'b0;
            sync_ok    <= 1'b0;
        end else begin
            // 1) on décale en continu
            shift_reg  <= next_shift;
            // 2) on éteint word_valid par défaut
            word_valid <= 1'b0;

            case (state)
            //----------------------------------------
            HUNT: begin
                // on détecte la tête de mot I_SYNC = 10
                if (next_shift[31:30] == 2'b10) begin
                    state   <= SYNCED;
                    bit_cnt <= 5'd0;
                    sync_ok <= 1'b0;
                end
            end

            //----------------------------------------
            SYNCED: begin
                if (bit_cnt == 5'd15) begin
                    // fin des 16 couples => un mot 32 bits complet
                    bit_cnt    <= 5'd0;

                    // -- zero-word ?
                    if (next_shift == 32'h0000_0000) begin
                        sync_ok <= 1'b0;
                        // pas de word_valid pour les zero-words
                    end
                    // -- mot utile valide ? I_SYNC=10 & Q_SYNC=01
                    else if (next_shift[31:30]==2'b10 &&
                             next_shift[15:14]==2'b01) begin
                        iq_word <= next_shift;
                        sync_ok <= 1'b1;
                        word_valid <= 1'b1;  // word_valid seulement pour les vrais mots IQ
                    end
                    // -- faute de framing => retour en chasse
                    else begin
                        sync_ok <= 1'b0;
                        state   <= HUNT;
                        // pas de word_valid pour les erreurs de framing
                    end
                end
                else begin
                    bit_cnt <= bit_cnt + 1'b1;
                end
            end

            default: state <= HUNT;
            endcase
        end
    end
endmodule
