`timescale 1ns/1ps

module tb_fp_argmax;

    reg        clk;
    reg        rst_n;
    reg        valid_in;

    reg [31:0] x0;
    reg [31:0] x1;
    reg [31:0] x2;

    wire        valid_out;
    wire [1:0]  index;

    integer pass_count;
    integer fail_count;

    //----------------------------------------------------------
    // DUT
    //----------------------------------------------------------

    fp_argmax dut (

        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),

        .x0        (x0),
        .x1        (x1),
        .x2        (x2),

        .valid_out (valid_out),
        .index     (index)

    );

    //----------------------------------------------------------
    // Clock
    //----------------------------------------------------------

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end

    //----------------------------------------------------------
    // Monitor
    //----------------------------------------------------------

    always @(posedge clk) begin

        #1;

        $display(
            "TIME=%0t | valid_in=%b | x0=%h | x1=%h | x2=%h | valid_out=%b | index=%d",
            $time,
            valid_in,
            x0,
            x1,
            x2,
            valid_out,
            index
        );

    end

    //----------------------------------------------------------
    // Main test
    //----------------------------------------------------------

    initial begin

        rst_n    = 1'b0;
        valid_in = 1'b0;

        x0 = 32'b0;
        x1 = 32'b0;
        x2 = 32'b0;

        pass_count = 0;
        fail_count = 0;

        //------------------------------------------------------
        // Reset
        //------------------------------------------------------

        repeat (2)
            @(posedge clk);

        rst_n = 1'b1;

        //------------------------------------------------------
        // TEST 1
        //
        // [0.8, 0.1, 0.05]
        //
        // Expected = 0
        //------------------------------------------------------

        @(negedge clk);

        x0 = 32'h3F4CCCCD;   // 0.8
        x1 = 32'h3DCCCCCD;   // 0.1
        x2 = 32'h3D4CCCCD;   // 0.05

        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        if (valid_out && index == 2'd0) begin

            $display("PASS: [0.8, 0.1, 0.05] -> class 0");

            pass_count = pass_count + 1;

        end

        else begin

            $display("FAIL: [0.8, 0.1, 0.05]");

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // TEST 2
        //
        // [0.1, 0.7, 0.2]
        //
        // Expected = 1
        //------------------------------------------------------

        @(negedge clk);

        x0 = 32'h3DCCCCCD;   // 0.1
        x1 = 32'h3F333333;   // 0.7
        x2 = 32'h3E4CCCCD;   // 0.2

        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        if (valid_out && index == 2'd1) begin

            $display("PASS: [0.1, 0.7, 0.2] -> class 1");

            pass_count = pass_count + 1;

        end

        else begin

            $display("FAIL: [0.1, 0.7, 0.2]");

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // TEST 3
        //
        // [0.1, 0.2, 0.9]
        //
        // Expected = 2
        //------------------------------------------------------

        @(negedge clk);

        x0 = 32'h3DCCCCCD;   // 0.1
        x1 = 32'h3E4CCCCD;   // 0.2
        x2 = 32'h3F666666;   // 0.9

        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        if (valid_out && index == 2'd2) begin

            $display("PASS: [0.1, 0.2, 0.9] -> class 2");

            pass_count = pass_count + 1;

        end

        else begin

            $display("FAIL: [0.1, 0.2, 0.9]");

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // TEST 4
        //
        // Negative values
        //
        // [-2, -5, -3]
        //
        // Expected = 0
        //------------------------------------------------------

        @(negedge clk);

        x0 = 32'hC0000000;   // -2
        x1 = 32'hC0A00000;   // -5
        x2 = 32'hC0400000;   // -3

        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        if (valid_out && index == 2'd0) begin

            $display("PASS: [-2, -5, -3] -> class 0");

            pass_count = pass_count + 1;

        end

        else begin

            $display("FAIL: [-2, -5, -3]");

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // TEST 5
        //
        // Positive + negative
        //
        // [-2, 5, 1]
        //
        // Expected = 1
        //------------------------------------------------------

        @(negedge clk);

        x0 = 32'hC0000000;   // -2
        x1 = 32'h40A00000;   // 5
        x2 = 32'h3F800000;   // 1

        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        if (valid_out && index == 2'd1) begin

            $display("PASS: [-2, 5, 1] -> class 1");

            pass_count = pass_count + 1;

        end

        else begin

            $display("FAIL: [-2, 5, 1]");

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // TEST 6
        //
        // Equal values
        //
        // [2, 2, 1]
        //
        // Expected = 0
        //
        // We choose the first maximum.
        //------------------------------------------------------

        @(negedge clk);

        x0 = 32'h40000000;   // 2
        x1 = 32'h40000000;   // 2
        x2 = 32'h3F800000;   // 1

        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        if (valid_out && index == 2'd0) begin

            $display("PASS: [2, 2, 1] -> class 0");

            pass_count = pass_count + 1;

        end

        else begin

            $display("FAIL: [2, 2, 1]");

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Summary
        //------------------------------------------------------

        $display("");
        $display("======================================");
        $display("FP32 ARGMAX TEST SUMMARY");
        $display("======================================");

        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);

        $display("======================================");

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $display("======================================");

        #20;

        $finish;

    end

endmodule