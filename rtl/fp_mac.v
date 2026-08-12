`timescale 1ns/1ps

//==============================================================
// Module Name : fp_mac
// Project     : Iris NN Hardware Accelerator
//
// Description:
//     FP32 Multiply-Accumulate style block
//
//     result = (a * b) + bias
//
// Pipeline:
//
//     a,b
//      |
//      v
//   FP32 Multiplier
//      |
//      | product
//      v
//   FP32 Adder <---- bias
//      |
//      v
//    result
//
// Latency:
//     Multiplier = 2 cycles
//     Adder      = 2 cycles
//
//     Total      = 4 cycles
//
//==============================================================

module fp_mac (

    input              clk,
    input              rst_n,

    input              valid_in,

    input      [31:0]  a,
    input      [31:0]  b,
    input      [31:0]  bias,

    output             valid_out,
    output     [31:0]  result

);

    //----------------------------------------------------------
    // Multiplier signals
    //----------------------------------------------------------

    wire        mul_valid;
    wire [31:0] product;

    //----------------------------------------------------------
    // Adder signals
    //----------------------------------------------------------

    wire        add_valid;
    wire [31:0] add_result;

    //----------------------------------------------------------
    // Bias pipeline
    //
    // The multiplier takes 2 cycles.
    // Therefore bias must be delayed by the same amount
    // before entering the adder.
    //----------------------------------------------------------

    reg [31:0] bias_reg1;
    reg [31:0] bias_reg2;

    //----------------------------------------------------------
    // FP32 MULTIPLIER
    //----------------------------------------------------------

    fp_multiplier u_multiplier (

        .clk       (clk),
        .rst_n     (rst_n),

        .valid_in  (valid_in),

        .a         (a),
        .b         (b),

        .valid_out (mul_valid),
        .product   (product)

    );

    //----------------------------------------------------------
    // Bias delay
    //----------------------------------------------------------

    always @(posedge clk) begin

        if (!rst_n) begin

            bias_reg1 <= 32'b0;
            bias_reg2 <= 32'b0;

        end

        else begin

            bias_reg1 <= bias;
            bias_reg2 <= bias_reg1;

        end

    end

    //----------------------------------------------------------
    // FP32 ADDER
    //
    // product + delayed bias
    //----------------------------------------------------------

    fp_adder u_adder (

        .clk       (clk),
        .rst_n     (rst_n),

        .valid_in  (mul_valid),

        .a         (product),
        .b         (bias_reg2),

        .valid_out (add_valid),
        .sum       (add_result)

    );

    //----------------------------------------------------------
    // Output
    //----------------------------------------------------------

    assign valid_out = add_valid;

    assign result = add_result;

endmodule