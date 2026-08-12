`timescale 1ns/1ps

//==============================================================
// Module Name : fp_multiplier
// Project     : FP32 Neural Network Accelerator
// Description : Pipelined IEEE-754 FP32 Multiplier
//
// Pipeline:
//   Stage 1 : Input registers
//   Stage 2 : Multiply + normalize + round + output register
//
// Rounding:
//   Round-to-nearest-even
//
// Notes:
// - Normal FP32 numbers are supported.
// - Zero, Infinity and NaN are handled.
// - Subnormal arithmetic is not implemented yet.
//==============================================================

module fp_multiplier (
    input              clk,
    input              rst_n,
    input              valid_in,

    input      [31:0]  a,
    input      [31:0]  b,

    output reg         valid_out,
    output reg [31:0]  product
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
    // Hidden 1 is restored
    //----------------------------------------------------------

    reg [23:0] mant_a;
    reg [23:0] mant_b;

    //----------------------------------------------------------
    // 48-bit multiplication result
    //----------------------------------------------------------

    reg [47:0] mant_product;

    //----------------------------------------------------------
    // Normalized mantissa
    //----------------------------------------------------------

    reg [23:0] normalized_mant;

    //----------------------------------------------------------
    // Rounding bits
    //----------------------------------------------------------

    reg guard_bit;
    reg round_bit;
    reg sticky_bit;

    //----------------------------------------------------------
    // Rounded mantissa
    //
    // 25 bits because rounding can generate a carry.
    //----------------------------------------------------------

    reg [24:0] rounded_mant;

    //----------------------------------------------------------
    // Result fields
    //----------------------------------------------------------

    reg        result_sign;
    reg [7:0]  result_exp;

    reg [31:0] result_comb;

    //----------------------------------------------------------
    // Temporary exponent
    //----------------------------------------------------------

    integer exponent_temp;

    //----------------------------------------------------------
    // Combinational multiplier datapath
    //----------------------------------------------------------

    always @(*) begin

        //------------------------------------------------------
        // Extract fields
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

        mant_product = 48'b0;

        normalized_mant = 24'b0;

        guard_bit  = 1'b0;
        round_bit  = 1'b0;
        sticky_bit = 1'b0;

        rounded_mant = 25'b0;

        result_sign = sign_a ^ sign_b;
        result_exp  = 8'b0;

        result_comb = 32'b0;

        exponent_temp = 0;

        //------------------------------------------------------
        // NaN
        //------------------------------------------------------

        if (((exp_a == 8'hFF) && (frac_a != 0)) ||
            ((exp_b == 8'hFF) && (frac_b != 0))) begin

            result_comb = 32'h7FC00000;

        end

        //------------------------------------------------------
        // Infinity × Zero = NaN
        //------------------------------------------------------

        else if (((exp_a == 8'hFF) && (frac_a == 0) &&
                  (exp_b == 0) && (frac_b == 0)) ||
                 ((exp_b == 8'hFF) && (frac_b == 0) &&
                  (exp_a == 0) && (frac_a == 0))) begin

            result_comb = 32'h7FC00000;

        end

        //------------------------------------------------------
        // Infinity
        //------------------------------------------------------

        else if ((exp_a == 8'hFF) && (frac_a == 0)) begin

            result_comb = {
                result_sign,
                8'hFF,
                23'b0
            };

        end

        else if ((exp_b == 8'hFF) && (frac_b == 0)) begin

            result_comb = {
                result_sign,
                8'hFF,
                23'b0
            };

        end

        //------------------------------------------------------
        // Zero
        //------------------------------------------------------

        else if ((exp_a == 0) && (frac_a == 0)) begin

            result_comb = {
                result_sign,
                31'b0
            };

        end

        else if ((exp_b == 0) && (frac_b == 0)) begin

            result_comb = {
                result_sign,
                31'b0
            };

        end

        //------------------------------------------------------
        // Normal FP32 multiplication
        //------------------------------------------------------

        else begin

            //--------------------------------------------------
            // Restore hidden 1
            //--------------------------------------------------

            mant_a = {1'b1, frac_a};
            mant_b = {1'b1, frac_b};

            //--------------------------------------------------
            // Multiply 24-bit significands
            //--------------------------------------------------

            mant_product = mant_a * mant_b;

            //--------------------------------------------------
            // Sign
            //--------------------------------------------------

            result_sign = sign_a ^ sign_b;

            //--------------------------------------------------
            // Exponent calculation
            //
            // Actual exponent:
            //
            // EA + EB - Bias
            //
            // Bias = 127
            //--------------------------------------------------

            exponent_temp =
                exp_a + exp_b - 127;

            //--------------------------------------------------
            // Normalize
            //
            // Product is between:
            //
            // 1.0 × 1.0 = 1.0
            //
            // and
            //
            // < 2.0 × 2.0 = < 4.0
            //
            // Therefore the product can be either:
            //
            // 01.xxxxx
            //
            // or
            //
            // 10.xxxxx
            //--------------------------------------------------

            if (mant_product[47]) begin

                //------------------------------------------------
                // Product is >= 2
                //------------------------------------------------

                normalized_mant =
                    mant_product[47:24];

                guard_bit =
                    mant_product[23];

                round_bit =
                    mant_product[22];

                sticky_bit =
                    |mant_product[21:0];

                exponent_temp =
                    exponent_temp + 1;

            end

            else begin

                //------------------------------------------------
                // Product is < 2
                //------------------------------------------------

                normalized_mant =
                    mant_product[46:23];

                guard_bit =
                    mant_product[22];

                round_bit =
                    mant_product[21];

                sticky_bit =
                    |mant_product[20:0];

            end

            //--------------------------------------------------
            // Convert exponent back to 8-bit representation
            //--------------------------------------------------

            if (exponent_temp <= 0) begin

                result_exp = 8'b0;

            end

            else if (exponent_temp >= 255) begin

                result_exp = 8'hFF;

            end

            else begin

                result_exp = exponent_temp[7:0];

            end

            //--------------------------------------------------
            // Prepare mantissa for rounding
            //--------------------------------------------------

            rounded_mant = {1'b0, normalized_mant};

            //--------------------------------------------------
            // Round-to-nearest-even
            //--------------------------------------------------

            if (guard_bit &&
                (round_bit ||
                 sticky_bit ||
                 normalized_mant[0])) begin

                rounded_mant =
                    rounded_mant + 1'b1;

            end

            //--------------------------------------------------
            // Rounding overflow
            //
            // Example:
            //
            // 1.111111...
            //
            // becomes
            //
            // 10.000000...
            //--------------------------------------------------

            if (rounded_mant[24]) begin

                rounded_mant =
                    rounded_mant >> 1;

                exponent_temp =
                    exponent_temp + 1;

                if (exponent_temp >= 255)
                    result_exp = 8'hFF;
                else
                    result_exp = exponent_temp[7:0];

            end

            //--------------------------------------------------
            // Overflow -> Infinity
            //--------------------------------------------------

            if (exponent_temp >= 255) begin

                result_comb = {
                    result_sign,
                    8'hFF,
                    23'b0
                };

            end

            //--------------------------------------------------
            // Underflow
            //
            // Subnormal result not implemented yet.
            //--------------------------------------------------

            else if (exponent_temp <= 0) begin

                result_comb = {
                    result_sign,
                    8'b0,
                    23'b0
                };

            end

            //--------------------------------------------------
            // Normal result
            //--------------------------------------------------

            else begin

                result_comb = {
                    result_sign,
                    result_exp,
                    rounded_mant[22:0]
                };

            end

        end

    end

    //----------------------------------------------------------
    // Stage 1 : Input registers
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

            product   <= 32'b0;
            valid_out <= 1'b0;

        end

        else begin

            product   <= result_comb;
            valid_out <= valid_reg;

        end

    end

endmodule