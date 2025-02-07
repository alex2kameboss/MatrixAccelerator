module line_mux #(
    parameter   ARRAY_WIDTH         =   32  ,
    parameter   DATA_WIDTH          =   32  
) (
    input   logic                           clk                                     ,
    input   logic                           rst_n                                   ,
    input   logic                           en              [ ARRAY_WIDTH - 1 : 0 ] ,
    input   logic   [DATA_WIDTH - 1 : 0]    array_results   [ ARRAY_WIDTH - 1 : 0 ] ,
    output  logic   [DATA_WIDTH - 1 : 0]    result                                  
);
    
always_comb begin : blockName
    result = 'd0;
    for ( int i = 0; i < ARRAY_WIDTH; i = i + 1 )
        if ( ~en[i] )
            result = array_results[i];
end

endmodule