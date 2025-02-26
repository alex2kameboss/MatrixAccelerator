module matrix_unit #(
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

localparam SA_HEIGHT = PRF_N_LANES;
localparam SA_WIDTH = PRF_N_LANES * 4;

localparam NUMBER_OF_ALU = DMA_DATA_WIDTH / ALU_WIDTH;

logic array_reset_n   [SA_HEIGHT - 1 : 0][SA_WIDTH - 1 : 0];
logic concat_en;
wire fast = rs1.dtype == ma_pkg::INT32 | rs1.dtype == ma_pkg::UINT32;

logic rs1_done, rs2_done;
logic rs_incr;

logic   [ALU_WIDTH - 1 : 0]    op1_alu [SA_HEIGHT - 1 : 0];
logic   [ALU_WIDTH - 1 : 0]    op2_alu [SA_WIDTH - 1 : 0];
logic   [ALU_WIDTH - 1 : 0]    res_alu [PRF_N_LANES - 1 : 0];
logic sa_valid;

logic   [ALU_WIDTH - 1 : 0]    op1_sa [SA_HEIGHT - 1 : 0];
logic   [ALU_WIDTH - 1 : 0]    op2_sa [SA_WIDTH - 1 : 0];
logic   [ALU_WIDTH - 1 : 0]    res_sa [SA_HEIGHT - 1 : 0][SA_WIDTH - 1 : 0];

logic start_delayed, rs_incr_delayed;
always @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       start_delayed <= 1'b0;      else
                                        start_delayed <= start;

always @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       rs_incr_delayed <= 1'b0;      else
                                        rs_incr_delayed <= rs_incr;

logic rs_addr_en;
assign rs1_read = (~fast ? rs_incr_delayed : rs_incr) | start_delayed;
assign rs2_read = rs_addr_en;

always @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       rs_addr_en <= 1'b0;         else
    if ( start & en )                   rs_addr_en <= 1'b1;         else
    if ( rs1_done & rs2_done )          rs_addr_en <= 1'b0;         

logic splitter_en;
always @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       splitter_en <= 1'b0;         else
                                        splitter_en <= rs_addr_en;

row_addr_gen_seq #(
    .ARRAY_WIDTH    ( SA_WIDTH    ),
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
    .r2      ( rs2                  ),
    .repeater( rs2.width            ),
    .i_out   ( rs1_i_out            ),
    .j_out   ( rs1_j_out            ),
    .done    ( rs1_done             )
);

col_addr_gen_seq #(
    .ARRAY_HEIGHT   ( SA_HEIGHT   ),
    .PRF_N_LANES    ( PRF_N_LANES ),
    .PRF_LOG_N      ( PRF_LOG_N   ),
    .PRF_LOG_M      ( PRF_LOG_M   )
) i_rs2_addr_gen (
    .clk     ( clk                  ),
    .rst_n   ( rst_n                ),
    .start   ( start                ),
    .en      ( rs_addr_en | start & ~scalar_op ),
    .incr    ( rs_addr_en           ),
    .r       ( rs2                  ),
    .repeater( rs1.height           ),
    .i_out   ( rs2_i_out            ),
    .j_out   ( rs2_j_out            ),
    .done    ( rs2_done             )
);

vectorial_splitter #(
    .IN_DATA_WIDTH  ( DMA_DATA_WIDTH ),
    .OUT_DATA_WIDTH ( ALU_WIDTH      )
) i_row_splitter (
    .clk        ( clk       ),
    .rst_n      ( rst_n     ),
    .reset      ( start     ),
    .en         (splitter_en),
    .dtype      ( rs1.dtype ),
    .op_in      ( rs1_data  ),
    .op_out     ( op1_alu   ),
    .next       ( rs_incr   )
);

sa_col_splitter #(
    .IN_DATA_WIDTH  ( DMA_DATA_WIDTH ),
    .OUT_DATA_WIDTH ( ALU_WIDTH      )
) i_col_splitter (
    .clk        ( clk       ),
    .rst_n      ( rst_n     ),
    .reset      ( start     ),
    .en         (splitter_en),
    .dtype      ( rs2.dtype ),
    .op_in      ( rs2_data  ),
    .op_out     ( op2_alu   )
);

// systolic array
crossbar #(
    .DATA_WIDTH     ( ALU_WIDTH     ),
    .ARRAY_ELLEMENTS( SA_HEIGHT     )
) row_crossbar (
    .clk            ( clk           ),
    .reset_n        ( rst_n         ),
    .sync_reset_n   ( 1'b1          ),
    .shift          ( concat_en     ),
    .data_i         ( op1_alu       ),
    .data_o         ( op1_sa        ) 
);

crossbar #(
    .DATA_WIDTH     ( ALU_WIDTH     ),
    .ARRAY_ELLEMENTS( SA_WIDTH      )
) col_crossbar (
    .clk            ( clk           ),
    .reset_n        ( rst_n         ),
    .sync_reset_n   ( 1'b1          ),
    .shift          ( concat_en     ),
    .data_i         ( op2_alu       ),
    .data_o         ( op2_sa        ) 
);

systolic_array #(
    .ARRAY_WIDTH ( SA_WIDTH     ),
    .ARRAY_HEIGHT( SA_HEIGHT    ),
    .DATA_WIDTH  ( ALU_WIDTH    )
) array (
    .clk            ( clk           ),
    .reset_n        ( rst_n         ),
    .array_reset_n  ( array_reset_n ),
    .en             ( concat_en     ),
    .dtype          ( rs2.dtype     ),
    .a_array_input  ( op1_sa        ),
    .b_array_input  ( op2_sa        ),
    .c_array_output ( res_sa        )
);

array_results_controller #(
    .ARRAY_HEIGHT    ( SA_HEIGHT     ),
    .ARRAY_WIDTH     ( SA_WIDTH      ),
    .DATA_WIDTH      ( ALU_WIDTH     )
) i_result_controller (
    .clk            ( clk           ),
    .reset_n        ( rst_n         ),
    .en             ( concat_en     ),
    .dtype          ( rs2.dtype     ),
    .start          ( start         ),
    .rd             ( rd            ),
    .rs1            ( rs1           ),
    .rs2            ( rs2           ),
    .array_results  ( res_sa        ),
    .array_reset_n  ( array_reset_n ),
    .data_o         ( res_alu       ),
    .valid_o        ( sa_valid      )
);

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )               concat_en <= 'd0;       else
    if ( splitter_en )          concat_en <= 'd1;       else
    if ( done )                 concat_en <= 'd0;       

vectorial_concat #(
    .OUT_DATA_WIDTH ( DMA_DATA_WIDTH ),
    .IN_DATA_WIDTH  ( ALU_WIDTH      )
) i_vectorial_concat (
    .clk        ( clk       ),
    .rst_n      ( rst_n     ),
    .reset      ( start     ),
    .en         ( sa_valid  ),
    .dtype      ( rd.dtype  ),
    .rez_in     ( res_alu   ),
    .rez_out    ( rd_data   ),
    .valid      ( rd_write  )
);

prf_addr_gen_seq #(
    .SCHEME         ( ma_pkg::ROW ),
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