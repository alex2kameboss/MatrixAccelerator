module au_inverse_top # (
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



// Wires Definition ------------------------------------------------------------------------------------------



// Combinatorial Logic ---------------------------------------------------------------------------------------



// Sequential Logic ------------------------------------------------------------------------------------------



// Modules Instances -----------------------------------------------------------------------------------------



endmodule