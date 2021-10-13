`timescale 1ns/100ps
`default_nettype none

/**
 * Pipelined calculating of the binary logarithm using an
 * CORDIC-like algorithm. It is possible to repeat the stages
 * to improve convergence.
 */
module log2cordic
  (clock, reset,
   data_i, valid_i,
   log2_o, valid_o);

    parameter INPUT_WIDTH = 16;
    parameter INPUT_POINT = 15;
    parameter OUTPUT_POINT = 15;
    parameter STAGES = 8;
    parameter STAGES_DBL_MASK = 0;

    localparam NORM_W = $clog2(INPUT_WIDTH);
    localparam OUTPUT_INT_W = NORM_W + 1;
    localparam OUTPUT_WIDTH = OUTPUT_INT_W + OUTPUT_POINT;

    input wire clock;
    input wire reset;

    input wire [INPUT_WIDTH-1:0] data_i;
    input wire valid_i;
    output wire [OUTPUT_WIDTH-1:0] log2_o;
    output wire valid_o;

    // Normalize input data
    reg [INPUT_WIDTH-1:0] data_norm;
    reg [NORM_W-1:0] norm;
    wire norm_valid;

    normalize #(.WIDTH(INPUT_WIDTH))
    normalize_0
      (.clock, .reset,
       .data_i, .valid_i,
       .data_o(data_norm),
       .norm_o(norm),
       .valid_o(norm_valid));

    // Function returns log2(1 - (2 ** -shift)) in fixed point
    function signed [OUTPUT_WIDTH-1:0] k0(int shift);
        return OUTPUT_WIDTH'(int'($ln(1.0 - (2.0 ** -shift)) / $ln(2) * (2 ** OUTPUT_POINT)));
    endfunction

    // Function returns log2(1 + (2 ** -shift)) in fixed point
    function signed [OUTPUT_WIDTH-1:0] k1(int shift);
        return OUTPUT_WIDTH'(int'($ln(1.0 + (2.0 ** -shift)) / $ln(2) * (2 ** OUTPUT_POINT)));
    endfunction

    // Function returns shift value for stage
    function int stage_shift(int stage);
        stage_shift = 1;

        for (int n = 0; n < stage; n += 1)
          if (STAGES_DBL_MASK[n] == 1'b0)
            stage_shift += 1;
    endfunction

    reg [INPUT_WIDTH-1:0] data_pp[STAGES];
    reg [OUTPUT_WIDTH-1:0] y_pp[STAGES];

    // First stage
    localparam signed [OUTPUT_WIDTH-1:0] K = k1(1);

    always_ff @(posedge clock) begin
        data_pp[0] <= (data_norm >> 1) + (data_norm >> 2);

        // Stage 0: y0 = INPUT_WIDTH - INPUT_POINT - K - norm
        y_pp[0] <= OUTPUT_WIDTH'(INPUT_WIDTH << OUTPUT_POINT) -
                   OUTPUT_WIDTH'(INPUT_POINT << OUTPUT_POINT) - K -
                   (OUTPUT_WIDTH'(norm) << OUTPUT_POINT);
    end

    // Rest stages
    genvar n;
    for (n = 1; n < STAGES; n = n + 1) begin: stage
        localparam SH = stage_shift(n);
        localparam signed [OUTPUT_WIDTH-1:0] K0 = k0(SH);
        localparam signed [OUTPUT_WIDTH-1:0] K1 = k1(SH);

        always_ff @(posedge clock)
          if (data_pp[n-1][INPUT_WIDTH-1] == 1'b1) begin
              data_pp[n] <= data_pp[n-1] - (data_pp[n-1] >> SH);
              y_pp[n] <= y_pp[n-1] - K0;
          end
          else begin
              data_pp[n] <= data_pp[n-1] + (data_pp[n-1] >> SH);
              y_pp[n] <= y_pp[n-1] - K1;
          end
    end

    // Valid signal propagation
    reg [STAGES-1:0] valid_pp;

    always_ff @(posedge clock)
      if (reset) valid_pp <= '0;
      else       valid_pp <= {valid_pp[STAGES-2:0], norm_valid};

    // Output assignments
    assign log2_o = y_pp[STAGES-1];
    assign valid_o = valid_pp[STAGES-1];

endmodule
