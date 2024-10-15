module delay_line #(
    parameter DATA_WIDTH    =   1   ,
    parameter DELAY_NUMBER  =   3
) (
    input   logic                           clk     ,
    input   logic                           rst_n   ,
    input   logic   [DATA_WIDTH - 1 : 0]    in      ,
    output  logic   [DATA_WIDTH - 1 : 0]    out     
);
    
logic [DATA_WIDTH - 1 : 0]  d   [0 : DELAY_NUMBER - 1];
int i;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        for ( i = 0; i < DELAY_NUMBER; i = i + 1 )
            d[i] <= 'd0;
    end else
        d <= { in, d[0 : DELAY_NUMBER - 2] };

assign out = d[DELAY_NUMBER - 1];

endmodule