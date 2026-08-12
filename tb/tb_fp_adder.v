`timescale 1ns/1ps

module tb_fp_adder;

    reg        clk;
    reg        rst_n;
    reg        valid_in;

    reg [31:0] a;
    reg [31:0] b;

    wire        valid_out;
    wire [31:0] sum;

    integer pass_count;
    integer fail_count;

    //----------------------------------------------------------
    // DUT
    //----------------------------------------------------------

    fp_adder dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .a         (a),
        .b         (b),
        .valid_out (valid_out),
        .sum       (sum)
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
            "TIME=%0t | rst_n=%b | valid_in=%b | valid_reg=%b | valid_out=%b | a_reg=%h | b_reg=%h | sum=%h",
            $time,
            rst_n,
            valid_in,
            dut.valid_reg,
            valid_out,
            dut.a_reg,
            dut.b_reg,
            sum
        );

    end

    //----------------------------------------------------------
    // Main test
    //----------------------------------------------------------

    initial begin

        //------------------------------------------------------
        // Initial state
        //------------------------------------------------------

        rst_n    = 1'b0;
        valid_in = 1'b0;

        a = 32'b0;
        b = 32'b0;

        pass_count = 0;
        fail_count = 0;

        //------------------------------------------------------
        // Hold reset for two clock cycles
        //------------------------------------------------------

        repeat (2)
            @(posedge clk);

        //------------------------------------------------------
        // Release reset
        //------------------------------------------------------

        rst_n = 1'b1;

        //------------------------------------------------------
        // Test 1
        // 5.1 + 3.5 = 8.6
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'h40A33333;
        b        = 32'h40600000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        //------------------------------------------------------
        // Output appears after pipeline
        //------------------------------------------------------

        @(posedge clk);

        #1;

        if (valid_out && (sum == 32'h4109999A)) begin

            $display("PASS: 5.1 + 3.5 = %h", sum);

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: 5.1 + 3.5 | Got=%h | Expected=4109999A",
                sum
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Test 2
        // FP32(5.1) + FP32(-3.5)
        // = 3FCCCCCC
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'h40A33333;
        b        = 32'hC0600000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        @(posedge clk);

        #1;

        if (valid_out && (sum == 32'h3FCCCCCC)) begin

            $display("PASS: 5.1 + (-3.5) = %h", sum);

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: 5.1 + (-3.5) | Got=%h | Expected=3FCCCCCC",
                sum
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Test 3
        // 1.0 + 2.0 = 3.0
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'h3F800000;
        b        = 32'h40000000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        @(posedge clk);

        #1;

        if (valid_out && (sum == 32'h40400000)) begin

            $display("PASS: 1.0 + 2.0 = %h", sum);

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: 1.0 + 2.0 | Got=%h | Expected=40400000",
                sum
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Test 4
        // 1.5 + 1.5 = 3.0
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'h3FC00000;
        b        = 32'h3FC00000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        @(posedge clk);

        #1;

        if (valid_out && (sum == 32'h40400000)) begin

            $display("PASS: 1.5 + 1.5 = %h", sum);

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: 1.5 + 1.5 | Got=%h | Expected=40400000",
                sum
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Test 5
        // 10.0 + (-5.0) = 5.0
        //------------------------------------------------------

        @(negedge clk);

        a        = 32'h41200000;
        b        = 32'hC0A00000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        @(posedge clk);

        #1;

        if (valid_out && (sum == 32'h40A00000)) begin

            $display("PASS: 10.0 + (-5.0) = %h", sum);

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: 10.0 + (-5.0) | Got=%h | Expected=40A00000",
                sum
            );

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Summary
        //------------------------------------------------------

        $display("");
        $display("==========================================");
        $display("FP32 ADDER TEST SUMMARY");
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