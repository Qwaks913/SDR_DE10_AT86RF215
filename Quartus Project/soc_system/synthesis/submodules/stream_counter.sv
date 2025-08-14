// stream_counter.sv
// Génère un flot Avalon-ST de DATA_W bits à STREAM_RATE_HZ beats/s
module stream_counter #(
  parameter DATA_W         = 64,               // bits par mot (64 pour I/Q regroupé)
  parameter CLK_FREQ_HZ    = 100_000_000,      // fréquence PL en Hz
  parameter STREAM_RATE_HZ = 625_000           // beats/s → 625k×64b = ~40Mbit/s
)(
  input  logic               clk,
  input  logic               reset,            // actif-haut
  // Avalon-ST source
  output logic [DATA_W-1:0]  stream_tdata,
  output logic               stream_tvalid,
  input  logic               stream_tready,
  output logic               stream_tstart,     // startofpacket
  output logic               stream_tlast       // endofpacket
);

  // ---------------------------------------------------
  // 1) Diviseur pour générer tick à STREAM_RATE_HZ
  // ---------------------------------------------------
  localparam integer DIV_MAX = CLK_FREQ_HZ / STREAM_RATE_HZ;
  logic [$clog2(DIV_MAX)-1:0] div_cnt;
  logic                       tick;

  always_ff @(posedge clk) begin
    if (reset) begin
      div_cnt <= '0;
      tick    <= 1'b0;
    end
    else if (div_cnt == DIV_MAX-1) begin
      div_cnt <= '0;
      tick    <= 1'b1;
    end
    else begin
      div_cnt <= div_cnt + 1;
      tick    <= 1'b0;
    end
  end

  // ---------------------------------------------------
  // 2) Compteur + hand-shake Avalon-ST
  // ---------------------------------------------------
  logic [DATA_W-1:0] data_reg;
  logic              pending;

  always_ff @(posedge clk) begin
    if (reset) begin
      data_reg <= '0;
      pending  <= 1'b0;
    end
    else begin
      // À chaque tick, incrémente et valide un nouveau mot
      if (tick) begin
        data_reg <= data_reg + 1;
        pending  <= 1'b1;
      end
      // Quand le mot a été consommé, on efface pending
      else if (pending && stream_tready) begin
        pending <= 1'b0;
      end
    end
  end

  // ---------------------------------------------------
  // 3) Assignations Avalon-ST
  // ---------------------------------------------------
  assign stream_tdata  = data_reg;
  assign stream_tvalid = pending;
  // Chaque tick est début ET fin de "paquet" d'un beat
  assign stream_tstart = tick;
  assign stream_tlast  = tick;

endmodule
