`timescale 1ns/1ps

//==============================================================
// Testbench : tb_fp_multiplier
//==============================================================

module tb_fp_multiplier;

    reg        clk;
    reg        rst_n;
    reg        valid_in;

    reg [31:0] a;
    reg [31:0] b;

    wire        valid_out;
    wire [31:0] product;

    integer pass_count;
    integer fail_count;

    //----------------------------------------------------------
    // DUT
    //----------------------------------------------------------

    fp_multiplier dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .a         (a),
        .b         (b),
        .valid_out (valid_out),
        .product   (product)
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
            "TIME=%0t | rst_n=%b | valid_in=%b | valid_reg=%b | valid_out=%b | a_reg=%h | b_reg=%h | product=%h",
            $time,
            rst_n,
            valid_in,
            dut.valid_reg,
            valid_out,
            dut.a_reg,
            dut.b_reg,
            product
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

        a = 32'b0;
        b = 32'b0;

        pass_count = 0;
        fail_count = 0;

        //------------------------------------------------------
        // Reset
        //------------------------------------------------------

        repeat (2)
            @(posedge clk);

        rst_n = 1'b1;

        //------------------------------------------------------
        // Test 1
        //
        // 5.1 × 3.5 = 17.85
        //
        // Expected FP32:
        // 418ECCCD
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'h40A33333;
        b        = 32'h40600000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        @(posedge clk);

        #1;

        if (valid_out && (product == 32'h418ECCCD)) begin

            $display(
                "PASS: 5.1 * 3.5 = %h",
                product
            );

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: 5.1 * 3.5 | Got=%h | Expected=418ECCCD",
                product
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Test 2
        //
        // 2.0 × 3.0 = 6.0
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'h40000000;
        b        = 32'h40400000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        @(posedge clk);

        #1;

        if (valid_out && (product == 32'h40C00000)) begin

            $display(
                "PASS: 2.0 * 3.0 = %h",
                product
            );

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: 2.0 * 3.0 | Got=%h | Expected=40C00000",
                product
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Test 3
        //
        // 1.5 × 2.5 = 3.75
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'h3FC00000;
        b        = 32'h40200000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        @(posedge clk);

        #1;

        if (valid_out && (product == 32'h40700000)) begin

            $display(
                "PASS: 1.5 * 2.5 = %h",
                product
            );

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: 1.5 * 2.5 | Got=%h | Expected=40700000",
                product
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Test 4
        //
        // -2.0 × 3.0 = -6.0
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'hC0000000;
        b        = 32'h40400000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        @(posedge clk);

        #1;

        if (valid_out && (product == 32'hC0C00000)) begin

            $display(
                "PASS: -2.0 * 3.0 = %h",
                product
            );

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: -2.0 * 3.0 | Got=%h | Expected=C0C00000",
                product
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Test 5
        //
        // -2.0 × -3.0 = +6.0
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'hC0000000;
        b        = 32'hC0400000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        @(posedge clk);

        #1;

        if (valid_out && (product == 32'h40C00000)) begin

            $display(
                "PASS: -2.0 * -3.0 = %h",
                product
            );

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: -2.0 * -3.0 | Got=%h | Expected=40C00000",
                product
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Test 6
        //
        // 0 × 5 = 0
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'h00000000;
        b        = 32'h40A00000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        @(posedge clk);

        #1;

        if (valid_out && (product == 32'h00000000)) begin

            $display(
                "PASS: 0.0 * 5.0 = %h",
                product
            );

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: 0.0 * 5.0 | Got=%h | Expected=00000000",
                product
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Test 7
        //
        // 1.0 × 1.0 = 1.0
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'h3F800000;
        b        = 32'h3F800000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        @(posedge clk);

        #1;

        if (valid_out && (product == 32'h3F800000)) begin

            $display(
                "PASS: 1.0 * 1.0 = %h",
                product
            );

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: 1.0 * 1.0 | Got=%h | Expected=3F800000",
                product
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Summary
        //------------------------------------------------------

        $display("");
        $display("==========================================");
        $display("FP32 MULTIPLIER TEST SUMMARY");
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