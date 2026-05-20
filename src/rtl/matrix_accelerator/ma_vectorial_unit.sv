module ma_vectorial_unit (
    ma_config_bus.accelerator   config_intf ,
    ma_data_bus.accelerator     data_intf   ,
    ma_rsp_intf.accelerator     rsp_intf    
);

// Local Parameters Definition  ------------------------------------------------------------------------------
localparam NUMBER_OF_ALU = data_intf.DATA_WIDTH / config_intf.ALU_WIDTH;


// Wires Definition ------------------------------------------------------------------------------------------
logic   en;
logic   scalar_op;

logic   [data_intf.DATA_WIDTH - 1 : 0]    scalar_line;
logic   [data_intf.DATA_WIDTH - 1 : 0]    op2;

logic   [config_intf.ALU_WIDTH - 1 : 0]    op1_alu [NUMBER_OF_ALU - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]    op2_alu [NUMBER_OF_ALU - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]    res_alu [NUMBER_OF_ALU - 1 : 0];

logic   rs_addr_en, start_delayed;
logic   operands_addr_gen_en;
logic   op1_addr_gen_incr, op2_addr_gen_incr;
logic   rs1_incr, rs2_incr;
logic   fast_rs1, fast_rs2;
logic   rs1_incr_1, rs2_incr_1;

logic   splitter_en;
logic   rs1_done, rs2_done;

logic   concat_en;
logic   [$clog2(data_intf.PRF_N_LANES) : 0] mask_value;


// Combinatorial Logic ---------------------------------------------------------------------------------------
assign data_intf.unit_id = ma_intf_pkg::VECTORIAL_UNIT;
assign data_intf.op1.scheme = prf_dtypes::ROW;
assign data_intf.op2.scheme = prf_dtypes::ROW;
assign data_intf.rez.scheme = prf_dtypes::ROW;
assign rsp_intf.unit_id = data_intf.unit_id;
assign en = config_intf.dst_unit == data_intf.unit_id;
assign scalar_op =  config_intf.internal_op == ma_intf_pkg::ADD_VS | 
                    config_intf.internal_op == ma_intf_pkg::SUB_VS |
                    config_intf.internal_op == ma_intf_pkg::DIV_VS |
                    config_intf.internal_op == ma_intf_pkg::SLL_VS |
                    config_intf.internal_op == ma_intf_pkg::SRL_VS |
                    config_intf.internal_op == ma_intf_pkg::SRA_VS |
                    config_intf.internal_op == ma_intf_pkg::MUL_VS ; 

assign scalar_line = config_intf.rd.dtype == ma_pkg::INT32 | config_intf.rd.dtype == ma_pkg::UINT32 ? {NUMBER_OF_ALU {config_intf.scalar[31 : 0]}} :
                     config_intf.rd.dtype == ma_pkg::INT16 | config_intf.rd.dtype == ma_pkg::UINT16 ? {NUMBER_OF_ALU * 2 {config_intf.scalar[15 : 0]}} :
                                                                                                      {NUMBER_OF_ALU * 4 {config_intf.scalar[7 : 0]}};
assign op2 = scalar_op ? scalar_line : data_intf.op2_data;                                                                                      

assign operands_addr_gen_en = rs_addr_en | config_intf.start;
assign op1_addr_gen_incr = rs1_incr | fast_rs1 & start_delayed;
assign op2_addr_gen_incr = rs2_incr | fast_rs2 & start_delayed;
assign fast_rs1 = config_intf.rs1.dtype == ma_pkg::INT32 | config_intf.rs1.dtype == ma_pkg::UINT32;
assign fast_rs2 = config_intf.rs2.dtype == ma_pkg::INT32 | config_intf.rs2.dtype == ma_pkg::UINT32;

//assign data_intf.op1.valid = ( ~fast_rs1 ? rs1_incr_1 : rs1_incr ) | start_delayed;
//assign data_intf.op2.valid = ( ~fast_rs2 ? rs2_incr_1 : rs2_incr ) | start_delayed;
assign data_intf.op1.valid = en;
assign data_intf.op2.valid = en;

genvar idx, val;
generate;
    for ( idx = 0; idx < data_intf.PRF_N_LANES; idx = idx + 1 ) begin : lanes_valid_idx
        wor bit_valid;
        for ( val = idx + 1; val <= data_intf.PRF_N_LANES; val = val + 1 ) begin : mask_value_check
assign bit_valid = mask_value == val;
        end
assign data_intf.rez.lane_valid[idx] = bit_valid;
    end
endgenerate


// Sequential Logic ------------------------------------------------------------------------------------------
always @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )             rs_addr_en <= 1'b0;         else
    if ( config_intf.start & en )       rs_addr_en <= 1'b1;         else
    if ( rs1_done & 
       (rs2_done | scalar_op) )         rs_addr_en <= 1'b0;  

always @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )             start_delayed <= 1'b0;      else
                                        start_delayed <= config_intf.start;

always @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )             rs1_incr_1 <= 1'b0;         else
                                        rs1_incr_1 <= rs1_incr;

always @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )             rs2_incr_1 <= 1'b0;         else
                                        rs2_incr_1 <= rs2_incr;                                        

always @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )             splitter_en <= 1'b0;         else
                                        splitter_en <= rs_addr_en;

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )     concat_en <= 'd0;                    else
                                concat_en <= splitter_en;


// Modules Instances -----------------------------------------------------------------------------------------
prf_addr_gen_seq #(
    .PRF_N_LANES    ( data_intf.PRF_N_LANES ),
    .PRF_LOG_N      ( data_intf.PRF_LOG_N   ),
    .PRF_LOG_M      ( data_intf.PRF_LOG_M   )
) i_rs1_addr_gen (
    .clk     ( data_intf.clk        ),
    .rst_n   ( data_intf.rst_n      ),
    .start   ( config_intf.start    ),
    .en      ( operands_addr_gen_en ),
    .incr    ( op1_addr_gen_incr    ),
    .r       ( config_intf.rs1      ),
    .i_out   ( data_intf.op1.i      ),
    .j_out   ( data_intf.op1.j      ),
    .mask    ( /* NOT CONNECTED */  ),
    .done    ( rs1_done             )
);

prf_addr_gen_seq #(
    .PRF_N_LANES    ( data_intf.PRF_N_LANES ),
    .PRF_LOG_N      ( data_intf.PRF_LOG_N   ),
    .PRF_LOG_M      ( data_intf.PRF_LOG_M   )
) i_rs2_addr_gen (
    .clk     ( data_intf.clk        ),
    .rst_n   ( data_intf.rst_n      ),
    .start   ( config_intf.start    ),
    .en      ( operands_addr_gen_en & ~scalar_op ),
    .incr    ( op2_addr_gen_incr    ),
    .r       ( config_intf.rs2      ),
    .i_out   ( data_intf.op2.i      ),
    .j_out   ( data_intf.op2.j      ),
    .mask    ( /* NOT CONNECTED */  ),
    .done    ( rs2_done             )
);

vectorial_splitter #(
    .IN_DATA_WIDTH  ( data_intf.DATA_WIDTH  ),
    .OUT_DATA_WIDTH ( config_intf.ALU_WIDTH )
) i_op1_splitter (
    .clk        ( data_intf.clk         ),
    .rst_n      ( data_intf.rst_n       ),
    .reset      ( config_intf.start     ),
    .en         ( splitter_en           ),
    .dtype      ( config_intf.rs1.dtype ),
    .op_in      ( data_intf.op1_data    ),
    .op_out     ( op1_alu               ),
    .next       ( rs1_incr              )
);

vectorial_splitter #(
    .IN_DATA_WIDTH  ( data_intf.DATA_WIDTH  ),
    .OUT_DATA_WIDTH ( config_intf.ALU_WIDTH )
) i_op2_splitter (
    .clk        ( data_intf.clk         ),
    .rst_n      ( data_intf.rst_n       ),
    .reset      ( config_intf.start     ),
    .en         ( splitter_en           ),
    .dtype      ( scalar_op ? config_intf.rs1.dtype : config_intf.rs2.dtype ),
    .op_in      ( op2                   ),
    .op_out     ( op2_alu               ),
    .next       ( rs2_incr              )
);

genvar j;
generate
    for ( j = 0; j < NUMBER_OF_ALU; j = j + 1 ) begin : alu_generate
ma_alu #(
    .DATA_WIDTH( config_intf.ALU_WIDTH  )
) i_vectorial_alu (
    .clk    ( data_intf.clk         ),
    .en     ( splitter_en           ),
    .op     ( config_intf.op        ),
    .dtype  ( config_intf.rs1.dtype ),
    .op1    ( op1_alu[j]            ),
    .op2    ( op2_alu[j]            ),
    .rez    ( res_alu[j]            )
);
    end
endgenerate

vectorial_concat #(
    .OUT_DATA_WIDTH ( data_intf.DATA_WIDTH  ),
    .IN_DATA_WIDTH  ( config_intf.ALU_WIDTH )
) i_vectorial_concat (
    .clk        ( data_intf.clk         ),
    .rst_n      ( data_intf.rst_n       ),
    .reset      ( config_intf.start     ),
    .en         ( concat_en             ),
    .dtype      ( config_intf.rd.dtype  ),
    .rez_in     ( res_alu               ),
    .rez_out    ( data_intf.rez_data    ),
    .valid      ( data_intf.rez.valid   )
);

prf_addr_gen_seq #(
    .PRF_N_LANES    ( data_intf.PRF_N_LANES ),
    .PRF_LOG_N      ( data_intf.PRF_LOG_N   ),
    .PRF_LOG_M      ( data_intf.PRF_LOG_M   )
) i_rd_addr_gen (
    .clk     ( data_intf.clk        ),
    .rst_n   ( data_intf.rst_n      ),
    .start   ( config_intf.start    ),
    .en      ( en                   ),
    .incr    ( data_intf.rez.valid  ),
    .r       ( config_intf.rd       ),
    .i_out   ( data_intf.rez.i      ),
    .j_out   ( data_intf.rez.j      ),
    .mask    ( mask_value           ),
    .done    ( rsp_intf.done        )
);

endmodule