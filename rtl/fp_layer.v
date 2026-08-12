`timescale 1ns/1ps

//==============================================================
// FP32 Neural Network Layer
//
// 4 inputs
// 4 parallel neurons
//
// Each neuron:
//
// ReLU(x0*w0 + x1*w1 + x2*w2 + x3*w3 + bias)
//
// Verilog-2001 compatible
//==============================================================

module fp_layer (

    input        clk,
    input        rst_n,
    input        valid_in,

    // Input features
    input [31:0] x0,
    input [31:0] x1,
    input [31:0] x2,
    input [31:0] x3,

    // ---------------------------------------------------------
    // Neuron 0 weights and bias
    // ---------------------------------------------------------

    input [31:0] w00,
    input [31:0] w01,
    input [31:0] w02,
    input [31:0] w03,
    input [31:0] bias0,

    // ---------------------------------------------------------
    // Neuron 1 weights and bias
    // ---------------------------------------------------------

    input [31:0] w10,
    input [31:0] w11,
    input [31:0] w12,
    input [31:0] w13,
    input [31:0] bias1,

    // ---------------------------------------------------------
    // Neuron 2 weights and bias
    // ---------------------------------------------------------

    input [31:0] w20,
    input [31:0] w21,
    input [31:0] w22,
    input [31:0] w23,
    input [31:0] bias2,

    // ---------------------------------------------------------
    // Neuron 3 weights and bias
    // ---------------------------------------------------------

    input [31:0] w30,
    input [31:0] w31,
    input [31:0] w32,
    input [31:0] w33,
    input [31:0] bias3,

    // Outputs
    output       valid_out,

    output [31:0] y0,
    output [31:0] y1,
    output [31:0] y2,
    output [31:0] y3

);

    //----------------------------------------------------------
    // Individual neuron valid signals
    //----------------------------------------------------------

    wire valid0;
    wire valid1;
    wire valid2;
    wire valid3;

    //----------------------------------------------------------
    // Neuron 0
    //----------------------------------------------------------

    fp_neuron neuron0 (

        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_in),

        .x0         (x0),
        .x1         (x1),
        .x2         (x2),
        .x3         (x3),

        .w0         (w00),
        .w1         (w01),
        .w2         (w02),
        .w3         (w03),

        .bias       (bias0),

        .valid_out  (valid0),
        .neuron_out (y0)

    );

    //----------------------------------------------------------
    // Neuron 1
    //----------------------------------------------------------

    fp_neuron neuron1 (

        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_in),

        .x0         (x0),
        .x1         (x1),
        .x2         (x2),
        .x3         (x3),

        .w0         (w10),
        .w1         (w11),
        .w2         (w12),
        .w3         (w13),

        .bias       (bias1),

        .valid_out  (valid1),
        .neuron_out (y1)

    );

    //----------------------------------------------------------
    // Neuron 2
    //----------------------------------------------------------

    fp_neuron neuron2 (

        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_in),

        .x0         (x0),
        .x1         (x1),
        .x2         (x2),
        .x3         (x3),

        .w0         (w20),
        .w1         (w21),
        .w2         (w22),
        .w3         (w23),

        .bias       (bias2),

        .valid_out  (valid2),
        .neuron_out (y2)

    );

    //----------------------------------------------------------
    // Neuron 3
    //----------------------------------------------------------

    fp_neuron neuron3 (

        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_in),

        .x0         (x0),
        .x1         (x1),
        .x2         (x2),
        .x3         (x3),

        .w0         (w30),
        .w1         (w31),
        .w2         (w32),
        .w3         (w33),

        .bias       (bias3),

        .valid_out  (valid3),
        .neuron_out (y3)

    );

    //----------------------------------------------------------
    // All neurons have the same latency
    //----------------------------------------------------------

    assign valid_out = valid0;

endmodule