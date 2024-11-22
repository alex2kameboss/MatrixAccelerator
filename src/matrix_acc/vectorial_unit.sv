module vectorial_unit #(
    parameter   NUMBER_OF_ALU       =   4   ,
    parameter   DMA_DATA_WIDTH      =   128 ,
    parameter   ALU_WIDTH           =   32  ,
    parameter   MEM_ADDR_WIDTH      =   16  ,
    parameter   REGISTER_NUMBERS    =   32  ,
    parameter   ADDR_WIDTH          =   32  
) (
    input                                                   clk         ,
    input                                                   rst_n       ,
// control signals
    input                                                   en          ,
    input                                                   soft_rst    ,
// config signals
    input   ma_pkg::operation                               op          ,
    input   ma_pkg::dtype                                   dtype       ,
// data signals
    input                       [DMA_DATA_WIDTH - 1 : 0]    rs1_alu     ,
    input                       [DMA_DATA_WIDTH - 1 : 0]    rs2_alu     ,
// output data
    // operands
    output  logic               [MEM_ADDR_WIDTH - 1 : 0]    rs1_addr    ,
    output  logic               [MEM_ADDR_WIDTH - 1 : 0]    rs2_addr    ,
    output  logic                                           rd_w_en     ,
    output  logic               [MEM_ADDR_WIDTH - 1 : 0]    rd_addr     ,
    output  logic               [DMA_DATA_WIDTH - 1 : 0]    rd_w_data   ,
// load/store signals
    input                                                   dma_write   ,
    input                                                   dma_read    
);
    
logic mem_next_addr_splitter, write_incr, read_incr;
assign write_incr = dma_read | rd_w_en & en;
assign read_incr = dma_write | mem_next_addr_splitter;

mem_addr_gen #(
    .ADDR_WIDTH(MEM_ADDR_WIDTH)
) i_write_addr_gen(
    .clk     ( clk          ),
    .rst_n   ( rst_n        ),
    .reset   ( soft_rst     ),
    .incr    ( write_incr   ),
    .addr    ( rd_addr      )
);

assign rs2_addr = rs1_addr;

logic   [ALU_WIDTH - 1 : 0]    op1_alu [NUMBER_OF_ALU - 1 : 0];
logic   [ALU_WIDTH - 1 : 0]    op2_alu [NUMBER_OF_ALU - 1 : 0];
logic   [ALU_WIDTH - 1 : 0]    res_alu [NUMBER_OF_ALU - 1 : 0];

mem_addr_gen #(
    .ADDR_WIDTH(MEM_ADDR_WIDTH)
) i_read_addr_gen(
    .clk     ( clk          ),
    .rst_n   ( rst_n        ),
    .reset   ( soft_rst     ),
    .incr    ( read_incr    ),
    .addr    ( rs1_addr     )
);

// vectorial arithmetics
genvar j;

vectorial_splitter #(
    .IN_DATA_WIDTH  ( DMA_DATA_WIDTH ),
    .OUT_DATA_WIDTH ( ALU_WIDTH      )
) i_data_splitter (
    .clk        ( clk                   ),
    .rst_n      ( rst_n                 ),
    .reset      ( soft_rst              ),
    .en         ( en                    ),
    .dtype      ( dtype                 ),
    .op1_in     ( rs1_alu               ),
    .op2_in     ( rs2_alu               ),
    .op1_out    ( op1_alu               ),
    .op2_out    ( op2_alu               ),
    .next       ( mem_next_addr_splitter)
);

generate
    for ( j = 0; j < NUMBER_OF_ALU; j = j + 1 ) begin : alu_generate
alu #(
    .DATA_WIDTH( ALU_WIDTH )
) i_vectorial_alu (
    .op  ( op         ),
    .op1 ( op1_alu[j] ),
    .op2 ( op2_alu[j] ),
    .rez ( res_alu[j] )
);
    end
endgenerate

logic concat_en;
always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )               concat_en <= 'd0;       else
    if ( soft_rst )             concat_en <= 'd0;       else
    if ( en )                   concat_en <= 'd1;      

vectorial_concat #(
    .OUT_DATA_WIDTH ( DMA_DATA_WIDTH ),
    .IN_DATA_WIDTH  ( ALU_WIDTH      )
) i_vectorial_concat (
    .clk        ( clk       ),
    .rst_n      ( rst_n     ),
    .reset      ( soft_rst  ),
    .en         ( concat_en ),
    .dtype      ( dtype     ),
    .rez_in     ( res_alu   ),
    .rez_out    ( rd_w_data ),
    .valid      ( rd_w_en   )
);

endmodule