module vectorial_unit #(
    parameter   DMA_DATA_WIDTH  =   128 ,
    parameter   ALU_WIDTH       =   32  ,
    parameter   PRF_N_LANES     =   8   ,
    parameter   PRF_LOG_N       =   10  ,
    parameter   PRF_LOG_M       =   10  
) (
    input                                                               clk         ,
    input                                                               rst_n       ,
// control signals
    input                                                               en          ,
    input                                                               start       ,
    input                                                               scalar_op   ,
// config signals
    input   ma_pkg::operation_t                                         op          ,
// register signals
    input   ma_pkg::register_file_line_t                                rd          ,
    input   ma_pkg::register_file_line_t                                rs1         ,
    input   ma_pkg::register_file_line_t                                rs2         ,
// output data
    // mem data
    output  logic                                                       rs1_read    ,
    output  logic                           [PRF_LOG_N - 1 : 0]         rs1_i_out   ,
    output  logic                           [PRF_LOG_M - 1 : 0]         rs1_j_out   ,
    output  logic                                                       rs2_read    ,
    output  logic                           [PRF_LOG_N - 1 : 0]         rs2_i_out   ,
    output  logic                           [PRF_LOG_M - 1 : 0]         rs2_j_out   ,
    output  logic                                                       rd_write    ,
    output  logic                           [PRF_LOG_N - 1 : 0]         rd_i_out    ,
    output  logic                           [PRF_LOG_M - 1 : 0]         rd_j_out    ,
    // data
    input   logic                           [DMA_DATA_WIDTH - 1 : 0]    rs1_data    ,
    input   logic                           [DMA_DATA_WIDTH - 1 : 0]    rs2_data    ,
    output  logic                           [DMA_DATA_WIDTH - 1 : 0]    rd_data     ,
// control data
    output  logic                                                       done        
);
    
localparam NUMBER_OF_ALU = DMA_DATA_WIDTH / ALU_WIDTH;


ma_pkg::dtype_t dtype;
assign dtype = rd.dtype;
wire fast = dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32;

logic rs1_done, rs2_done;
wor rs_incr;

logic   [ALU_WIDTH - 1 : 0]    op1_alu [NUMBER_OF_ALU - 1 : 0];
logic   [ALU_WIDTH - 1 : 0]    op2_alu [NUMBER_OF_ALU - 1 : 0];
logic   [ALU_WIDTH - 1 : 0]    res_alu [NUMBER_OF_ALU - 1 : 0];

logic start_delayed, rs_incr_delayed;
always @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       start_delayed <= 1'b0;      else
                                        start_delayed <= start;

always @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       rs_incr_delayed <= 1'b0;      else
                                        rs_incr_delayed <= rs_incr;

assign rs1_read = (~fast ? rs_incr_delayed : rs_incr) | start_delayed;
assign rs2_read = rs1_read;

logic rs_addr_en;
always @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       rs_addr_en <= 1'b0;         else
    if ( start & en )                   rs_addr_en <= 1'b1;         else
    if ( rs1_done & rs2_done )          rs_addr_en <= 1'b0;         

logic splitter_en;
always @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       splitter_en <= 1'b0;         else
                                        splitter_en <= rs_addr_en;

prf_addr_gen_seq #(
    .PRF_N_LANES    ( PRF_N_LANES ),
    .PRF_LOG_N      ( PRF_LOG_N   ),
    .PRF_LOG_M      ( PRF_LOG_M   )
) i_rs1_addr_gen (
    .clk     ( clk                  ),
    .rst_n   ( rst_n                ),
    .start   ( start                ),
    .en      ( rs_addr_en | start   ),
    .incr    ( rs_incr | fast & start_delayed ),
    .r       ( rs1                  ),
    .i_out   ( rs1_i_out            ),
    .j_out   ( rs1_j_out            ),
    .done    ( rs1_done             )
);

prf_addr_gen_seq #(
    .PRF_N_LANES    ( PRF_N_LANES ),
    .PRF_LOG_N      ( PRF_LOG_N   ),
    .PRF_LOG_M      ( PRF_LOG_M   )
) i_rs2_addr_gen (
    .clk     ( clk                  ),
    .rst_n   ( rst_n                ),
    .start   ( start                ),
    .en      ( rs_addr_en | start & ~scalar_op ),
    .incr    ( rs_incr | fast & start_delayed ),
    .r       ( rs2                  ),
    .i_out   ( rs2_i_out            ),
    .j_out   ( rs2_j_out            ),
    .done    ( rs2_done             )
);

// vectorial arithmetics
vectorial_splitter #(
    .IN_DATA_WIDTH  ( DMA_DATA_WIDTH ),
    .OUT_DATA_WIDTH ( ALU_WIDTH      )
) i_op1_splitter (
    .clk        ( clk       ),
    .rst_n      ( rst_n     ),
    .reset      ( start     ),
    .en         ( splitter_en),
    .dtype      ( dtype     ),
    .op_in      ( rs1_data  ),
    .op_out     ( op1_alu   ),
    .next       ( rs_incr   )
);

vectorial_splitter #(
    .IN_DATA_WIDTH  ( DMA_DATA_WIDTH ),
    .OUT_DATA_WIDTH ( ALU_WIDTH      )
) i_op2_splitter (
    .clk        ( clk       ),
    .rst_n      ( rst_n     ),
    .reset      ( start     ),
    .en         ( splitter_en),
    .dtype      ( dtype     ),
    .op_in      ( rs2_data  ),
    .op_out     ( op2_alu   ),
    .next       ( rs_incr   )
);

genvar j;

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
                                concat_en <= splitter_en;

vectorial_concat #(
    .OUT_DATA_WIDTH ( DMA_DATA_WIDTH ),
    .IN_DATA_WIDTH  ( ALU_WIDTH      )
) i_vectorial_concat (
    .clk        ( clk       ),
    .rst_n      ( rst_n     ),
    .reset      ( start     ),
    .en         ( concat_en ),
    .dtype      ( dtype     ),
    .rez_in     ( res_alu   ),
    .rez_out    ( rd_data   ),
    .valid      ( rd_write  )
);

prf_addr_gen_seq #(
    .PRF_N_LANES    ( PRF_N_LANES ),
    .PRF_LOG_N      ( PRF_LOG_N   ),
    .PRF_LOG_M      ( PRF_LOG_M   )
) i_rd_addr_gen (
    .clk     ( clk          ),
    .rst_n   ( rst_n        ),
    .start   ( start        ),
    .en      ( en           ),
    .incr    ( rd_write     ),
    .r       ( rd           ),
    .i_out   ( rd_i_out     ),
    .j_out   ( rd_j_out     ),
    .done    ( done         )
);

endmodule