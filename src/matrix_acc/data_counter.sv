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
    
logic arith_edge, load_edge, store_edge;

localparam DMA_BYTES = DMA_WIDTH / 8;

logic [DATA_WIDTH - $clog2(DMA_BYTES) : 0]  cnt;
logic                       start;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )               start <= 'd0;               else
    if ( clear )                start <= 'd0;               else
    if ( load_edge | 
            store_edge | 
            arith_edge )        start <= 'd1;               

//always_ff @( posedge clk, negedge rst_n )
//    if ( ~rst_n )               clear <= 'd0;               else
//                                clear <= cnt == 'd1 & cnt_up;

assign clear = cnt == 'd1 & cnt_up;                            

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )               cnt <= 'd0;                 else
    if ( start & cnt_up)        cnt <= cnt - 1'b1;          else
    if ( ~start ) begin
        if ( arith_edge )           cnt <= arith_bytes[DATA_WIDTH - 1 : $clog2(DMA_BYTES)];         else
        if ( load_edge )            cnt <= load_bytes[DATA_WIDTH - 1 : $clog2(DMA_BYTES)];          else
        if ( store_edge )           cnt <= store_bytes[DATA_WIDTH - 1 : $clog2(DMA_BYTES)];         
    end

posedge_detector i_arith_edge (
    .clk    ( clk           ),
    .rst_n  ( rst_n         ),
    .signal ( arith         ),
    .flag   ( arith_edge    ) 
);

posedge_detector i_load_edge (
    .clk    ( clk           ),
    .rst_n  ( rst_n         ),
    .signal ( load          ),
    .flag   ( load_edge     ) 
);

posedge_detector i_store_edge (
    .clk    ( clk           ),
    .rst_n  ( rst_n         ),
    .signal ( store         ),
    .flag   ( store_edge    ) 
);

endmodule