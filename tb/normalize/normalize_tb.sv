`timescale 1ns/100ps

module normalize_tb;
    logic clock = 1'b0;
    logic reset = 1'b1;

    /* Master clock 100MHz (10ns period) */
    /* verilator lint_off STMTDLY */
    always #(10ns/2) clock = ~clock;
    /* verilator lint_on STMTDLY */

    localparam TRIES = 200;
    localparam WIDTH = 16;
    localparam NORM_W = $clog2(WIDTH);

    reg [WIDTH-1:0] data_i;
    wire [WIDTH-1:0] data_o;
    wire [NORM_W-1:0] norm_o;

    reg valid_i;
    wire valid_o;

    normalize #(.WIDTH(WIDTH)) DUT
      (.clock, .reset,
       .data_i,
       .valid_i,
       .data_o,
       .norm_o,
       .valid_o);

    logic [WIDTH-1:0] data[TRIES];
    int errors = 0;
    int output_count = 0;

    // Reference normalization
    function int norm_ref(logic [WIDTH-1:0] x);
        int n;

        for (n = 0; n < (WIDTH-1) && x[WIDTH-1] == 1'b0; n += 1)
          x = x << 1;

        return n;
    endfunction

    // Compare reference value and calculated in DUT
    always_ff @(posedge clock)
      if (valid_o) begin
          int norm;

          norm = norm_ref(data[output_count]);

          if ((data[output_count] << norm) != data_o || norm != int'(norm_o))
            errors <= errors + 1;

          output_count <= output_count + 1;
      end

    // Testbench procedure
    initial begin
        reset = 1'b1;
        repeat(10) @(posedge clock) #1;
        reset = 1'b0;

        valid_i = 1'b1;

        for (int n = 0; n < TRIES; n += 1) begin
            if (n < 100)
              data[n] = WIDTH'(n);
            else
              data[n] = WIDTH'($urandom % (1 << WIDTH));

            data_i = data[n];
            valid_i = 1'b1;
            @(posedge clock) #1;
            valid_i = 1'b0;

            while(valid_o == 1'b0)
              @(posedge clock) #1;
            @(posedge clock) #1;
        end

        repeat(10) @(posedge clock) #1;

        if (errors == 0)
          $display("Test OK");
        else
          $display("Test FAILED with %0d errors", errors);

        $finish;
    end

`ifdef DUMP
    initial begin
        $dumpfile("normalize_tb.fst");
        $dumpvars(0, normalize_tb);
    end
`endif

endmodule // normalize_tb
