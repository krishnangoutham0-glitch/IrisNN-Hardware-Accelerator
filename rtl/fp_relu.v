`timescale 1ns/1ps

//==============================================================
// Module Name : fp_relu
// Description : FP32 ReLU activation
//
//              ReLU(x) = max(0, x)
//
// Pipeline:
//              Input -> Register -> Output
//
// Latency:
//              1 clock cycle
//==============================================================

module fp_relu (

    input              clk,
    input              rst_n,
    input              valid_in,

    input      [31:0]  data_in,

    output reg         valid_out,
    output reg [31:0]  data_out

);

    always @(posedge clk) begin

        if (!rst_n) begin

            data_out  <= 32'b0;
            valid_out <= 1'b0;

        end

        else begin

            valid_out <= valid_in;

            //--------------------------------------------------
            // Check FP32 sign bit
            //--------------------------------------------------

            if (data_in[31] == 1'b1)

                data_out <= 32'h00000000;

            else

                data_out <= data_in;

        end

    end

endmodule