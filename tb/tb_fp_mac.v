`timescale 1ns/1ps

//==============================================================
// Testbench : tb_fp_mac
//
// Tests:
//
//     result = (a * b) + bias
//
//==============================================================

module tb_fp_mac;

    reg        clk;
    reg        rst_n;
    reg        valid_in;

    reg [31:0] a;
    reg [31:0] b;
    reg [31:0] bias;

    wire        valid_out;
    wire [31:0] result;

    integer pass_count;
    integer fail_count;

    //----------------------------------------------------------
    // DUT
    //----------------------------------------------------------

    fp_mac dut (

        .clk       (clk),
        .rst_n     (rst_n),

        .valid_in  (valid_in),

        .a         (a),
        .b         (b),
        .bias      (bias),

        .valid_out (valid_out),
        .result    (result)

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
            "TIME=%0t | rst_n=%b | valid_in=%b | mul_valid=%b | add_valid=%b | result=%h",
            $time,
            rst_n,
            valid_in,
            dut.mul_valid,
            dut.add_valid,
            result
        );

    end

    //----------------------------------------------------------
    // Main test
    //----------------------------------------------------------

    initial begin

        //------------------------------------------------------
        // Initial values
        //------------------------------------------------------

        rst_n    = 1'b0;
        valid_in = 1'b0;

        a    = 32'b0;
        b    = 32'b0;
        bias = 32'b0;

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
        // 5.1 × 3.5 + 1.0
        //
        // 5.1 × 3.5 = 17.85
        //
        // 17.85 + 1 = 18.85
        //
        // Expected FP32:
        // 4196CCCD
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'h40A33333;   // 5.1
        b        = 32'h40600000;   // 3.5
        bias     = 32'h3F800000;   // 1.0
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        //------------------------------------------------------
        // Wait for 4-cycle pipeline
        //------------------------------------------------------

        repeat (3)
            @(posedge clk);

        #1;

        if (valid_out && (result == 32'h4196CCCD)) begin

            $display(
                "PASS: (5.1 * 3.5) + 1.0 = %h",
                result
            );

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: (5.1 * 3.5) + 1.0 | Got=%h | Expected=4196CCCD",
                result
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // TEST 2
        //
        // 2 × 3 + 4 = 10
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'h40000000;   // 2.0
        b        = 32'h40400000;   // 3.0
        bias     = 32'h40800000;   // 4.0
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        repeat (3)
            @(posedge clk);

        #1;

        if (valid_out && (result == 32'h41200000)) begin

            $display(
                "PASS: (2.0 * 3.0) + 4.0 = %h",
                result
            );

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: (2.0 * 3.0) + 4.0 | Got=%h | Expected=41200000",
                result
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // TEST 3
        //
        // 1.5 × 2.5 + (-1.0)
        //
        // 3.75 - 1 = 2.75
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'h3FC00000;   // 1.5
        b        = 32'h40200000;   // 2.5
        bias     = 32'hBF800000;   // -1.0
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        repeat (3)
            @(posedge clk);

        #1;

        if (valid_out && (result == 32'h40300000)) begin

            $display(
                "PASS: (1.5 * 2.5) + (-1.0) = %h",
                result
            );

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: (1.5 * 2.5) + (-1.0) | Got=%h | Expected=40300000",
                result
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // TEST 4
        //
        // -2 × 3 + 10 = 4
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'hC0000000;   // -2
        b        = 32'h40400000;   // 3
        bias     = 32'h41200000;   // 10
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        repeat (3)
            @(posedge clk);

        #1;

        if (valid_out && (result == 32'h40800000)) begin

            $display(
                "PASS: (-2.0 * 3.0) + 10.0 = %h",
                result
            );

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: (-2.0 * 3.0) + 10.0 | Got=%h | Expected=40800000",
                result
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // TEST 5
        //
        // 5 × 0 + 7 = 7
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'h40A00000;   // 5
        b        = 32'h00000000;   // 0
        bias     = 32'h40E00000;   // 7
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        repeat (3)
            @(posedge clk);

        #1;

        if (valid_out && (result == 32'h40E00000)) begin

            $display(
                "PASS: (5.0 * 0.0) + 7.0 = %h",
                result
            );

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: (5.0 * 0.0) + 7.0 | Got=%h | Expected=40E00000",
                result
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // SUMMARY
        //------------------------------------------------------

        $display("");
        $display("==========================================");
        $display("FP32 MAC TEST SUMMARY");
        $display("==========================================");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);
        $display("==========================================");

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $display("==========================================");

        #20;

        $finish;

    end

endmodule