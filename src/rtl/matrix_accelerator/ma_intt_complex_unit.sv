module ma_intt_complex_unit (
    ma_config_bus.accelerator   config_intf ,
    ma_data_bus.accelerator     data_intf   ,
    ma_rsp_intf.accelerator     rsp_intf    
);

// Local Parameters Definition  ------------------------------------------------------------------------------
localparam NUMBER_OF_ALU = data_intf.DATA_WIDTH / config_intf.ALU_WIDTH;
localparam NTT_LATENCY = 10;
localparam WIDTH = config_intf.ALU_WIDTH;
localparam W0 = 13;
localparam W1 = 17;
localparam W_NOTUSED = WIDTH - W0 - W1;


// Wires Definition ------------------------------------------------------------------------------------------
logic   en;

logic   [config_intf.ALU_WIDTH - 1 : 0]    op1_alu [NUMBER_OF_ALU - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]    op2_alu [NUMBER_OF_ALU - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]    res_alu [NUMBER_OF_ALU - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]    res_ntt [2 * NUMBER_OF_ALU - 1 : 0];

logic   ntt_en;
logic   [NTT_LATENCY - 1 : 0]   ntt_delay_line;

logic   rs_addr_en, rs_incr;
logic   operands_addr_gen_en;

logic   rs_done;

logic   start_1;
logic   concat_en, out_sel;
logic   [$clog2(data_intf.PRF_N_LANES) : 0] mask_value;


// Combinatorial Logic ---------------------------------------------------------------------------------------
assign data_intf.unit_id = ma_intf_pkg::INTT_COMPLEX_UNIT;
assign data_intf.op1.scheme = prf_dtypes::ROW;
assign data_intf.op2.scheme = prf_dtypes::ROW;
assign data_intf.rez.scheme = prf_dtypes::ROW;
assign rsp_intf.unit_id = data_intf.unit_id;
assign en = config_intf.dst_unit == data_intf.unit_id;

assign data_intf.rez.valid = concat_en;
assign concat_en = ntt_delay_line[NTT_LATENCY - 1];

assign operands_addr_gen_en = rs_addr_en | config_intf.start;
assign ntt_en = ntt_delay_line[0] | config_intf.start;

assign data_intf.op1.valid = en;
assign data_intf.op2.valid = en;

assign res_alu = out_sel ? res_ntt[2 * NUMBER_OF_ALU - 1 -: NUMBER_OF_ALU] :
                            res_ntt[NUMBER_OF_ALU - 1 : 0];

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
    if ( rs_done )                      rs_addr_en <= 1'b0;  

always @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )             start_1 <= 1'b0;            else
                                        start_1 <= config_intf.start;

// 101010...
always @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )             rs_incr <= 1'b0;            else
    if ( start_1 & en )                 rs_incr <= 1'b1;            else
    if ( rs_addr_en )                   rs_incr <= ~rs_incr;        

always @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )             out_sel <= 1'b0;            else
    if ( config_intf.start & en )       out_sel <= 1'b0;            else
    if ( concat_en )                    out_sel <= ~out_sel;  

always @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )     ntt_delay_line <= 'd0;              else
                                ntt_delay_line <= {ntt_delay_line[NTT_LATENCY - 2 : 0], rs_addr_en};


// Modules Instances -----------------------------------------------------------------------------------------
prf_complex_addr_gen_seq #(
    .PRF_N_LANES    ( data_intf.PRF_N_LANES ),
    .PRF_LOG_N      ( data_intf.PRF_LOG_N   ),
    .PRF_LOG_M      ( data_intf.PRF_LOG_M   )
) i_rs_addr_gen (
    .clk        ( data_intf.clk         ),
    .rst_n      ( data_intf.rst_n       ),
    .en         ( operands_addr_gen_en  ),
    .start      ( config_intf.start     ),
    .incr       ( rs_incr               ),
    .r          ( config_intf.rs1       ),
    .i_re_out   ( data_intf.op1.i       ),
    .j_re_out   ( data_intf.op1.j       ),
    .i_im_out   ( data_intf.op2.i       ),
    .j_im_out   ( data_intf.op2.j       ),
    .done       ( rs_done               )
);

mrsn_intt_complex16 #(
    .WIDTH  ( 32 ),
    .LEN    ( 16 )
) i_mrsn_intt_complex16 (
    .clk_i  ( data_intf.clk                                 ),
    .rst_ni ( data_intf.rst_n                               ),
    .en_i   ( en                                            ),
    .a_re_i ( op1_alu                                       ),
    .a_im_i ( op2_alu                                       ),
    .c_re_o ( res_ntt[NUMBER_OF_ALU - 1 : 0]                ),
    .c_im_o ( res_ntt[2* NUMBER_OF_ALU - 1 : NUMBER_OF_ALU] )
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
    .incr    ( concat_en            ),
    .r       ( config_intf.rd       ),
    .i_out   ( data_intf.rez.i      ),
    .j_out   ( data_intf.rez.j      ),
    .mask    ( mask_value           ),
    .done    ( rsp_intf.done        )
);

endmodule