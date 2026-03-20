`timescale 1ns / 1ps

module au_initial_approx # (
    parameter   N       =   16  ,
    parameter   LOG_N   =   4   ,
    parameter   CONST_A =   347
) (
    input   wire                    clk         ,
    input   wire                    rst_n       ,
    input   wire                    valid_in    ,
    input   wire [N/2-2:0]          z_msb_in    ,
    input   wire [N-1:0]            x_in        ,
    input   wire [LOG_N-1:0]        lzc_in      ,
    input   wire [N-2:0]            z1_in       ,
    output  reg                     valid_out   ,
    output  reg  [N/2:0]            y0          ,
    output  reg  [N/2-2:0]          z_msb_out   ,
    output  reg  [N-1:0]            x_out       ,
    output  reg  [LOG_N-1:0]        lzc_out     ,
    output  reg  [N-2:0]            z1_out
);

// Local Parameters Definition  ------------------------------------------------------------------------------

    localparam H = N / 2;

// Wires Definition ------------------------------------------------------------------------------------------

    reg [H+1:0] seven_z;
    reg [H-1:0] seven_z_shifted;
    reg [H:0]   y0_comb;

// Combinatorial Logic ---------------------------------------------------------------------------------------

    always @(*) begin
        seven_z         = ({3'b0, z_msb_in} << 3) - {3'b0, z_msb_in};
        seven_z_shifted = seven_z[H+1:2];
        y0_comb         = CONST_A - seven_z_shifted;
    end

// Sequential Logic ------------------------------------------------------------------------------------------

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            y0        <= y0_comb;
            z_msb_out <= z_msb_in;
            x_out     <= x_in;
            lzc_out   <= lzc_in;
            z1_out    <= z1_in;
        end
    end

// Modules Instances -----------------------------------------------------------------------------------------


endmodule
