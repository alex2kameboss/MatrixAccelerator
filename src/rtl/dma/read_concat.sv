module read_concat #(
    parameter   FIFO_DATA_WIDTH =   64  ,
    parameter   DATA_MULTIPLIER =   4    // how many data need to be concatenated
) (
    input   logic                                               clk         ,
    input   logic                                               rst_n       ,
    // fifo side
    input   logic   [FIFO_DATA_WIDTH - 1 : 0]                   fifo_data   ,
    input   logic                                               fifo_empty  ,
    output  logic                                               fifo_incr   ,
    // concatenated data side
    output  logic   [FIFO_DATA_WIDTH * DATA_MULTIPLIER - 1 : 0] data        ,
    output  logic                                               empty       ,
    input   logic                                               incr        
);
    
logic [$clog2(DATA_MULTIPLIER) - 1 : 0] cnt, cnt_next;

assign cnt_next = cnt + 1'b1;
assign fifo_incr = empty; 

always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )                       cnt <= 'd0;             else
    if ( ~fifo_empty & empty )          cnt <= cnt_next;        

always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )                       empty <= 'd1;           else
    if ( incr )                         empty <= 'd1;           else
    if ( &cnt & ~fifo_empty )           empty <= 'd0;           

always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )                       data <= 'd0;            else
    if ( empty )                        data[((cnt + 1) * FIFO_DATA_WIDTH - 1) -: FIFO_DATA_WIDTH] <= fifo_data;

endmodule