`timescale 1ns/1ps

//==============================================================
// Module Name : fp_argmax
//
// Description:
//     Finds the maximum of three FP32 values.
//
//     input:
//         x0 -> class 0
//         x1 -> class 1
//         x2 -> class 2
//
//     output:
//         index = 0, 1, or 2
//
//     Pipeline:
//         1 clock cycle
//
//==============================================================

module fp_argmax (

    input              clk,
    input              rst_n,
    input              valid_in,

    input      [31:0]  x0,
    input      [31:0]  x1,
    input      [31:0]  x2,

    output reg         valid_out,
    output reg [1:0]   index

);

    //----------------------------------------------------------
    // FP32 comparison function
    //
    // Returns 1 when A > B
    //----------------------------------------------------------

    function fp_greater;

        input [31:0] A;
        input [31:0] B;

        reg sign_A;
        reg sign_B;

        reg [30:0] mag_A;
        reg [30:0] mag_B;

        begin

            sign_A = A[31];
            sign_B = B[31];

            mag_A = A[30:0];
            mag_B = B[30:0];

            //--------------------------------------------------
            // A positive, B negative
            //--------------------------------------------------

            if ((sign_A == 1'b0) &&
                (sign_B == 1'b1)) begin

                fp_greater = 1'b1;

            end

            //--------------------------------------------------
            // A negative, B positive
            //--------------------------------------------------

            else if ((sign_A == 1'b1) &&
                     (sign_B == 1'b0)) begin

                fp_greater = 1'b0;

            end

            //--------------------------------------------------
            // Both positive
            //
            // Larger magnitude = larger number
            //--------------------------------------------------

            else if (sign_A == 1'b0) begin

                fp_greater = (mag_A > mag_B);

            end

            //--------------------------------------------------
            // Both negative
            //
            // Smaller magnitude = larger number
            //
            // Example:
            //     -2 > -5
            //--------------------------------------------------

            else begin

                fp_greater = (mag_A < mag_B);

            end

        end

    endfunction

    //----------------------------------------------------------
    // Combinational argmax
    //----------------------------------------------------------

    reg [1:0] max_index;

    always @(*) begin

        //------------------------------------------------------
        // Start by assuming x0 is maximum
        //------------------------------------------------------

        max_index = 2'd0;

        //------------------------------------------------------
        // Compare x1 against x0
        //------------------------------------------------------

        if (fp_greater(x1, x0))
            max_index = 2'd1;

        //------------------------------------------------------
        // Compare x2 against current maximum
        //------------------------------------------------------

        if ((max_index == 2'd0) &&
            fp_greater(x2, x0))

            max_index = 2'd2;

        else if ((max_index == 2'd1) &&
                 fp_greater(x2, x1))

            max_index = 2'd2;

    end

    //----------------------------------------------------------
    // Output register
    //----------------------------------------------------------

    always @(posedge clk) begin

        if (!rst_n) begin

            index     <= 2'd0;
            valid_out <= 1'b0;

        end

        else begin

            index     <= max_index;
            valid_out <= valid_in;

        end

    end

endmodule