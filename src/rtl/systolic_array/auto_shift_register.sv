module auto_shift_register #(
    parameter   DATA_WIDTH  =   8,
    parameter   STEPS       =   4
) (
    input                           clk         ,
    input                           reset_n     ,
    input                           sync_reset_n,
    input                           shift       ,
    input   [DATA_WIDTH - 1 : 0]    data_i      ,
    output  [DATA_WIDTH - 1 : 0]    data_o      
);

generate
    if ( STEPS == 0 ) begin
assign data_o = data_i;
    end else begin
reg     [DATA_WIDTH - 1 : 0]    buffer  [0 : STEPS - 1];

assign data_o = buffer[STEPS - 1];

always_ff @(posedge clk or negedge reset_n)
    if ( ~reset_n ) begin
        for (int i = 0; i < STEPS; i = i + 1)
            buffer[i] <= 'd0;
    end else
    if ( ~sync_reset_n ) begin
        for (int i = 0; i < STEPS; i = i + 1)
            buffer[i] <= 'd0;
    end else
    if ( shift ) begin
        buffer[0] <= data_i;
        for ( int i = 1; i < STEPS; i = i + 1)
            buffer[i] <= buffer[i - 1];
    end
    end
endgenerate

endmodule