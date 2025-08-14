module cs_fuser_edges #(
    parameter integer NB_SEG = 3   // nb de créneaux CS attendus (octets)
)(
    input  wire clk,               // horloge système (≥ 2× SCLK)
    input  wire cs_in_n,           // /CS du HPS
    output reg  cs_out_n = 1'b1,   // /CS vers RF215
    input  wire reset_n
);
    reg cs_in_d = 1'b1;            // retard 1 clk pour détection d'edge
    reg [2:0] seg_cnt = 3'd0;      // compte les fronts montants vus

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            cs_out_n <= 1'b1;
            seg_cnt  <= 0;
            cs_in_d  <= 1'b1;
        end
        else begin
            /* mémorise l’état précédent de CS maître */
            cs_in_d <= cs_in_n;

            /* ----- descente maître : début de la séquence -------- */
            if (cs_in_d && !cs_in_n && cs_out_n) begin   // front descendant
                cs_out_n <= 1'b0;     // on colle CS esclave
                seg_cnt  <= 0;
            end

            /* ----- front montant maître : fin d’un octet ---------- */
            if (!cs_in_d && cs_in_n && !cs_out_n) begin  // front montant
                seg_cnt <= seg_cnt + 3'd1;
                if (seg_cnt == NB_SEG-1)  // 3ᵉ front pour 3 octets
                    cs_out_n <= 1'b1;     // on relâche CS esclave
            end
        end
    end
endmodule
