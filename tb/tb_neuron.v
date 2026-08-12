`timescale 1ns/1ps

module tb_neuron;

    reg        clk;
    reg        rst_n;
    reg        valid_in;

    reg [31:0] x0;
    reg [31:0] x1;
    reg [31:0] x2;
    reg [31:0] x3;

    reg [31:0] w0;
    reg [31:0] w1;
    reg [31:0] w2;
    reg [31:0] w3;

    reg [31:0] bias;

    wire        valid_out;
    wire [31:0] neuron_out;

    integer pass_count;
    integer fail_count;

    //----------------------------------------------------------
    // DUT
    //----------------------------------------------------------

    neuron dut (

        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_in),

        .x0         (x0),
        .x1         (x1),
        .x2         (x2),
        .x3         (x3),

        .w0         (w0),
        .w1         (w1),
        .w2         (w2),
        .w3         (w3),

        .bias       (bias),

        .valid_out  (valid_out),
        .neuron_out (neuron_out)
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
            "TIME=%0t | valid_in=%b | valid_out=%b | neuron_out=%h",
            $time,
            valid_in,
            valid_out,
            neuron_out
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
        x3 = 32'b0;

        w0 = 32'b0;
        w1 = 32'b0;
        w2 = 32'b0;
        w3 = 32'b0;

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
        // 2*1 + 3*1 + 4*1 + 5*1 - 5
        //
        // = 9
        //
        // ReLU(9) = 9
        //------------------------------------------------------

        @(negedge clk);

        x0 = 32'h40000000;   // 2
        x1 = 32'h40400000;   // 3
        x2 = 32'h40800000;   // 4
        x3 = 32'h40A00000;   // 5

        w0 = 32'h3F800000;   // 1
        w1 = 32'h3F800000;   // 1
        w2 = 32'h3F800000;   // 1
        w3 = 32'h3F800000;   // 1

        bias = 32'hC0A00000; // -5

        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;


        //------------------------------------------------------
        // Wait for result
        //------------------------------------------------------

        wait (valid_out == 1'b1);

        #1;

        if (neuron_out == 32'h41100000) begin

            $display("PASS: 2+3+4+5-5 = 9");

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: Expected 41100000, Got %h",
                neuron_out
            );

            fail_count = fail_count + 1;

        end


        //------------------------------------------------------
        // TEST 2
        //
        // 2+3+4+5-20 = -6
        //
        // ReLU(-6) = 0
        //------------------------------------------------------

        @(negedge clk);

        x0 = 32'h40000000;
        x1 = 32'h40400000;
        x2 = 32'h40800000;
        x3 = 32'h40A00000;

        w0 = 32'h3F800000;
        w1 = 32'h3F800000;
        w2 = 32'h3F800000;
        w3 = 32'h3F800000;

        bias = 32'hC1A00000; // -20

        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        wait (valid_out == 1'b1);

        #1;

        if (neuron_out == 32'h00000000) begin

            $display("PASS: 2+3+4+5-20 = -6 -> ReLU = 0");

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: Expected 00000000, Got %h",
                neuron_out
            );

            fail_count = fail_count + 1;

        end


        //------------------------------------------------------
        // TEST 3
        //
        // 2*2 + 3*2 + 4*2 + 5*2 - 5
        //
        // = 23
        //------------------------------------------------------

        @(negedge clk);

        x0 = 32'h40000000;
        x1 = 32'h40400000;
        x2 = 32'h40800000;
        x3 = 32'h40A00000;

        w0 = 32'h40000000;   // 2
        w1 = 32'h40000000;   // 2
        w2 = 32'h40000000;   // 2
        w3 = 32'h40000000;   // 2

        bias = 32'hC0A00000; // -5

        valid_in = 1'b1;

        @(posedge clk);

        #1;

        valid_in = 1'b0;

        wait (valid_out == 1'b1);

        #1;

        if (neuron_out == 32'h41B80000) begin

            $display("PASS: weighted neuron = 23");

            pass_count = pass_count + 1;

        end

        else begin

            $display(
                "FAIL: Expected 41B80000, Got %h",
                neuron_out
            );

            fail_count = fail_count + 1;

        end


        //------------------------------------------------------
        // Summary
        //------------------------------------------------------

        $display("");
        $display("==========================================");
        $display("FP32 NEURON TEST SUMMARY");
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