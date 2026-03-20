`timescale 1ns / 1ps

module au_clz # (
    parameter   N       =   16  ,
    parameter   LOG_N   =   4
) (
    input   wire                clk         ,
    input   wire                rst_n       ,
    input   wire                valid_in    ,
    input   wire [N-1:0]        z           ,
    input   wire [N-1:0]        x_in        ,
    output  reg                 valid_out   ,
    output  reg  [LOG_N-1:0]    lzc         ,
    output  reg  [N-2:0]        z1          ,
    output  reg  [N/2-2:0]      z_msb       ,
    output  reg  [N-1:0]        x_out
);

// Local Parameters Definition  ------------------------------------------------------------------------------



// Wires Definition ------------------------------------------------------------------------------------------

    reg  [LOG_N-1:0]    lzc_comb;
    wire [N-1:0]        z_shifted;
    wire [N-2:0]        z1_comb;
    wire [N/2-2:0]      z_msb_comb;

// Combinatorial Logic ---------------------------------------------------------------------------------------

    integer idx;

    always @(*) begin : clz_loop
        lzc_comb = {LOG_N{1'b0}};
        for (idx = N-1; idx >= 0; idx = idx - 1) begin
            if (z[idx]) begin
                lzc_comb = (N - 1 - idx);
                disable clz_loop;
            end
        end
    end

    assign z_shifted  = z << lzc_comb;
    assign z1_comb    = z_shifted[N-1:1];
    assign z_msb_comb = z1_comb[N-2:N/2];

// Sequential Logic ------------------------------------------------------------------------------------------

    always @(posedge clk) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            lzc       <= lzc_comb;
            z1        <= z1_comb;
            z_msb     <= z_msb_comb;
            x_out     <= x_in;
        end
    end

// Modules Instances -----------------------------------------------------------------------------------------


endmodule
