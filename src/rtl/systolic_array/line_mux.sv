module line_mux #(
    parameter   ARRAY_WIDTH         =   32  ,
    parameter   DATA_WIDTH          =   32  
) (
    input   logic                           clk                                     ,
    input   logic                           rst_n                                   ,
    input   logic                           en                                      ,
    input   logic   [DATA_WIDTH - 1 : 0]    array_results   [ ARRAY_WIDTH - 1 : 0 ] ,
    output  logic   [DATA_WIDTH - 1 : 0]    result                                  
);
    
logic [$clog2(ARRAY_WIDTH) - 1 : 0] cnt;

assign result = array_results[cnt];

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   cnt <= 'd0;             else
    if ( en )                       cnt <= cnt + 1'b1;

endmodule