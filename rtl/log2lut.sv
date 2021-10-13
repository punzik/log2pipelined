`timescale 1ns/100ps
`default_nettype none

/**
 * Calculating the binary logarithm using lookup table.
 * Optional interpolation between table points.
 */
module log2lut
  (clock, reset,
   data_i, valid_i,
   log2_o, valid_o);

    parameter INPUT_WIDTH = 16;
    parameter INPUT_POINT = 15;
    parameter OUTPUT_POINT = 15;
    parameter TABLE_WIDTH = 6;
    parameter INTERPOLATION = 0;

    localparam NORM_W = $clog2(INPUT_WIDTH);
    localparam OUTPUT_INT_W = NORM_W + 1;
    localparam OUTPUT_WIDTH = OUTPUT_INT_W + OUTPUT_POINT;

    localparam TABLE_WIDTH0 = (TABLE_WIDTH >= INPUT_WIDTH) ? INPUT_WIDTH-1 : TABLE_WIDTH;
    localparam TABLE_LEN = 2 ** TABLE_WIDTH0;
    localparam LM_WIDTH = INPUT_WIDTH-TABLE_WIDTH0-1;
    localparam DO_IPOL = (INTERPOLATION == 1 && LM_WIDTH > 1) ? 1 : 0;

    input wire clock;
    input wire reset;

    input wire [INPUT_WIDTH-1:0] data_i;
    input wire valid_i;
    output wire [OUTPUT_WIDTH-1:0] log2_o;
    output wire valid_o;

    // Make lookup table
    reg [OUTPUT_POINT-1:0] tbl[TABLE_LEN];
    /* verilator lint_off UNUSED */
    reg [OUTPUT_POINT-1:0] lin[TABLE_LEN];
    /* verilator lint_on UNUSED */

    initial begin
        real x0, x1;
        for (int i = 0; i < TABLE_LEN; i = i + 1) begin
            if (DO_IPOL == 1) begin
                x0 = $ln(1+real'(i)/TABLE_LEN) / $ln(2);
                x1 = $ln(1+real'(i+1)/TABLE_LEN) / $ln(2);
                lin[i] = OUTPUT_POINT'(int'((x1-x0) * (2 ** OUTPUT_POINT)));
            end
            else
              x0 = $ln(1+(real'(i)+0.5)/TABLE_LEN) / $ln(2);

            tbl[i] = OUTPUT_POINT'(int'(x0 * (2 ** OUTPUT_POINT)));
        end
    end

    // Input data normalization
    /* verilator lint_off UNUSED */
    reg [INPUT_WIDTH-1:0] data_norm;
    /* verilator lint_on UNUSED */
    reg [NORM_W-1:0] norm;
    wire norm_valid;

    normalize #(.WIDTH(INPUT_WIDTH))
    normalize_0
      (.clock, .reset,
       .data_i, .valid_i,
       .data_o(data_norm),
       .norm_o(norm),
       .valid_o(norm_valid));

    // Getting value of the fractional part from lookup table
    reg [OUTPUT_POINT-1:0] t_0;
    reg signed [OUTPUT_INT_W-1:0] l2_0;

    always_ff @(posedge clock) begin
        t_0 <= tbl[data_norm[INPUT_WIDTH-2 -: TABLE_WIDTH0]];
        l2_0 <= OUTPUT_INT_W'(int'(INPUT_WIDTH) - int'(norm) - int'(INPUT_POINT) - 1);
    end

    if (DO_IPOL == 1) begin
        reg [OUTPUT_POINT-1:0] l;
        reg [LM_WIDTH-1:0] lm;

        // Get interpolation coefficient and rest fraction
        always_ff @(posedge clock) begin
            l <= lin[data_norm[INPUT_WIDTH-2 -: TABLE_WIDTH0]];
            lm <= data_norm[INPUT_WIDTH-TABLE_WIDTH0-2 -: LM_WIDTH];
        end

        // Multiply interpolation coefficient to fraction
        reg [OUTPUT_POINT-1:0] t_1;
        reg signed [OUTPUT_INT_W-1:0] l2_1;
        /* verilator lint_off UNUSED */
        reg [OUTPUT_POINT+LM_WIDTH-1:0] m;
        /* verilator lint_on UNUSED */

        always_ff @(posedge clock) begin
            m <= (l * lm) >> LM_WIDTH;
            t_1 <= t_0;
            l2_1 <= l2_0;
        end

        // Add multiply result to table value and merge with integer part of log2
        reg [OUTPUT_WIDTH-1:0] log2_reg;

        always_ff @(posedge clock)
          log2_reg <= {l2_1, t_1 + m[0 +: OUTPUT_POINT]};

        // Valid signal propagation
        reg [2:0] valid_pp;

        always_ff @(posedge clock)
          if (reset) valid_pp <= '0;
          else       valid_pp <= {valid_pp[1:0], norm_valid};

        assign log2_o = log2_reg;
        assign valid_o = valid_pp[2];
    end
    else begin
        // Merge integer part and table value
        assign log2_o = {l2_0, t_0};

        // Valid signal propagation
        reg valid_pp;

        always_ff @(posedge clock)
          if (reset) valid_pp <= 1'b0;
          else       valid_pp <= norm_valid;

        assign valid_o = valid_pp;
    end

endmodule
