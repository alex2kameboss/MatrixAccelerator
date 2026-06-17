`timescale 1ns / 1ps

module au_newton_step2 # (
    parameter   N       =   16  ,
    parameter   LOG_N   =   4   ,
    parameter   CONST_F =   1
) (
    input   wire                    clk         ,
    input   wire                    rst_n       ,
    input   wire                    valid_in    ,
    input   wire [N-1:0]            y1          ,
    input   wire [N-2:0]            z1          ,
    input   wire [N-1:0]            x_in        ,
    input   wire [LOG_N-1:0]        lzc_in      ,
    output  reg                     valid_out   ,
    output  reg  [N-1:0]            y2          ,
    output  reg  [N-1:0]            x_out       ,
    output  reg  [LOG_N-1:0]        lzc_out
);

// Local Parameters Definition  ------------------------------------------------------------------------------

    localparam [N:0] TWO_N_PLUS_F = (1 << N) + CONST_F;

// Wires Definition ------------------------------------------------------------------------------------------

    reg [2*N-2:0]    yz;
    reg [N-1:0]      yz_hi;
    reg [N:0]        factor;
    reg [2*N:0]      product;
    reg [N-1:0]      y2_comb;

// Combinatorial Logic ---------------------------------------------------------------------------------------

    always @(*) begin
        yz      = y1 * z1;
        yz_hi   = yz[2*N-2:N-1];
        factor  = TWO_N_PLUS_F - {1'b0, yz_hi};
        product = y1 * factor;
        y2_comb = product[2*N:N-1];
    end

// Sequential Logic ------------------------------------------------------------------------------------------

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            y2        <= y2_comb;
            x_out     <= x_in;
            lzc_out   <= lzc_in;
        end
    end

// Modules Instances -----------------------------------------------------------------------------------------


endmodule
