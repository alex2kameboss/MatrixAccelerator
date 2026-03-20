`timescale 1ns / 1ps

module au_final_multiply # (
    parameter   N       =   16  ,
    parameter   LOG_N   =   4
) (
    input   wire                    clk         ,
    input   wire                    rst_n       ,
    input   wire                    valid_in    ,
    input   wire [N-1:0]            x           ,
    input   wire [N-1:0]            y2          ,
    input   wire [LOG_N-1:0]        lzc         ,
    output  reg                     valid_out   ,
    output  reg  [N-1:0]            result
);

// Local Parameters Definition  ------------------------------------------------------------------------------



// Wires Definition ------------------------------------------------------------------------------------------

    reg [2*N-1:0]    product;
    reg [LOG_N:0]    shift_amt;
    reg [N:0]        shifted;
    reg [N-1:0]      result_comb;

// Combinatorial Logic ---------------------------------------------------------------------------------------

    always @(*) begin
        product     = x * y2;
        shift_amt   = (N - 1) - lzc;
        shifted     = product >> shift_amt;
        result_comb = shifted[N] ? {N{1'b1}} : shifted[N-1:0];
    end

// Sequential Logic ------------------------------------------------------------------------------------------

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            result    <= result_comb;
        end
    end

// Modules Instances -----------------------------------------------------------------------------------------


endmodule
