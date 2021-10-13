`timescale 1ns/100ps
`default_nettype none

/**
 * Pipelined calculation of the binary logarithm by linear
 * interpolation of the fractional part.
 */
module log2lin
  (clock, reset,
   data_i, valid_i,
   log2_o, valid_o);

    parameter INPUT_WIDTH = 20;
    parameter INPUT_POINT = 15;
    parameter OUTPUT_POINT = 15;

    localparam NORM_W = $clog2(INPUT_WIDTH);
    localparam OUTPUT_INT_W = NORM_W + 1;
    localparam OUTPUT_WIDTH = OUTPUT_INT_W + OUTPUT_POINT;

    input wire clock;
    input wire reset;

    input wire [INPUT_WIDTH-1:0] data_i;
    input wire valid_i;
    output reg signed [OUTPUT_WIDTH-1:0] log2_o;
    output reg valid_o;

    wire [INPUT_WIDTH-1:0] data_norm;
    wire [NORM_W-1:0] norm;
    wire norm_valid;

    localparam [OUTPUT_WIDTH-1:0] CORRECTOR = OUTPUT_WIDTH'(longint'(0.043 * (2 ** OUTPUT_POINT)));

    normalize #(.WIDTH(INPUT_WIDTH))
    normalize_0
      (.clock, .reset,
       .data_i, .valid_i,
       .data_o(data_norm),
       .norm_o(norm),
       .valid_o(norm_valid));

    /* verilator lint_off UNUSED */
    wire [INPUT_WIDTH+OUTPUT_POINT-1:0] data_ext;
    /* verilator lint_on UNUSED */
    assign data_ext = {data_norm, {OUTPUT_POINT{1'b0}}};

    reg [OUTPUT_WIDTH-1:0] noajust;

    always_ff @(posedge clock)
      noajust <= {OUTPUT_INT_W'(INPUT_WIDTH-INPUT_POINT-1) - norm,
                  data_ext[INPUT_WIDTH+OUTPUT_POINT-2 -: OUTPUT_POINT]};

    always_ff @(posedge clock)
      log2_o <= noajust + CORRECTOR;

    // Valid signal propagation
    reg [1:0] valid;

    always_ff @(posedge clock)
      if (reset) valid <= '0;
      else       valid <= {valid[0], norm_valid};

    assign valid_o = valid[1];

endmodule
