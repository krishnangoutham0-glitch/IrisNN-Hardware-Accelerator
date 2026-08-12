`timescale 1ns/1ps

//==============================================================
// Module : neuron
//
// 4-input FP32 neural-network neuron
//
//      y = ReLU(x0*w0 + x1*w1 + x2*w2 + x3*w3 + bias)
//
// Architecture:
//
//      x0*w0 ──┐
//              ├── ADD ──┐
//      x1*w1 ──┘         │
//                        ├── ADD ──┐
//      x2*w2 ──┐         │        │
//              ├── ADD ──┘        ├── ADD bias ── ReLU
//      x3*w3 ──┘                  │
//                                 │
//==============================================================

module fp_neuron (

    input              clk,
    input              rst_n,
    input              valid_in,

    // Inputs
    input      [31:0]  x0,
    input      [31:0]  x1,
    input      [31:0]  x2,
    input      [31:0]  x3,

    // Weights
    input      [31:0]  w0,
    input      [31:0]  w1,
    input      [31:0]  w2,
    input      [31:0]  w3,

    // Bias
    input      [31:0]  bias,

    // Output
    output             valid_out,
    output     [31:0]  neuron_out
);

    //----------------------------------------------------------
    // Multiplier outputs
    //----------------------------------------------------------

    wire        mul_valid0;
    wire        mul_valid1;
    wire        mul_valid2;
    wire        mul_valid3;

    wire [31:0] product0;
    wire [31:0] product1;
    wire [31:0] product2;
    wire [31:0] product3;


    //----------------------------------------------------------
    // First adder tree
    //----------------------------------------------------------

    wire        add_valid01;
    wire        add_valid23;

    wire [31:0] sum01;
    wire [31:0] sum23;


    //----------------------------------------------------------
    // Second adder
    //----------------------------------------------------------

    wire        add_valid_all;
    wire [31:0] sum_all;


    //----------------------------------------------------------
    // Bias adder
    //----------------------------------------------------------

    wire        add_valid_bias;
    wire [31:0] sum_bias;


    //----------------------------------------------------------
    // ReLU
    //----------------------------------------------------------

    wire        relu_valid;
    wire [31:0] relu_output;


    //----------------------------------------------------------
    // Bias pipeline
    //
    // Product reaches the first adder after the multiplier.
    // Then:
    //
    //   first adder
    //       ↓
    //   second adder
    //       ↓
    //   bias adder
    //
    // Bias is delayed so that it arrives together with sum_all.
    //----------------------------------------------------------

    reg [31:0] bias_d1;
    reg [31:0] bias_d2;
    reg [31:0] bias_d3;

    always @(posedge clk) begin

        if (!rst_n) begin

            bias_d1 <= 32'b0;
            bias_d2 <= 32'b0;
            bias_d3 <= 32'b0;

        end

        else begin

            bias_d1 <= bias;
            bias_d2 <= bias_d1;
            bias_d3 <= bias_d2;

        end

    end


    //----------------------------------------------------------
    // Four parallel FP32 multipliers
    //----------------------------------------------------------

    fp_multiplier u_mul0 (

        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),

        .a         (x0),
        .b         (w0),

        .valid_out (mul_valid0),
        .product   (product0)
    );


    fp_multiplier u_mul1 (

        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),

        .a         (x1),
        .b         (w1),

        .valid_out (mul_valid1),
        .product   (product1)
    );


    fp_multiplier u_mul2 (

        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),

        .a         (x2),
        .b         (w2),

        .valid_out (mul_valid2),
        .product   (product2)
    );


    fp_multiplier u_mul3 (

        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),

        .a         (x3),
        .b         (w3),

        .valid_out (mul_valid3),
        .product   (product3)
    );


    //----------------------------------------------------------
    // First level of adder tree
    //
    // product0 + product1
    // product2 + product3
    //----------------------------------------------------------

    fp_adder u_add01 (

        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (mul_valid0),

        .a         (product0),
        .b         (product1),

        .valid_out (add_valid01),
        .sum       (sum01)
    );


    fp_adder u_add23 (

        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (mul_valid2),

        .a         (product2),
        .b         (product3),

        .valid_out (add_valid23),
        .sum       (sum23)
    );


    //----------------------------------------------------------
    // Second level
    //
    // (product0 + product1)
    // +
    // (product2 + product3)
    //----------------------------------------------------------

    fp_adder u_add_all (

        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (add_valid01),

        .a         (sum01),
        .b         (sum23),

        .valid_out (add_valid_all),
        .sum       (sum_all)
    );


    //----------------------------------------------------------
    // Add bias
    //----------------------------------------------------------

    fp_adder u_add_bias (

        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (add_valid_all),

        .a         (sum_all),
        .b         (bias_d3),

        .valid_out (add_valid_bias),
        .sum       (sum_bias)
    );


    //----------------------------------------------------------
    // ReLU
    //----------------------------------------------------------

    fp_relu u_relu (

        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (add_valid_bias),

        .data_in   (sum_bias),

        .valid_out (relu_valid),
        .data_out  (relu_output)
    );


    //----------------------------------------------------------
    // Output
    //----------------------------------------------------------

    assign neuron_out = relu_output;

    assign valid_out = relu_valid;

endmodule