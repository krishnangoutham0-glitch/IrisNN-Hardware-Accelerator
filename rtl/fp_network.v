`timescale 1ns/1ps

//==============================================================
// FP32 Iris Neural Network
//
// Architecture:
//
//              4 inputs
//                 |
//                 v
//        +-------------------+
//        | Hidden Layer      |
//        | 4 neurons         |
//        | MAC + ReLU        |
//        +---------+---------+
//                  |
//              4 hidden values
//                  |
//                  v
//        +-------------------+
//        | Output Layer      |
//        | 3 neurons         |
//        | MAC only          |
//        +---------+---------+
//                  |
//                y0 y1 y2
//                  |
//                  v
//              FP Argmax
//                  |
//                  v
//             class[1:0]
//
//==============================================================

module fp_network (

    input        clk,
    input        rst_n,
    input        valid_in,

    //----------------------------------------------------------
    // Input features
    //----------------------------------------------------------

    input [31:0] x0,
    input [31:0] x1,
    input [31:0] x2,
    input [31:0] x3,

    //----------------------------------------------------------
    // Hidden layer weights
    //----------------------------------------------------------

    input [31:0] hw00,
    input [31:0] hw01,
    input [31:0] hw02,
    input [31:0] hw03,
    input [31:0] hb0,

    input [31:0] hw10,
    input [31:0] hw11,
    input [31:0] hw12,
    input [31:0] hw13,
    input [31:0] hb1,

    input [31:0] hw20,
    input [31:0] hw21,
    input [31:0] hw22,
    input [31:0] hw23,
    input [31:0] hb2,

    input [31:0] hw30,
    input [31:0] hw31,
    input [31:0] hw32,
    input [31:0] hw33,
    input [31:0] hb3,

    //----------------------------------------------------------
    // Output layer weights
    //----------------------------------------------------------

    input [31:0] ow00,
    input [31:0] ow01,
    input [31:0] ow02,
    input [31:0] ow03,
    input [31:0] ob0,

    input [31:0] ow10,
    input [31:0] ow11,
    input [31:0] ow12,
    input [31:0] ow13,
    input [31:0] ob1,

    input [31:0] ow20,
    input [31:0] ow21,
    input [31:0] ow22,
    input [31:0] ow23,
    input [31:0] ob2,

    //----------------------------------------------------------
    // Network output
    //----------------------------------------------------------

    output        valid_out,
    output [1:0]  class_out,

    //----------------------------------------------------------
    // Optional: expose output logits
    //----------------------------------------------------------

    output [31:0] y0,
    output [31:0] y1,
    output [31:0] y2

);

    //==========================================================
    // HIDDEN LAYER
    //==========================================================

    wire        hidden_valid;

    wire [31:0] h0;
    wire [31:0] h1;
    wire [31:0] h2;
    wire [31:0] h3;

    fp_layer hidden_layer (

        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),

        .x0        (x0),
        .x1        (x1),
        .x2        (x2),
        .x3        (x3),

        .w00       (hw00),
        .w01       (hw01),
        .w02       (hw02),
        .w03       (hw03),
        .bias0     (hb0),

        .w10       (hw10),
        .w11       (hw11),
        .w12       (hw12),
        .w13       (hw13),
        .bias1     (hb1),

        .w20       (hw20),
        .w21       (hw21),
        .w22       (hw22),
        .w23       (hw23),
        .bias2     (hb2),

        .w30       (hw30),
        .w31       (hw31),
        .w32       (hw32),
        .w33       (hw33),
        .bias3     (hb3),

        .valid_out (hidden_valid),

        .y0        (h0),
        .y1        (h1),
        .y2        (h2),
        .y3        (h3)

    );

    //==========================================================
    // OUTPUT LAYER
    //
    // y0 = h0*ow00 + h1*ow01 + h2*ow02 + h3*ow03 + ob0
    //
    // y1 = h0*ow10 + h1*ow11 + h2*ow12 + h3*ow13 + ob1
    //
    // y2 = h0*ow20 + h1*ow21 + h2*ow22 + h3*ow23 + ob2
    //
    // NO ReLU HERE
    //==========================================================

    //----------------------------------------------------------
    // Output neuron 0 multipliers
    //----------------------------------------------------------

    wire        y0_mul_valid0;
    wire        y0_mul_valid1;
    wire        y0_mul_valid2;
    wire        y0_mul_valid3;

    wire [31:0] y0_p0;
    wire [31:0] y0_p1;
    wire [31:0] y0_p2;
    wire [31:0] y0_p3;

    fp_multiplier y0_mul0 (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (hidden_valid),
        .a         (h0),
        .b         (ow00),
        .valid_out (y0_mul_valid0),
        .product   (y0_p0)
    );

    fp_multiplier y0_mul1 (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (hidden_valid),
        .a         (h1),
        .b         (ow01),
        .valid_out (y0_mul_valid1),
        .product   (y0_p1)
    );

    fp_multiplier y0_mul2 (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (hidden_valid),
        .a         (h2),
        .b         (ow02),
        .valid_out (y0_mul_valid2),
        .product   (y0_p2)
    );

    fp_multiplier y0_mul3 (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (hidden_valid),
        .a         (h3),
        .b         (ow03),
        .valid_out (y0_mul_valid3),
        .product   (y0_p3)
    );

    wire [31:0] y0_s01;
    wire [31:0] y0_s23;
    wire [31:0] y0_sum;
    wire [31:0] y0_bias_sum;

    wire y0_v01;
    wire y0_v23;
    wire y0_vsum;
    wire y0_vbias;

    fp_adder y0_add01 (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (y0_mul_valid0),
        .a         (y0_p0),
        .b         (y0_p1),
        .valid_out (y0_v01),
        .sum       (y0_s01)
    );

    fp_adder y0_add23 (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (y0_mul_valid2),
        .a         (y0_p2),
        .b         (y0_p3),
        .valid_out (y0_v23),
        .sum       (y0_s23)
    );

    fp_adder y0_add_all (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (y0_v01),
        .a         (y0_s01),
        .b         (y0_s23),
        .valid_out (y0_vsum),
        .sum       (y0_sum)
    );

    // Bias delay
    reg [31:0] ob0_d1;
    reg [31:0] ob0_d2;
    reg [31:0] ob0_d3;

    always @(posedge clk) begin
        if (!rst_n) begin
            ob0_d1 <= 32'b0;
            ob0_d2 <= 32'b0;
            ob0_d3 <= 32'b0;
        end
        else begin
            ob0_d1 <= ob0;
            ob0_d2 <= ob0_d1;
            ob0_d3 <= ob0_d2;
        end
    end

    fp_adder y0_add_bias (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (y0_vsum),
        .a         (y0_sum),
        .b         (ob0_d3),
        .valid_out (y0_vbias),
        .sum       (y0_bias_sum)
    );

    assign y0 = y0_bias_sum;


    //==========================================================
    // OUTPUT NEURON 1
    //==========================================================

    wire [31:0] y1_p0;
    wire [31:0] y1_p1;
    wire [31:0] y1_p2;
    wire [31:0] y1_p3;

    wire y1_mv0;
    wire y1_mv1;
    wire y1_mv2;
    wire y1_mv3;

    fp_multiplier y1_mul0 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(hidden_valid),
        .a(h0), .b(ow10),
        .valid_out(y1_mv0), .product(y1_p0)
    );

    fp_multiplier y1_mul1 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(hidden_valid),
        .a(h1), .b(ow11),
        .valid_out(y1_mv1), .product(y1_p1)
    );

    fp_multiplier y1_mul2 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(hidden_valid),
        .a(h2), .b(ow12),
        .valid_out(y1_mv2), .product(y1_p2)
    );

    fp_multiplier y1_mul3 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(hidden_valid),
        .a(h3), .b(ow13),
        .valid_out(y1_mv3), .product(y1_p3)
    );

    wire [31:0] y1_s01;
    wire [31:0] y1_s23;
    wire [31:0] y1_sum;
    wire [31:0] y1_bias_sum;

    wire y1_v01;
    wire y1_v23;
    wire y1_vsum;
    wire y1_vbias;

    fp_adder y1_add01 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(y1_mv0),
        .a(y1_p0), .b(y1_p1),
        .valid_out(y1_v01),
        .sum(y1_s01)
    );

    fp_adder y1_add23 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(y1_mv2),
        .a(y1_p2), .b(y1_p3),
        .valid_out(y1_v23),
        .sum(y1_s23)
    );

    fp_adder y1_add_all (
        .clk(clk), .rst_n(rst_n),
        .valid_in(y1_v01),
        .a(y1_s01), .b(y1_s23),
        .valid_out(y1_vsum),
        .sum(y1_sum)
    );

    reg [31:0] ob1_d1;
    reg [31:0] ob1_d2;
    reg [31:0] ob1_d3;

    always @(posedge clk) begin
        if (!rst_n) begin
            ob1_d1 <= 32'b0;
            ob1_d2 <= 32'b0;
            ob1_d3 <= 32'b0;
        end
        else begin
            ob1_d1 <= ob1;
            ob1_d2 <= ob1_d1;
            ob1_d3 <= ob1_d2;
        end
    end

    fp_adder y1_add_bias (
        .clk(clk), .rst_n(rst_n),
        .valid_in(y1_vsum),
        .a(y1_sum), .b(ob1_d3),
        .valid_out(y1_vbias),
        .sum(y1_bias_sum)
    );

    assign y1 = y1_bias_sum;


    //==========================================================
    // OUTPUT NEURON 2
    //==========================================================

    wire [31:0] y2_p0;
    wire [31:0] y2_p1;
    wire [31:0] y2_p2;
    wire [31:0] y2_p3;

    wire y2_mv0;
    wire y2_mv1;
    wire y2_mv2;
    wire y2_mv3;

    fp_multiplier y2_mul0 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(hidden_valid),
        .a(h0), .b(ow20),
        .valid_out(y2_mv0), .product(y2_p0)
    );

    fp_multiplier y2_mul1 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(hidden_valid),
        .a(h1), .b(ow21),
        .valid_out(y2_mv1), .product(y2_p1)
    );

    fp_multiplier y2_mul2 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(hidden_valid),
        .a(h2), .b(ow22),
        .valid_out(y2_mv2), .product(y2_p2)
    );

    fp_multiplier y2_mul3 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(hidden_valid),
        .a(h3), .b(ow23),
        .valid_out(y2_mv3), .product(y2_p3)
    );

    wire [31:0] y2_s01;
    wire [31:0] y2_s23;
    wire [31:0] y2_sum;
    wire [31:0] y2_bias_sum;

    wire y2_v01;
    wire y2_v23;
    wire y2_vsum;
    wire y2_vbias;

    fp_adder y2_add01 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(y2_mv0),
        .a(y2_p0), .b(y2_p1),
        .valid_out(y2_v01),
        .sum(y2_s01)
    );

    fp_adder y2_add23 (
        .clk(clk), .rst_n(rst_n),
        .valid_in(y2_mv2),
        .a(y2_p2), .b(y2_p3),
        .valid_out(y2_v23),
        .sum(y2_s23)
    );

    fp_adder y2_add_all (
        .clk(clk), .rst_n(rst_n),
        .valid_in(y2_v01),
        .a(y2_s01), .b(y2_s23),
        .valid_out(y2_vsum),
        .sum(y2_sum)
    );

    reg [31:0] ob2_d1;
    reg [31:0] ob2_d2;
    reg [31:0] ob2_d3;

    always @(posedge clk) begin
        if (!rst_n) begin
            ob2_d1 <= 32'b0;
            ob2_d2 <= 32'b0;
            ob2_d3 <= 32'b0;
        end
        else begin
            ob2_d1 <= ob2;
            ob2_d2 <= ob2_d1;
            ob2_d3 <= ob2_d2;
        end
    end

    fp_adder y2_add_bias (
        .clk(clk), .rst_n(rst_n),
        .valid_in(y2_vsum),
        .a(y2_sum), .b(ob2_d3),
        .valid_out(y2_vbias),
        .sum(y2_bias_sum)
    );

    assign y2 = y2_bias_sum;


    //==========================================================
    // ARGMAX
    //==========================================================

    // All three output neurons have identical latency.
    // y0_vbias, y1_vbias and y2_vbias occur together.

    wire argmax_valid;

    fp_argmax classifier (

        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (y0_vbias),

        .x0        (y0),
        .x1        (y1),
        .x2        (y2),

        .valid_out (argmax_valid),
        .index     (class_out)

    );

    assign valid_out = argmax_valid;

endmodule