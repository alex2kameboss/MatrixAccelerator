`timescale 1ns / 1ps

module au_newton_step1 # (
    parameter   N       =   16  ,
    parameter   LOG_N   =   4   ,
    parameter   CONST_D =   -3
) (
    input   wire                    clk         ,
    input   wire                    rst_n       ,
    input   wire                    valid_in    ,
    input   wire [N/2:0]            y0          ,
    input   wire [N/2-2:0]          z_msb_in    ,
    input   wire [N-1:0]            x_in        ,
    input   wire [LOG_N-1:0]        lzc_in      ,
    input   wire [N-2:0]            z1_in       ,
    output  reg                     valid_out   ,
    output  reg  [N-1:0]            y1          ,
    output  reg  [N-1:0]            x_out       ,
    output  reg  [LOG_N-1:0]        lzc_out     ,
    output  reg  [N-2:0]            z1_out
);

// Local Parameters Definition  ------------------------------------------------------------------------------

    localparam H = N / 2;

    localparam [N-1:0] TWO_N_M1_PLUS_D = (1 << (N-1)) + CONST_D;

// Wires Definition ------------------------------------------------------------------------------------------

    reg [2*H-1:0]   yz;
    reg [N-1:0]     diff;
    reg [H:0]       factor;
    reg [2*H+1:0]   product;
    reg [N-1:0]     y1_comb;

// Combinatorial Logic ---------------------------------------------------------------------------------------

    always @(*) begin
        yz      = y0 * z_msb_in;
        diff    = TWO_N_M1_PLUS_D - yz;
        factor  = diff[N-1:H-1];
        product = y0 * factor;
        y1_comb = product[N-1:0] << 1;
    end

// Sequential Logic ------------------------------------------------------------------------------------------

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            y1        <= y1_comb;
            x_out     <= x_in;
            lzc_out   <= lzc_in;
            z1_out    <= z1_in;
        end
    end

// Modules Instances -----------------------------------------------------------------------------------------


endmodule
