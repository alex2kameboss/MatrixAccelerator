module ma_complex_mult_unit (
    ma_config_bus.accelerator   config_intf ,
    ma_data_bus.accelerator     data_intf   ,
    ma_rsp_intf.accelerator     rsp_intf    
);

// Local Parameters Definition  ------------------------------------------------------------------------------
localparam NUMBER_OF_ALU = data_intf.DATA_WIDTH / config_intf.ALU_WIDTH;
localparam NTT_LATENCY = 5;
localparam WIDTH = config_intf.ALU_WIDTH;
localparam W0 = 13;
localparam W1 = 17;
localparam W_NOTUSED = WIDTH - W0 - W1;


// Wires Definition ------------------------------------------------------------------------------------------
logic   en, conjugate;

logic   [config_intf.ALU_WIDTH - 1 : 0]    op1_alu [NUMBER_OF_ALU - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]    op2_alu [NUMBER_OF_ALU - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]    res_alu [NUMBER_OF_ALU - 1 : 0];

logic   ntt_en;
logic   [NTT_LATENCY - 1 : 0]   ntt_delay_line;

logic   rs_addr_en;
logic   operands_addr_gen_en;

logic   rs1_done, rs2_done;

logic   concat_en;
logic   [$clog2(data_intf.PRF_N_LANES) : 0] mask_value;


// Combinatorial Logic ---------------------------------------------------------------------------------------
assign data_intf.unit_id = ma_intf_pkg::COMPLEX_MULT_UNIT;
assign data_intf.op1.scheme = prf_dtypes::COL;
assign data_intf.op2.scheme = prf_dtypes::COL;
assign data_intf.rez.scheme = prf_dtypes::COL;
assign rsp_intf.unit_id = data_intf.unit_id;
assign en = config_intf.dst_unit == data_intf.unit_id;
assign conjugate = config_intf.internal_op == ma_intf_pkg::CMC;

assign data_intf.rez.valid = concat_en;
assign concat_en = ntt_delay_line[NTT_LATENCY - 1];

assign operands_addr_gen_en = rs_addr_en | config_intf.start;
assign ntt_en = ntt_delay_line[0] | config_intf.start;

assign data_intf.op1.valid = en;
assign data_intf.op2.valid = en;

genvar lane;
generate;
    for ( lane = 0; lane < data_intf.PRF_N_LANES; lane = lane + 1 ) begin : data_splitter
assign op1_alu[lane] = data_intf.op1_data[(lane + 1) * config_intf.ALU_WIDTH - 1 -: config_intf.ALU_WIDTH];
assign op2_alu[lane] = data_intf.op2_data[(lane + 1) * config_intf.ALU_WIDTH - 1 -: config_intf.ALU_WIDTH];
assign data_intf.rez_data[(lane + 1) * config_intf.ALU_WIDTH - 1 -: config_intf.ALU_WIDTH] = res_alu[lane];
    end
endgenerate

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
    if ( rs1_done & rs2_done )          rs_addr_en <= 1'b0;  

always @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )     ntt_delay_line <= 'd0;              else
                                ntt_delay_line <= {ntt_delay_line[NTT_LATENCY - 2 : 0], rs_addr_en};


// Modules Instances -----------------------------------------------------------------------------------------
prf_addr_gen_seq #(
    .SCHEME         ( ma_pkg::ROW           ),
    .PRF_N_LANES    ( data_intf.PRF_N_LANES ),
    .PRF_LOG_N      ( data_intf.PRF_LOG_N   ),
    .PRF_LOG_M      ( data_intf.PRF_LOG_M   )
) i_rs1_addr_gen (
    .clk     ( data_intf.clk        ),
    .rst_n   ( data_intf.rst_n      ),
    .start   ( config_intf.start    ),
    .en      ( operands_addr_gen_en ),
    .incr    ( rs_addr_en           ),
    .r       ( config_intf.rs1      ),
    .i_out   ( data_intf.op1.i      ),
    .j_out   ( data_intf.op1.j      ),
    .mask    ( /* NOT CONNECTED */  ),
    .done    ( rs1_done             )
);

prf_addr_gen_seq #(
    .SCHEME         ( ma_pkg::ROW           ),
    .PRF_N_LANES    ( data_intf.PRF_N_LANES ),
    .PRF_LOG_N      ( data_intf.PRF_LOG_N   ),
    .PRF_LOG_M      ( data_intf.PRF_LOG_M   )
) i_rs2_addr_gen (
    .clk     ( data_intf.clk        ),
    .rst_n   ( data_intf.rst_n      ),
    .start   ( config_intf.start    ),
    .en      ( operands_addr_gen_en ),
    .incr    ( rs_addr_en           ),
    .r       ( config_intf.rs2      ),
    .i_out   ( data_intf.op2.i      ),
    .j_out   ( data_intf.op2.j      ),
    .mask    ( /* NOT CONNECTED */  ),
    .done    ( rs2_done             )
);

genvar j;
generate
    for ( j = 0; j < NUMBER_OF_ALU / 2; j = j + 1 ) begin : alu_generate
mrsn_complex_multiply #(
    .WIDTH  ( 32    ),
    .W0     ( 13    ),
    .W1     ( 19    )
) i_complex_mult (
    .clk_i  ( data_intf.clk     ), 
    .rst_ni ( data_intf.rst_n   ),
    .en_i   ( en                ),
    .a_re_i ( op1_alu[2 * j + 0]),
    .a_im_i ( op1_alu[2 * j + 1] ^ {config_intf.ALU_WIDTH{conjugate}}),
    .b_re_i ( op2_alu[2 * j + 0]),
    .b_im_i ( op2_alu[2 * j + 1] ^ {config_intf.ALU_WIDTH{conjugate}}),
    .z_re_o ( res_alu[2 * j + 0]),
    .z_im_o ( res_alu[2 * j + 1])
);
    end
endgenerate

prf_addr_gen_seq #(
    .SCHEME         ( ma_pkg::ROW           ),
    .PRF_N_LANES    ( data_intf.PRF_N_LANES ),
    .PRF_LOG_N      ( data_intf.PRF_LOG_N   ),
    .PRF_LOG_M      ( data_intf.PRF_LOG_M   )
) i_rd_addr_gen (
    .clk     ( data_intf.clk        ),
    .rst_n   ( data_intf.rst_n      ),
    .start   ( config_intf.start    ),
    .en      ( en                   ),
    .incr    ( concat_en            ),
    .r       ( config_intf.rd       ),
    .i_out   ( data_intf.rez.i      ),
    .j_out   ( data_intf.rez.j      ),
    .mask    ( mask_value           ),
    .done    ( rsp_intf.done        )
);

endmodule