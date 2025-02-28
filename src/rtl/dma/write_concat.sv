module write_concat #(
    parameter FIFO_DATA_WIDTH   =   64  ,
    parameter DATA_MULTIPLIER   =   4   
) (
    input   logic                                               clk         ,
    input   logic                                               rst_n       ,
    // fifo side
    output  logic   [FIFO_DATA_WIDTH - 1 : 0]                   fifo_data   ,
    input   logic                                               fifo_full   ,
    output  logic                                               fifo_incr   ,
    // concatenated data side
    input   logic   [FIFO_DATA_WIDTH * DATA_MULTIPLIER - 1 : 0] data        ,
    output  logic                                               full        ,
    input   logic                                               incr        
);
    
logic [$clog2(DATA_MULTIPLIER) - 1 : 0] cnt, cnt_next;
logic [FIFO_DATA_WIDTH * DATA_MULTIPLIER - 1 : 0] buffer;

assign cnt_next = cnt + 1'b1;
assign fifo_data = buffer[((cnt + 1) * FIFO_DATA_WIDTH - 1) -: FIFO_DATA_WIDTH];
assign full = fifo_incr & ~(&cnt & ~fifo_full);

always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )                       cnt <= 'd0;             else
    if ( ~fifo_full & fifo_incr )       cnt <= cnt_next;     

always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )                       buffer <= 'd0;          else
    if ( ~full & incr )                 buffer <= data;                        

always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )                       fifo_incr <= 'd0;       else
    if ( ~|cnt & incr )                 fifo_incr <= 'd1;       else
    if ( &cnt & ~incr & ~fifo_full )    fifo_incr <= 'd0;

endmodule