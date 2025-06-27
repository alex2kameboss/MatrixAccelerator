module mask_generator #(
    parameter   PRF_LOG_PARAM   =   2   ,
    localparam  PRF_PARAM       =   2 ** PRF_LOG_PARAM
) (
    input   logic                           clk     ,
    input   logic                           rst_n   ,
    input   logic                           en      ,
    input   logic   [PRF_LOG_PARAM - 1 : 0] value   , // mod 2 ** PRF_PARAM
    output  logic       [PRF_PARAM - 1 : 0] mask    
);

// Local Parameters Definition  ------------------------------------------------------------------------------



// Wires Definition ------------------------------------------------------------------------------------------
logic                       is_zero;
logic   [PRF_PARAM - 1 : 0] mask_internal;


// Combinatorial Logic ---------------------------------------------------------------------------------------
assign is_zero = ~|value;
genvar i;

generate;
    for ( i = 0 ; i < PRF_PARAM; i = i + 1 ) begin : mask_generation
assign mask_internal[i] = is_zero | value >= (i + 1); 
    end
endgenerate


// Sequential Logic ------------------------------------------------------------------------------------------
always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )           mask <= 'd0;            else
    if ( en )               mask <= mask_internal;  


// Modules Instances -----------------------------------------------------------------------------------------



endmodule