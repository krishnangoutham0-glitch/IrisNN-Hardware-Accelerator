`timescale 1ns/1ps

//==============================================================
// FP32 Floating Point Adder
//
// Optimized version
//
// Architecture:
//
//       a ──► Input Register ──┐
//                              │
//                              ▼
//                         FP32 ADDER
//                              │
//       b ──► Input Register ──┘
//                              │
//                              ▼
//                        Output Register
//
// Supported:
//   - FP32 normal numbers
//   - Zero
//   - Same-sign addition
//   - Different-sign subtraction
//   - Guard / Round / Sticky
//   - Round-to-nearest-even
//   - Overflow -> Infinity
//   - Underflow -> Zero
//
// Optimization:
//   Original subtraction normalization used a 27-iteration
//   shift-left loop.
//
//   This version uses:
//
//       Leading Zero Detector
//              +
//       Variable Left Shift
//
//   to reduce combinational logic depth.
//==============================================================

module fp_adder (

    input        clk,
    input        rst_n,
    input        valid_in,

    input  [31:0] a,
    input  [31:0] b,

    output       valid_out,
    output [31:0] sum

);

    //==========================================================
    // Input registers
    //==========================================================

    reg [31:0] a_reg;
    reg [31:0] b_reg;
    reg        valid_reg;


    //==========================================================
    // Output registers
    //==========================================================

    reg [31:0] sum_reg;
    reg        valid_out_reg;


    //==========================================================
    // FP32 fields
    //==========================================================

    reg        sign_a;
    reg        sign_b;

    reg [7:0]  exp_a;
    reg [7:0]  exp_b;

    reg [22:0] frac_a;
    reg [22:0] frac_b;


    //==========================================================
    // Mantissas
    //==========================================================

    reg [23:0] mant_a;
    reg [23:0] mant_b;

    reg [23:0] mant_large;
    reg [23:0] mant_small;


    //==========================================================
    // Exponents
    //==========================================================

    reg [7:0] exp_large;
    reg [7:0] exp_small;

    reg [7:0] result_exp;


    //==========================================================
    // Sign
    //==========================================================

    reg sign_large;
    reg result_sign;


    //==========================================================
    // Aligned mantissas
    //
    // 24-bit mantissa + GRS bits
    //
    // [26:3] = mantissa
    // [2]    = guard
    // [1]    = round
    // [0]    = sticky
    //==========================================================

    reg [26:0] aligned_large;
    reg [26:0] aligned_small;


    //==========================================================
    // Addition/subtraction result
    //==========================================================

    reg [27:0] mant_result;


    //==========================================================
    // Normalized result
    //==========================================================

    reg [26:0] normalized;


    //==========================================================
    // Rounding
    //==========================================================

    reg [23:0] rounded_mant;

    reg guard_bit;
    reg round_bit;
    reg sticky_bit;


    //==========================================================
    // Final combinational result
    //==========================================================

    reg [31:0] result_comb;


    //==========================================================
    // Shift amount
    //==========================================================

    integer shift_amount;


    //==========================================================
    // Leading-zero count
    //
    // Returns the number of leading zeros in a 27-bit value.
    //
    // Example:
    //
    // 1xxxxxxxxxxxxxxxxxxxxxxxxxx -> 0
    // 01xxxxxxxxxxxxxxxxxxxxxxxxx -> 1
    // 001xxxxxxxxxxxxxxxxxxxxxxxx -> 2
    //
    // Maximum = 26
    //==========================================================

    function integer leading_zero_count;

        input [26:0] value;

        integer k;
        reg found;

        begin

            leading_zero_count = 27;
            found = 1'b0;

            for (k = 26; k >= 0; k = k - 1) begin

                if (!found && value[k]) begin

                    leading_zero_count = 26 - k;
                    found = 1'b1;

                end

            end

        end

    endfunction


    //==========================================================
    // Right shift with sticky generation
    //
    // Used during exponent alignment.
    //
    // Example:
    //
    // aligned_small >> shift
    //
    // Any discarded 1 bits are accumulated into bit [0].
    //==========================================================

    function [26:0] shift_right_sticky;

        input [26:0] value;
        input integer shift;

        reg [26:0] shifted;
        reg sticky;

        integer j;

        begin

            shifted = 27'b0;
            sticky  = 1'b0;

            if (shift == 0) begin

                shift_right_sticky = value;

            end

            else if (shift >= 27) begin

                sticky = 1'b0;

                for (j = 0; j < 27; j = j + 1) begin
                    sticky = sticky | value[j];
                end

                shifted = 27'b0;
                shifted[0] = sticky;

                shift_right_sticky = shifted;

            end

            else begin

                shifted = value >> shift;

                sticky = 1'b0;

                for (j = 0; j < 27; j = j + 1) begin

                    if (j < shift)
                        sticky = sticky | value[j];

                end

                shifted[0] = shifted[0] | sticky;

                shift_right_sticky = shifted;

            end

        end

    endfunction


    //==========================================================
    // Combinational FP32 datapath
    //==========================================================

    always @(*) begin

        //======================================================
        // Extract FP32 fields
        //======================================================

        sign_a = a_reg[31];
        exp_a  = a_reg[30:23];
        frac_a = a_reg[22:0];

        sign_b = b_reg[31];
        exp_b  = b_reg[30:23];
        frac_b = b_reg[22:0];


        //======================================================
        // Defaults
        //======================================================

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


        //======================================================
        // Zero handling
        //======================================================

        if ((exp_a == 8'b0) &&
            (frac_a == 23'b0)) begin

            result_comb = b_reg;

        end

        else if ((exp_b == 8'b0) &&
                 (frac_b == 23'b0)) begin

            result_comb = a_reg;

        end


        //======================================================
        // Normal FP32 numbers
        //======================================================

        else begin

            //==================================================
            // Restore hidden 1
            //==================================================

            mant_a = {1'b1, frac_a};
            mant_b = {1'b1, frac_b};


            //==================================================
            // Find larger magnitude
            //==================================================

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


            //==================================================
            // Add GRS bits
            //==================================================

            aligned_large = {
                mant_large,
                3'b000
            };

            aligned_small = {
                mant_small,
                3'b000
            };


            //==================================================
            // Align smaller operand
            //==================================================

            shift_amount =
                exp_large - exp_small;

            aligned_small =
                shift_right_sticky(
                    aligned_small,
                    shift_amount
                );


            //==================================================
            // Same signs -> addition
            //==================================================

            if (sign_a == sign_b) begin

                mant_result =
                    {1'b0, aligned_large} +
                    {1'b0, aligned_small};

                result_sign = sign_a;
                result_exp  = exp_large;


                //================================================
                // Carry generated
                //================================================

                if (mant_result[27]) begin

                    normalized =
                        mant_result[27:1];

                    normalized[0] =
                        mant_result[1] |
                        mant_result[0];

                    result_exp =
                        exp_large + 1'b1;

                end

                else begin

                    normalized =
                        mant_result[26:0];

                end

            end


            //==================================================
            // Different signs -> subtraction
            //==================================================

            else begin

                mant_result =
                    {1'b0, aligned_large} -
                    {1'b0, aligned_small};

                result_sign = sign_large;
                result_exp  = exp_large;


                //================================================
                // Exact cancellation
                //================================================

                if (mant_result == 28'b0) begin

                    normalized  = 27'b0;
                    result_exp  = 8'b0;
                    result_sign = 1'b0;

                end

                else begin

                    normalized =
                        mant_result[26:0];


                    //============================================
                    // OPTIMIZED NORMALIZATION
                    //
                    // OLD:
                    //
                    // for 27 cycles:
                    //     normalized <<= 1
                    //     exponent--
                    //
                    // NEW:
                    //
                    // leading-zero detector
                    //        ↓
                    // shift amount
                    //        ↓
                    // one variable shift
                    //
                    // This reduces the sequential-looking
                    // normalization chain.
                    //============================================

                    shift_amount =
                        leading_zero_count(normalized);


                    //============================================
                    // Cannot shift more than exponent allows.
                    //
                    // This preserves the behavior of the
                    // original:
                    //
                    // if (result_exp > 0)
                    //     shift
                    //============================================

                    if (shift_amount > result_exp)
                        shift_amount = result_exp;


                    //============================================
                    // Single normalization shift
                    //============================================

                    normalized =
                        normalized << shift_amount;


                    //============================================
                    // Update exponent once
                    //============================================

                    result_exp =
                        result_exp - shift_amount;

                end

            end


            //==================================================
            // Exact zero
            //==================================================

            if (normalized == 27'b0) begin

                result_comb = 32'b0;

            end

            else begin

                //================================================
                // Extract GRS
                //================================================

                guard_bit  = normalized[2];
                round_bit  = normalized[1];
                sticky_bit = normalized[0];


                //================================================
                // Remove GRS bits
                //================================================

                rounded_mant =
                    normalized[26:3];


                //================================================
                // Round-to-nearest-even
                //================================================

                if (guard_bit &&
                    (round_bit ||
                     sticky_bit ||
                     rounded_mant[0])) begin

                    rounded_mant =
                        rounded_mant + 1'b1;

                end


                //================================================
                // Rounding carry
                //================================================

                if (rounded_mant[24]) begin

                    rounded_mant =
                        rounded_mant >> 1;

                    result_exp =
                        result_exp + 1'b1;

                end


                //================================================
                // Exponent overflow
                //================================================

                if (result_exp >= 8'hFF) begin

                    result_comb = {
                        result_sign,
                        8'hFF,
                        23'b0
                    };

                end


                //================================================
                // Underflow
                //================================================

                else if (result_exp == 8'b0) begin

                    result_comb = {
                        result_sign,
                        8'b0,
                        23'b0
                    };

                end


                //================================================
                // Normal result
                //================================================

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


    //==========================================================
    // Stage 1
    //
    // Register inputs
    //==========================================================

    always @(posedge clk) begin

        if (!rst_n) begin

            a_reg    <= 32'b0;
            b_reg    <= 32'b0;
            valid_reg <= 1'b0;

        end

        else begin

            if (valid_in) begin

                a_reg <= a;
                b_reg <= b;

            end

            valid_reg <= valid_in;

        end

    end


    //==========================================================
    // Stage 2
    //
    // Register output
    //==========================================================

    always @(posedge clk) begin

        if (!rst_n) begin

            sum_reg       <= 32'b0;
            valid_out_reg <= 1'b0;

        end

        else begin

            if (valid_reg) begin

                sum_reg <= result_comb;

            end

            valid_out_reg <= valid_reg;

        end

    end


    //==========================================================
    // Outputs
    //==========================================================

    assign sum       = sum_reg;
    assign valid_out = valid_out_reg;


endmodule