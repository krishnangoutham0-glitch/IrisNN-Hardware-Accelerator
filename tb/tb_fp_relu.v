`timescale 1ns/1ps

module tb_fp_relu;

    reg        clk;
    reg        rst_n;
    reg        valid_in;

    reg [31:0] data_in;

    wire        valid_out;
    wire [31:0] data_out;

    integer pass_count;
    integer fail_count;

    //----------------------------------------------------------
    // DUT
    //----------------------------------------------------------

    fp_relu dut (

        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),

        .data_in   (data_in),

        .valid_out (valid_out),
        .data_out  (data_out)

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
            "TIME=%0t | valid_in=%b | data_in=%h | valid_out=%b | data_out=%h",
            $time,
            valid_in,
            data_in,
            valid_out,
            data_out
        );

    end

    //----------------------------------------------------------
    // Main
    //----------------------------------------------------------

    initial begin

        rst_n    = 1'b0;
        valid_in = 1'b0;
        data_in  = 32'b0;

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
        // +5.0 -> +5.0
        //------------------------------------------------------

        @(negedge clk);

        data_in  = 32'h40A00000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        if (valid_out && data_out == 32'h40A00000) begin

            $display("PASS: ReLU(+5.0) = +5.0");

            pass_count = pass_count + 1;

        end

        else begin

            $display("FAIL: ReLU(+5.0)");

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Test 2
        // -5.0 -> 0
        //------------------------------------------------------

        @(negedge clk);

        data_in  = 32'hC0A00000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        if (valid_out && data_out == 32'h00000000) begin

            $display("PASS: ReLU(-5.0) = 0");

            pass_count = pass_count + 1;

        end

        else begin

            $display("FAIL: ReLU(-5.0)");

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Test 3
        // 0 -> 0
        //------------------------------------------------------

        @(negedge clk);

        data_in  = 32'h00000000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        if (valid_out && data_out == 32'h00000000) begin

            $display("PASS: ReLU(0.0) = 0");

            pass_count = pass_count + 1;

        end

        else begin

            $display("FAIL: ReLU(0.0)");

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Test 4
        // +0.5 -> +0.5
        //------------------------------------------------------

        @(negedge clk);

        data_in  = 32'h3F000000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        if (valid_out && data_out == 32'h3F000000) begin

            $display("PASS: ReLU(+0.5) = +0.5");

            pass_count = pass_count + 1;

        end

        else begin

            $display("FAIL: ReLU(+0.5)");

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Test 5
        // -0.5 -> 0
        //------------------------------------------------------

        @(negedge clk);

        data_in  = 32'hBF000000;
        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        if (valid_out && data_out == 32'h00000000) begin

            $display("PASS: ReLU(-0.5) = 0");

            pass_count = pass_count + 1;

        end

        else begin

            $display("FAIL: ReLU(-0.5)");

            fail_count = fail_count + 1;

        end

        //------------------------------------------------------
        // Summary
        //------------------------------------------------------

        $display("");
        $display("======================================");
        $display("FP32 RELU TEST SUMMARY");
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