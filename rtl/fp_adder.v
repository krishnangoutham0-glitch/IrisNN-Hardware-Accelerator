`timescale 1ns/1ps

//==============================================================
// Module Name : fp_adder
// Project     : FP32 Neural Network Accelerator
// Description : Pipelined FP32 Floating-Point Adder
//
// Pipeline:
//   Stage 1 : Input registers
//   Stage 2 : FP32 add + output register
//
// Reset:
//   Active-low synchronous reset
//
// Rounding:
//   Round-to-nearest-even
//
//==============================================================

module fp_adder (
    input              clk,
    input              rst_n,
    input              valid_in,

    input      [31:0]  a,
    input      [31:0]  b,

    output reg         valid_out,
    output reg [31:0]  sum
);

    //----------------------------------------------------------
    // Stage 1 registers
    //----------------------------------------------------------

    reg [31:0] a_reg;
    reg [31:0] b_reg;
    reg        valid_reg;

    //----------------------------------------------------------
    // FP32 fields
    //----------------------------------------------------------

    reg        sign_a;
    reg        sign_b;

    reg [7:0]  exp_a;
    reg [7:0]  exp_b;

    reg [22:0] frac_a;
    reg [22:0] frac_b;

    //----------------------------------------------------------
    // 24-bit significands
    // Hidden '1' is restored here
    //----------------------------------------------------------

    reg [23:0] mant_a;
    reg [23:0] mant_b;

    reg [23:0] mant_large;
    reg [23:0] mant_small;

    reg [7:0]  exp_large;
    reg [7:0]  exp_small;

    reg        sign_large;

    //----------------------------------------------------------
    // 27-bit values
    //
    // 24 mantissa bits + Guard + Round + Sticky
    //----------------------------------------------------------

    reg [26:0] aligned_large;
    reg [26:0] aligned_small;

    //----------------------------------------------------------
    // Addition/subtraction result
    //----------------------------------------------------------

    reg [27:0] mant_result;

    //----------------------------------------------------------
    // Normalization
    //----------------------------------------------------------

    reg [26:0] normalized;

    //----------------------------------------------------------
    // Final result fields
    //----------------------------------------------------------

    reg        result_sign;
    reg [7:0]  result_exp;

    reg [23:0] rounded_mant;

    reg        guard_bit;
    reg        round_bit;
    reg        sticky_bit;

    reg [31:0] result_comb;

    integer shift_amount;
    integer i;

    //----------------------------------------------------------
    // Right shift with sticky-bit generation
    //----------------------------------------------------------

    function [26:0] shift_right_sticky;

        input [26:0] value;
        input integer shift;

        reg [26:0] shifted;
        reg        sticky;

        integer j;

        begin

            shifted = 27'b0;
            sticky  = 1'b0;

            if (shift == 0) begin

                shifted = value;

            end

            else if (shift >= 27) begin

                shifted[0] = |value;

            end

            else begin

                shifted = value >> shift;

                for (j = 0; j < 27; j = j + 1) begin

                    if (j < shift)
                        sticky = sticky | value[j];

                end

                shifted[0] = shifted[0] | sticky;

            end

            shift_right_sticky = shifted;

        end

    endfunction

    //----------------------------------------------------------
    // Combinational FP32 datapath
    //----------------------------------------------------------

    always @(*) begin

        //------------------------------------------------------
        // Extract FP32 fields
        //------------------------------------------------------

        sign_a = a_reg[31];
        exp_a  = a_reg[30:23];
        frac_a = a_reg[22:0];

        sign_b = b_reg[31];
        exp_b  = b_reg[30:23];
        frac_b = b_reg[22:0];

        //------------------------------------------------------
        // Defaults
        //------------------------------------------------------

        mant_a = 24'b0;
        mant_b = 24'b0;

        mant_large = 24'b0;
        mant_small = 24'b0;

        exp_large = 8'b0;
        exp_small = 8'b0;

        sign_large = 1'b0;

        aligned_large = 27'b0;
        aligned_small = 27'b0;

        mant_result = 28'b0;

        normalized = 27'b0;

        result_sign = 1'b0;
        result_exp  = 8'b0;

        rounded_mant = 24'b0;

        guard_bit  = 1'b0;
        round_bit  = 1'b0;
        sticky_bit = 1'b0;

        result_comb = 32'b0;

        shift_amount = 0;

        //------------------------------------------------------
        // Zero handling
        //------------------------------------------------------

        if ((exp_a == 8'b0) && (frac_a == 23'b0)) begin

            result_comb = b_reg;

        end

        else if ((exp_b == 8'b0) && (frac_b == 23'b0)) begin

            result_comb = a_reg;

        end

        //------------------------------------------------------
        // Normal FP32 numbers
        //------------------------------------------------------

        else begin

            //--------------------------------------------------
            // Restore hidden 1
            //--------------------------------------------------

            mant_a = {1'b1, frac_a};
            mant_b = {1'b1, frac_b};

            //--------------------------------------------------
            // Find larger magnitude
            //--------------------------------------------------

            if (exp_a > exp_b) begin

                mant_large = mant_a;
                mant_small = mant_b;

                exp_large = exp_a;
                exp_small = exp_b;

                sign_large = sign_a;

            end

            else if (exp_b > exp_a) begin

                mant_large = mant_b;
                mant_small = mant_a;

                exp_large = exp_b;
                exp_small = exp_a;

                sign_large = sign_b;

            end

            else if (mant_a >= mant_b) begin

                mant_large = mant_a;
                mant_small = mant_b;

                exp_large = exp_a;
                exp_small = exp_b;

                sign_large = sign_a;

            end

            else begin

                mant_large = mant_b;
                mant_small = mant_a;

                exp_large = exp_b;
                exp_small = exp_a;

                sign_large = sign_b;

            end

            //--------------------------------------------------
            // Add GRS bits
            //--------------------------------------------------

            aligned_large = {mant_large, 3'b000};
            aligned_small = {mant_small, 3'b000};

            //--------------------------------------------------
            // Align smaller operand
            //--------------------------------------------------

            shift_amount = exp_large - exp_small;

            aligned_small =
                shift_right_sticky(
                    aligned_small,
                    shift_amount
                );

            //--------------------------------------------------
            // Same signs -> addition
            //--------------------------------------------------

            if (sign_a == sign_b) begin

                mant_result =
                    {1'b0, aligned_large} +
                    {1'b0, aligned_small};

                result_sign = sign_a;
                result_exp  = exp_large;

                //------------------------------------------------
                // Carry generated
                //------------------------------------------------

                if (mant_result[27]) begin

                    normalized = mant_result[27:1];

                    normalized[0] =
                        mant_result[1] |
                        mant_result[0];

                    result_exp =
                        exp_large + 1'b1;

                end

                else begin

                    normalized = mant_result[26:0];

                end

            end

            //--------------------------------------------------
            // Different signs -> subtraction
            //--------------------------------------------------

            else begin

                mant_result =
                    {1'b0, aligned_large} -
                    {1'b0, aligned_small};

                result_sign = sign_large;
                result_exp  = exp_large;

                //------------------------------------------------
                // Exact cancellation
                //------------------------------------------------

                if (mant_result == 28'b0) begin

                    normalized  = 27'b0;
                    result_exp  = 8'b0;
                    result_sign = 1'b0;

                end

                else begin

                    normalized = mant_result[26:0];

                    //------------------------------------------------
                    // Normalize left
                    //------------------------------------------------

                    for (i = 0; i < 27; i = i + 1) begin

                        if ((normalized[26] == 1'b0) &&
                            (result_exp > 0)) begin

                            normalized =
                                normalized << 1;

                            result_exp =
                                result_exp - 1'b1;

                        end

                    end

                end

            end

            //--------------------------------------------------
            // Exact zero
            //--------------------------------------------------

            if (normalized == 27'b0) begin

                result_comb = 32'b0;

            end

            else begin

                //------------------------------------------------
                // Extract GRS
                //------------------------------------------------

                guard_bit  = normalized[2];
                round_bit  = normalized[1];
                sticky_bit = normalized[0];

                //------------------------------------------------
                // Remove GRS bits
                //------------------------------------------------

                rounded_mant = normalized[26:3];

                //------------------------------------------------
                // Round-to-nearest-even
                //------------------------------------------------

                if (guard_bit &&
                    (round_bit ||
                     sticky_bit ||
                     rounded_mant[0])) begin

                    rounded_mant =
                        rounded_mant + 1'b1;

                end

                //------------------------------------------------
                // Rounding carry
                //------------------------------------------------

                if (rounded_mant[24]) begin

                    rounded_mant =
                        rounded_mant >> 1;

                    result_exp =
                        result_exp + 1'b1;

                end

                //------------------------------------------------
                // Exponent overflow
                //------------------------------------------------

                if (result_exp >= 8'hFF) begin

                    result_comb = {
                        result_sign,
                        8'hFF,
                        23'b0
                    };

                end

                //------------------------------------------------
                // Underflow
                //------------------------------------------------

                else if (result_exp == 8'b0) begin

                    result_comb = {
                        result_sign,
                        8'b0,
                        23'b0
                    };

                end

                //------------------------------------------------
                // Normal result
                //------------------------------------------------

                else begin

                    result_comb = {
                        result_sign,
                        result_exp,
                        rounded_mant[22:0]
                    };

                end

            end

        end

    end

    //----------------------------------------------------------
    // Stage 1 : Input registers
    //
    // Synchronous active-low reset
    //----------------------------------------------------------

    always @(posedge clk) begin

        if (!rst_n) begin

            a_reg     <= 32'b0;
            b_reg     <= 32'b0;
            valid_reg <= 1'b0;

        end

        else begin

            a_reg     <= a;
            b_reg     <= b;
            valid_reg <= valid_in;

        end

    end

    //----------------------------------------------------------
    // Stage 2 : Output registers
    //----------------------------------------------------------

    always @(posedge clk) begin

        if (!rst_n) begin

            sum       <= 32'b0;
            valid_out <= 1'b0;

        end

        else begin

            sum       <= result_comb;
            valid_out <= valid_reg;

        end

    end

endmodule