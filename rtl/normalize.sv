`timescale 1ns/100ps
`default_nettype none

/**
 * Normalize data_i before calculating logarithm.
 * Shifts data to the left until the most significant bit is equal to one.
 * Returns the shifted number and the number of shifted bits.
 */
module normalize #(parameter WIDTH = 16)
    (clock, reset, data_i, valid_i, data_o, norm_o, valid_o);

    localparam NORM_W = $clog2(WIDTH);

    input wire clock;
    input wire reset;

    input wire [WIDTH-1:0] data_i;
    input wire valid_i;

    output wire [WIDTH-1:0] data_o;
    output wire [NORM_W-1:0] norm_o;
    output wire valid_o;

    // Normalization
    localparam STEPS = $clog2(WIDTH);

    reg [WIDTH-1:0] data_pp[STEPS];
    reg [NORM_W-1:0] norm_pp[STEPS];

    genvar n;
    for (n = 0; n < STEPS; n = n + 1) begin: step
        localparam MASK_LEN = 1 << (STEPS-n-1);

        wire [WIDTH-1:0] prev_data;
        wire [NORM_W-1:0] prev_norm;

        assign prev_data = (n == 0) ? data_i : data_pp[n-1];
        assign prev_norm = (n == 0) ? '0 : norm_pp[n-1];

        always_ff @(posedge clock)
          if (reset) begin
              data_pp[n] <= '0;
              norm_pp[n] <= '0;
          end
          else
            if ((prev_data & {{MASK_LEN{1'b1}}, {(WIDTH-MASK_LEN){1'b0}}}) == '0) begin
                data_pp[n] <= prev_data << MASK_LEN;
                norm_pp[n] <= prev_norm + MASK_LEN;
            end
            else begin
                data_pp[n] <= prev_data;
                norm_pp[n] <= prev_norm;
            end
    end

    // Valid signal propagation
    reg [STEPS-1:0] valid_pp;

    always_ff @(posedge clock)
      if (reset)
        valid_pp <= '0;
      else
        if (STEPS > 1)
          valid_pp <= {valid_pp[STEPS-2:0], valid_i};
        else
          valid_pp[0] <= valid_i;

    // Output assignments
    assign data_o = data_pp[STEPS-1];
    assign norm_o = norm_pp[STEPS-1];
    assign valid_o = valid_pp[STEPS-1];

endmodule
