module data_counter #(
    parameter   DATA_WIDTH  =   32  ,
    parameter   DMA_WIDTH   =   128   
) (
    input   logic                           clk         ,
    input   logic                           rst_n       ,
    input   logic   [DATA_WIDTH - 1 : 0]    load_bytes  ,
    input   logic                           load        ,
    input   logic   [DATA_WIDTH - 1 : 0]    store_bytes ,
    input   logic                           store       ,
    input   logic   [DATA_WIDTH - 1 : 0]    arith_bytes ,
    input   logic                           arith       ,
    input   logic                           cnt_up      ,
    output  logic                           clear       
);
    
localparam DMA_BYTES = DMA_WIDTH / 8;

logic [DATA_WIDTH - $clog2(DMA_BYTES) : 0]  cnt;
logic                       start;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )               start <= 'd0;               else
    if ( clear )                start <= 'd0;               else
    if ( load | store | arith ) start <= 'd1;               

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )               clear <= 'd0;               else
                                clear <= cnt == 'd1 & cnt_up;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )               cnt <= 'd0;                 else
    if ( start & cnt_up)        cnt <= cnt - 1'b1;          else
    if ( ~start ) begin
        if ( arith )                cnt <= arith_bytes[DATA_WIDTH - 1 : $clog2(DMA_BYTES)];         else
        if ( load )                 cnt <= load_bytes[DATA_WIDTH - 1 : $clog2(DMA_BYTES)];          else
        if ( store )                cnt <= store_bytes[DATA_WIDTH - 1 : $clog2(DMA_BYTES)];         
    end

endmodule