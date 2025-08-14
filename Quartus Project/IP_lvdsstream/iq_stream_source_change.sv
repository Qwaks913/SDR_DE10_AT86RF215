//=====================================================================
// iq_stream_source_change.sv
// Avalon-ST Source qui envoie iq_word_in dès qu'il change
// – clk = delayedCLK  (64 MHz)
// – reset = actif-haut
// – iq_word_in change seulement sur nouveaux mots valides
// 
// CORRECTION BYTE ORDER: Ce module applique une correction de l'ordre 
// des bytes pour compenser le byte swapping effectué par l'adaptateur
// de format de données lors de la conversion 32->64 bits.
// Input:  [B3][B2][B1][B0] -> Output: [B0][B1][B2][B3]
// Après l'adaptateur: [B3][B2][B1][B0] (ordre correct restauré)
//=====================================================================================================================================
// iq_stream_source_change.sv
// Avalon-ST Source qui envoie iq_word_in dès qu’il change
// – clk = delayedCLK  (64 MHz)
// – reset = actif-haut
// – iq_word_in change seulement sur nouveaux mots valides
//=====================================================================
module iq_stream_source_change #(
  parameter DATA_W = 32
)(
  input  logic              clk,            // delayedCLK
  input  logic              reset,          // actif-haut
  input  logic [DATA_W-1:0] iq_word_in,     // mot I/Q 32 bits
  input  logic              word_valid_in,  // pulse quand iq_word_in valide
  // Avalon-ST Source  
  output logic [DATA_W-1:0] stream_tdata,
  output logic              stream_tvalid,
  input  logic              stream_tready,
  output logic              stream_tstart,   // SOP
  output logic              stream_tlast     // EOP (single-beat)
);

  // Indique “j’ai capturé iq_word_in et j’attends tready”
  logic pending;  
  // Pour détecter un changement
  logic [DATA_W-1:0] prev_word;  
  // Registre qui stocke le mot à envoyer
  logic [DATA_W-1:0] data_reg;  

  // ------------------------------
  // 1) Détection de changement
  // ------------------------------
  // On pulse start/last dès qu’on voit un nouveau mot
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      pending       <= 1'b0;
      prev_word     <= '0;
      data_reg      <= '0;
      stream_tvalid <= 1'b0;
      stream_tstart <= 1'b0;
      stream_tlast  <= 1'b0;
    end else begin
      // par défaut, on clear start/last
      stream_tstart <= 1'b0;
      stream_tlast  <= 1'b0;

      // Si pas déjà en attente ET un nouveau mot valide
      if (!pending && word_valid_in) begin
        // On capture la nouvelle donnée avec correction de l'ordre des bytes
        // pour compenser le byte swapping de l'adaptateur 32->64 bits
        data_reg   <= {iq_word_in[7:0], iq_word_in[15:8], iq_word_in[23:16], iq_word_in[31:24]};
        prev_word  <= iq_word_in;
        pending    <= 1'b1;
        // On marque tvalid + SOP/EOP
        stream_tstart <= 1'b1;
        stream_tlast  <= 1'b1;
      end
      // Une fois que l’esclave a lu (tready=1)
      else if (pending && stream_tready) begin
        pending    <= 1'b0;
      end

      // tvalid suit pending
      stream_tvalid <= pending;
    end
  end

  // ------------------------------
  // 2) Liaison des données
  // ------------------------------
  assign stream_tdata = data_reg;

endmodule
