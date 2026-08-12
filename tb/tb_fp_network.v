`timescale 1ns/1ps

module tb_fp_network;

    //==========================================================
    // IRIS TEST VECTORS
    //==========================================================

    `include "tb/iris_test_vectors.vh"

    //==========================================================
    // CLOCK / RESET
    //==========================================================

    reg clk;
    reg rst_n;
    reg valid_in;

    //==========================================================
    // NETWORK INPUTS
    //==========================================================

    reg [31:0] x0;
    reg [31:0] x1;
    reg [31:0] x2;
    reg [31:0] x3;

    //==========================================================
    // EXPECTED CLASS
    //==========================================================

    reg [1:0] expected_class;

    //==========================================================
    // HIDDEN LAYER WEIGHTS
    //==========================================================

    reg [31:0] hw00, hw01, hw02, hw03, hb0;
    reg [31:0] hw10, hw11, hw12, hw13, hb1;
    reg [31:0] hw20, hw21, hw22, hw23, hb2;
    reg [31:0] hw30, hw31, hw32, hw33, hb3;

    //==========================================================
    // OUTPUT LAYER WEIGHTS
    //==========================================================

    reg [31:0] ow00, ow01, ow02, ow03, ob0;
    reg [31:0] ow10, ow11, ow12, ow13, ob1;
    reg [31:0] ow20, ow21, ow22, ow23, ob2;

    //==========================================================
    // OUTPUTS
    //==========================================================

    wire        valid_out;

    wire [31:0] y0;
    wire [31:0] y1;
    wire [31:0] y2;

    wire [1:0] class_out;

    //==========================================================
    // COUNTERS
    //==========================================================

    integer sample;
    integer pass_count;
    integer fail_count;

    //==========================================================
    // DUT
    //==========================================================

    fp_network dut (

        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),

        .x0        (x0),
        .x1        (x1),
        .x2        (x2),
        .x3        (x3),

        // Hidden layer
        .hw00      (hw00),
        .hw01      (hw01),
        .hw02      (hw02),
        .hw03      (hw03),
        .hb0       (hb0),

        .hw10      (hw10),
        .hw11      (hw11),
        .hw12      (hw12),
        .hw13      (hw13),
        .hb1       (hb1),

        .hw20      (hw20),
        .hw21      (hw21),
        .hw22      (hw22),
        .hw23      (hw23),
        .hb2       (hb2),

        .hw30      (hw30),
        .hw31      (hw31),
        .hw32      (hw32),
        .hw33      (hw33),
        .hb3       (hb3),

        // Output layer
        .ow00      (ow00),
        .ow01      (ow01),
        .ow02      (ow02),
        .ow03      (ow03),
        .ob0       (ob0),

        .ow10      (ow10),
        .ow11      (ow11),
        .ow12      (ow12),
        .ow13      (ow13),
        .ob1       (ob1),

        .ow20      (ow20),
        .ow21      (ow21),
        .ow22      (ow22),
        .ow23      (ow23),
        .ob2       (ob2),

        .valid_out (valid_out),
        .class_out (class_out),

        .y0        (y0),
        .y1        (y1),
        .y2        (y2)

    );

    //==========================================================
    // CLOCK
    //==========================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    //==========================================================
    // TRAINED WEIGHTS
    //==========================================================

    initial begin

        //======================================================
        // Hidden layer
        //======================================================

        hw00 = 32'hBE455101;
        hw01 = 32'h3E38E852;
        hw02 = 32'hBF151F4F;
        hw03 = 32'hBED63BD9;
        hb0  = 32'h3EA89343;

        hw10 = 32'h3E9E3CBB;
        hw11 = 32'h3F2E3715;
        hw12 = 32'hBF7EF1B1;
        hw13 = 32'hBEC4F1EF;
        hb1  = 32'h3E991762;

        hw20 = 32'hBF2F4A6D;
        hw21 = 32'hBF53BA56;
        hw22 = 32'h3FA8F40F;
        hw23 = 32'h40077342;
        hb2  = 32'hBF47B473;

        hw30 = 32'hBD4F089A;
        hw31 = 32'h3E2D050E;
        hw32 = 32'hBE5B9DDF;
        hw33 = 32'hBE6AD7F1;
        hb3  = 32'hBF1BFABD;

        //======================================================
        // Output layer
        //======================================================

        ow00 = 32'hBEA353F1;
        ow01 = 32'h3F146FE9;
        ow02 = 32'hBFE8EA92;
        ow03 = 32'h39F5DF47;
        ob0  = 32'h3F5EB6CC;

        ow10 = 32'hBEEA8A52;
        ow11 = 32'hBFEEE300;
        ow12 = 32'hBE8484FA;
        ow13 = 32'h3C25848D;
        ob1  = 32'h40028064;

        ow20 = 32'hBE04CC50;
        ow21 = 32'hBE6F3FB9;
        ow22 = 32'h3FBFA93D;
        ow23 = 32'h3CADC750;
        ob2  = 32'hC00FDF9B;

    end

    //==========================================================
    // TEST
    //==========================================================

    initial begin

        rst_n = 1'b0;
        valid_in = 1'b0;

        x0 = 32'b0;
        x1 = 32'b0;
        x2 = 32'b0;
        x3 = 32'b0;

        expected_class = 2'b0;

        pass_count = 0;
        fail_count = 0;

        //======================================================
        // RESET
        //======================================================

        repeat (2)
            @(posedge clk);

        rst_n = 1'b1;

        //======================================================
        // RUN ALL SAMPLES
        //======================================================

        for (sample = 0;
             sample < NUM_IRIS_SAMPLES;
             sample = sample + 1) begin

            //--------------------------------------------------
            // Load sample
            //--------------------------------------------------

            @(negedge clk);

            x0 = iris_x0[sample];
            x1 = iris_x1[sample];
            x2 = iris_x2[sample];
            x3 = iris_x3[sample];

            expected_class = iris_class[sample];

            valid_in = 1'b1;

            //--------------------------------------------------
            // Send input
            //--------------------------------------------------

            @(posedge clk);

            #1;

            valid_in = 1'b0;

            //--------------------------------------------------
            // Wait for pipeline
            //--------------------------------------------------

            wait (valid_out == 1'b1);

            #1;

            //--------------------------------------------------
            // Compare
            //--------------------------------------------------

            if (class_out == expected_class) begin

                $display(
                    "PASS | Sample %0d | Expected=%0d | RTL=%0d",
                    sample,
                    expected_class,
                    class_out
                );

                pass_count = pass_count + 1;

            end

            else begin

                $display(
                    "FAIL | Sample %0d | Expected=%0d | RTL=%0d",
                    sample,
                    expected_class,
                    class_out
                );

                $display(
                    "      x = [%h, %h, %h, %h]",
                    x0, x1, x2, x3
                );

                $display(
                    "      logits = [%h, %h, %h]",
                    y0, y1, y2
                );

                fail_count = fail_count + 1;

            end

            //--------------------------------------------------
            // Give pipeline one idle cycle
            //--------------------------------------------------

            @(posedge clk);

        end

        //======================================================
        // SUMMARY
        //======================================================

        $display("");
        $display("==========================================");
        $display("IRIS FP32 RTL VERIFICATION");
        $display("==========================================");

        $display("Samples tested = %0d", NUM_IRIS_SAMPLES);
        $display("Correct        = %0d", pass_count);
        $display("Incorrect      = %0d", fail_count);

        if (NUM_IRIS_SAMPLES != 0)
            $display(
                "Accuracy       = %0d%%",
                (pass_count * 100) / NUM_IRIS_SAMPLES
            );

        $display("==========================================");

        if (fail_count == 0)
            $display("ALL IRIS TESTS PASSED");
        else
            $display("SOME IRIS TESTS FAILED");

        $display("==========================================");

        #20;

        $finish;

    end

endmodule