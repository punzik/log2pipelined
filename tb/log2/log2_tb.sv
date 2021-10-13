`timescale 1ns/100ps

module log2_tb;
    logic clock = 1'b0;
    logic reset = 1'b1;

    /* Master clock 100MHz (10ns period) */
    /* verilator lint_off STMTDLY */
    always #(10ns/2) clock = ~clock;
    /* verilator lint_on STMTDLY */

    parameter TRIES = 10000;
    parameter IWIDTH = 18;
    parameter IPOINT = 16;
    parameter OPOINT = 12;
    parameter TABLE_WIDTH = 8;
    parameter TABLE_WIDTH_INT = 3;
    parameter CORDIC_STAGES = 12;

    localparam OWIDTH = $clog2(IWIDTH) + OPOINT + 1;

    logic [IWIDTH-1:0] data_i;
    reg valid_i;

    logic signed [OWIDTH-1:0] log2lin_o;
    logic signed [OWIDTH-1:0] log2lut1_o;
    logic signed [OWIDTH-1:0] log2lut2_o;
    logic signed [OWIDTH-1:0] log2crd1_o;
    logic signed [OWIDTH-1:0] log2crd2_o;
    logic signed [OWIDTH-1:0] log2crd3_o;

    wire valid_lin;
    wire valid_lut1;
    wire valid_lut2;
    wire valid_crd1;
    wire valid_crd2;
    wire valid_crd3;

    // Cordic log2
    log2cordic #(.INPUT_WIDTH(IWIDTH),
                 .INPUT_POINT(IPOINT),
                 .OUTPUT_POINT(OPOINT),
                 .STAGES(CORDIC_STAGES),
                 .STAGES_DBL_MASK(0))
    log2cordic_v1_DUT
      (.clock, .reset,
       .data_i,
       .valid_i,
       .log2_o(log2crd1_o),
       .valid_o(valid_crd1));

    // Cordic log2 doubles all stages
    log2cordic #(.INPUT_WIDTH(IWIDTH),
                 .INPUT_POINT(IPOINT),
                 .OUTPUT_POINT(OPOINT),
                 .STAGES(CORDIC_STAGES),
                 .STAGES_DBL_MASK('hAAAA))
    log2cordic_v2_DUT
      (.clock, .reset,
       .data_i,
       .valid_i,
       .log2_o(log2crd2_o),
       .valid_o(valid_crd2));

    // Cordic log2 V3 doubles some stages
    log2cordic #(.INPUT_WIDTH(IWIDTH),
                 .INPUT_POINT(IPOINT),
                 .OUTPUT_POINT(OPOINT),
                 .STAGES(CORDIC_STAGES),
                 .STAGES_DBL_MASK('h8888))
    log2cordic_v3_DUT
      (.clock, .reset,
       .data_i,
       .valid_i,
       .log2_o(log2crd3_o),
       .valid_o(valid_crd3));

    // LUT log2 without interpolation
    log2lut #(.INPUT_WIDTH(IWIDTH),
              .INPUT_POINT(IPOINT),
              .OUTPUT_POINT(OPOINT),
              .TABLE_WIDTH(TABLE_WIDTH),
              .INTERPOLATION(0))
    log2lut_v1_DUT
      (.clock, .reset,
       .data_i,
       .valid_i,
       .log2_o(log2lut1_o),
       .valid_o(valid_lut1));

    // LUT log2 with interpolation
    log2lut #(.INPUT_WIDTH(IWIDTH),
              .INPUT_POINT(IPOINT),
              .OUTPUT_POINT(OPOINT),
              .TABLE_WIDTH(TABLE_WIDTH_INT),
              .INTERPOLATION(1))
    log2lut_v2_DUT
      (.clock, .reset,
       .data_i,
       .valid_i,
       .log2_o(log2lut2_o),
       .valid_o(valid_lut2));

    // Linear log2
    log2lin #(.INPUT_WIDTH(IWIDTH),
              .INPUT_POINT(IPOINT),
              .OUTPUT_POINT(OPOINT))
    log2lin_DUT
      (.clock, .reset,
       .data_i,
       .valid_i,
       .log2_o(log2lin_o),
       .valid_o(valid_lin));

    real x_ref[TRIES];
    real y_ref[TRIES];
    real y_lin[TRIES];
    real y_lut1[TRIES];
    real y_lut2[TRIES];
    real y_crd1[TRIES];
    real y_crd2[TRIES];
    real y_crd3[TRIES];

    int cnt_lin = 0;
    int cnt_lut1 = 0;
    int cnt_lut2 = 0;
    int cnt_crd1 = 0;
    int cnt_crd2 = 0;
    int cnt_crd3 = 0;

    function real log2f(real x);
        return $ln(x) / $ln(2);
    endfunction

    always @(posedge clock) begin
        if (valid_lin) begin
            y_lin[cnt_lin] <= real'(log2lin_o) / (2 ** OPOINT);
            cnt_lin <= cnt_lin + 1;
        end

        if (valid_lut1) begin
            y_lut1[cnt_lut1] <= real'(log2lut1_o) / (2 ** OPOINT);
            cnt_lut1 <= cnt_lut1 + 1;
        end

        if (valid_lut2) begin
            y_lut2[cnt_lut2] <= real'(log2lut2_o) / (2 ** OPOINT);
            cnt_lut2 <= cnt_lut2 + 1;
        end

        if (valid_crd1) begin
            y_crd1[cnt_crd1] <= real'(log2crd1_o) / (2 ** OPOINT);
            cnt_crd1 <= cnt_crd1 + 1;
        end

        if (valid_crd2) begin
            y_crd2[cnt_crd2] <= real'(log2crd2_o) / (2 ** OPOINT);
            cnt_crd2 <= cnt_crd2 + 1;
        end

        if (valid_crd3) begin
            y_crd3[cnt_crd3] <= real'(log2crd3_o) / (2 ** OPOINT);
            cnt_crd3 <= cnt_crd3 + 1;
        end
    end

    function real abs(real x);
        return (x < 0) ? -x : x;
    endfunction

    real arg, dx;
    real err, err_max, e;
    real sfb_min;
    real smpl;

`ifdef PLOT
    int fd;
`endif

    initial begin
        arg = 1.0 / (2.0 ** IPOINT);
        dx = ((2.0 ** (IWIDTH-IPOINT)) - 0) / TRIES;

        // arg = 1.0;
        // dx = 1.0 / TRIES;

        data_i = '0;
        valid_i = 1'b0;

        reset = 1'b1;
        repeat(10) @(posedge clock) #1;
        reset = 1'b0;

        valid_i = 1'b1;

        for (int i = 0; i < TRIES; i += 1) begin
            data_i = IWIDTH'(int'(arg * (2 ** IPOINT)));
            @(posedge clock) #1;

            x_ref[i] = real'(data_i) / (2 ** IPOINT);
            y_ref[i] = log2f(x_ref[i]);
            arg = arg + dx;
        end

        valid_i = 1'b0;

        // wait for computation complete
        while (cnt_lin < TRIES  ||
               cnt_lut1 < TRIES  ||
               cnt_lut2 < TRIES  ||
               cnt_crd1 < TRIES ||
               cnt_crd2 < TRIES ||
               cnt_crd3 < TRIES)
          @(posedge clock) #1;

        // print errors
        for (int i = 0; i < 6; i += 1) begin
            err = 0;
            sfb_min = 100;
            err_max = 0;

            for (int n = 0; n < TRIES; n += 1) begin
                case(i)
                  0: smpl = y_lin[n];
                  1: smpl = y_lut1[n];
                  2: smpl = y_lut2[n];
                  3: smpl = y_crd1[n];
                  4: smpl = y_crd2[n];
                  5: smpl = y_crd3[n];
                endcase

                e = abs(y_ref[n] - smpl);

                err = err + e;
                if (e > err_max)
                  err_max = e;

                e = -log2f(e);
                if (e < sfb_min)
                  sfb_min = e;
            end

            err = err/TRIES;

            case(i)
              0: $display("Linear:");
              1: $display("LUT: (LUT size: %0d)", 2 ** TABLE_WIDTH);
              2: $display("LUT: (LUT size: %0d, interpolation)", 2 ** TABLE_WIDTH_INT);
              3: $display("CORDIC (%0d stages):", CORDIC_STAGES);
              4: $display("CORDIC double (%0d stages):", CORDIC_STAGES);
              5: $display("CORDIC mix (%0d stages):", CORDIC_STAGES);
            endcase

            $display("  Err (max):    %.8f", err_max);
            $display("  SFB (min):    %.2f", sfb_min);
            $display("  SFB (mean):   %.2f", -log2f(err));
            $display("  dB err (max): %f db", err_max/log2f(10)*20);
            $display;
        end

`ifdef PLOT
        // dump data to CSV
        fd = $fopen("./log2_tb.csv", "w");

        for (int n = 0; n < TRIES; n += 1)
          $fdisplay(fd, "%.10f\t%.10f\t%.10f\t%.10f\t%.10f\t%.10f\t%.10f\t%.10f",
                    x_ref[n], y_ref[n], y_lin[n], y_lut1[n], y_lut2[n], y_crd1[n], y_crd2[n], y_crd3[n]);

        $fclose(fd);
`endif

        $finish;
    end

`ifdef DUMP
    initial begin
        $dumpfile("log2_tb.fst");
        $dumpvars(0, log2_tb);
    end
`endif

endmodule // log2_tb
