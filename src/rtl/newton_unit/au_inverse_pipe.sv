`timescale 1ns / 1ps

module au_inverse_pipe # (
    parameter   N       =   16  ,
    parameter   LOG_N   =   4   ,
    parameter   CONST_A =   347 ,
    parameter   CONST_D =   -3  ,
    parameter   CONST_F =   1
) (
    input   wire                clk         ,
    input   wire                rst_n       ,
    input   wire                valid_in    ,
    input   wire [N-1:0]        x           ,
    input   wire [N-1:0]        z           ,
    output  wire                valid_out   ,
    output  wire [N-1:0]        result
);

// Local Parameters Definition  ------------------------------------------------------------------------------

    localparam H = N / 2;

// Wires Definition ------------------------------------------------------------------------------------------

    // Stage 1 -> Stage 2
    wire                valid_s1;
    wire [LOG_N-1:0]    lzc_s1;
    wire [N-2:0]        z1_s1;
    wire [H-2:0]        z_msb_s1;
    wire [N-1:0]        x_s1;

    // Stage 2 -> Stage 3
    wire                valid_s2;
    wire [H:0]          y0_s2;
    wire [H-2:0]        z_msb_s2;
    wire [N-1:0]        x_s2;
    wire [LOG_N-1:0]    lzc_s2;
    wire [N-2:0]        z1_s2;

    // Stage 3 -> Stage 4
    wire                valid_s3;
    wire [N-1:0]        y1_s3;
    wire [N-1:0]        x_s3;
    wire [LOG_N-1:0]    lzc_s3;
    wire [N-2:0]        z1_s3;

    // Stage 4 -> Stage 5
    wire                valid_s4;
    wire [N-1:0]        y2_s4;
    wire [N-1:0]        x_s4;
    wire [LOG_N-1:0]    lzc_s4;

// Combinatorial Logic ---------------------------------------------------------------------------------------



// Sequential Logic ------------------------------------------------------------------------------------------



// Modules Instances -----------------------------------------------------------------------------------------

    au_clz # (
        .N      (N),
        .LOG_N  (LOG_N)
    ) u_clz (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_in),
        .z          (z),
        .x_in       (x),
        .valid_out  (valid_s1),
        .lzc        (lzc_s1),
        .z1         (z1_s1),
        .z_msb      (z_msb_s1),
        .x_out      (x_s1)
    );

    au_initial_approx # (
        .N       (N),
        .LOG_N   (LOG_N),
        .CONST_A (CONST_A)
    ) u_initial_approx (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_s1),
        .z_msb_in   (z_msb_s1),
        .x_in       (x_s1),
        .lzc_in     (lzc_s1),
        .z1_in      (z1_s1),
        .valid_out  (valid_s2),
        .y0         (y0_s2),
        .z_msb_out  (z_msb_s2),
        .x_out      (x_s2),
        .lzc_out    (lzc_s2),
        .z1_out     (z1_s2)
    );

    au_newton_step1 # (
        .N       (N),
        .LOG_N   (LOG_N),
        .CONST_D (CONST_D)
    ) u_newton_step1 (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_s2),
        .y0         (y0_s2),
        .z_msb_in   (z_msb_s2),
        .x_in       (x_s2),
        .lzc_in     (lzc_s2),
        .z1_in      (z1_s2),
        .valid_out  (valid_s3),
        .y1         (y1_s3),
        .x_out      (x_s3),
        .lzc_out    (lzc_s3),
        .z1_out     (z1_s3)
    );

    au_newton_step2 # (
        .N       (N),
        .LOG_N   (LOG_N),
        .CONST_F (CONST_F)
    ) u_newton_step2 (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_s3),
        .y1         (y1_s3),
        .z1         (z1_s3),
        .x_in       (x_s3),
        .lzc_in     (lzc_s3),
        .valid_out  (valid_s4),
        .y2         (y2_s4),
        .x_out      (x_s4),
        .lzc_out    (lzc_s4)
    );

    au_final_multiply # (
        .N      (N),
        .LOG_N  (LOG_N)
    ) u_final_multiply (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_s4),
        .x          (x_s4),
        .y2         (y2_s4),
        .lzc        (lzc_s4),
        .valid_out  (valid_out),
        .result     (result)
    );

endmodule
