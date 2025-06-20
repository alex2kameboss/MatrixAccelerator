module ma_matrix_unit (
    ma_config_bus.accelerator   config_intf ,
    ma_data_bus.accelerator     data_intf   ,
    ma_rsp_intf.accelerator     rsp_intf    
);

// Local Parameters Definition  ------------------------------------------------------------------------------
localparam SA_HEIGHT = data_intf.PRF_N_LANES;
localparam SA_WIDTH = data_intf.PRF_N_LANES * 4;


// Wires Definition ------------------------------------------------------------------------------------------
logic   en;

logic                                       array_reset_n   [SA_HEIGHT - 1 : 0][SA_WIDTH - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]     op1_alu         [SA_HEIGHT - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]     op2_alu         [SA_WIDTH - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]     res_alu         [data_intf.PRF_N_LANES - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]     op1_sa          [SA_HEIGHT - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]     op2_sa          [SA_WIDTH - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]     res_sa          [SA_HEIGHT - 1 : 0][SA_WIDTH - 1 : 0];

logic   rs_addr_en, start_delayed;
logic   operands_addr_gen_en;
logic   op1_addr_gen_incr;
logic   fast_rs1;
logic   rs1_incr, rs1_incr_1;

logic   splitter_en;
logic   rs1_done, rs2_done;

logic   concat_en;
logic   sa_valid;


// Combinatorial Logic ---------------------------------------------------------------------------------------
assign data_intf.unit_id = ma_intf_pkg::MATRIX_UNIT;
assign data_intf.op1.scheme = prf_dtypes::COL;
assign data_intf.op1.valid = (~fast_rs1 ? rs1_incr_1 : rs1_incr) | start_delayed;
assign data_intf.op2.scheme = prf_dtypes::ROW;
assign data_intf.op2.valid = rs_addr_en;
assign data_intf.rez.scheme = prf_dtypes::COL;
assign data_intf.rez.lane_valid = {data_intf.PRF_N_LANES{1'b1}};
assign rsp_intf.unit_id = data_intf.unit_id;
assign en = config_intf.dst_unit == data_intf.unit_id;

assign operands_addr_gen_en = rs_addr_en | config_intf.start;
assign op1_addr_gen_incr = rs1_incr | fast_rs1 & start_delayed;
assign fast_rs1 = config_intf.rs1.dtype == ma_pkg::INT32 | config_intf.rs1.dtype == ma_pkg::UINT32;


// Sequential Logic ------------------------------------------------------------------------------------------
always @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )             start_delayed <= 1'b0;      else
                                        start_delayed <= config_intf.start;

always @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )             rs_addr_en <= 1'b0;         else
    if ( config_intf.start & en )       rs_addr_en <= 1'b1;         else
    if ( rs1_done & rs2_done )          rs_addr_en <= 1'b0;                                          

always @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )             rs1_incr_1 <= 1'b0;         else
                                        rs1_incr_1 <= rs1_incr;

always @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )             splitter_en <= 1'b0;         else
                                        splitter_en <= rs_addr_en;

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )             concat_en <= 'd0;           else
    if ( rsp_intf.done )                concat_en <= 'd0;           else
    if ( splitter_en )                  concat_en <= 'd1;           


// Modules Instances -----------------------------------------------------------------------------------------
row_addr_gen_seq #(
    .ARRAY_WIDTH    ( SA_WIDTH    ),
    .PRF_N_LANES    ( data_intf.PRF_N_LANES ),
    .PRF_LOG_N      ( data_intf.PRF_LOG_N   ),
    .PRF_LOG_M      ( data_intf.PRF_LOG_M   )
) i_rs1_addr_gen (
    .clk     ( data_intf.clk            ),
    .rst_n   ( data_intf.rst_n          ),
    .start   ( config_intf.start        ),
    .en      ( operands_addr_gen_en     ),
    .incr    ( op1_addr_gen_incr        ),
    .r       ( config_intf.rs1          ),
    .r2      ( config_intf.rs2          ),
    .repeater( config_intf.rs2.width    ),
    .i_out   ( data_intf.op1.i          ),
    .j_out   ( data_intf.op1.j          ),
    .done    ( rs1_done                 )
);

col_addr_gen_seq #(
    .ARRAY_HEIGHT   ( SA_HEIGHT             ),
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
    .repeater(config_intf.rs1.height),
    .i_out   ( data_intf.op2.i      ),
    .j_out   ( data_intf.op2.j      ),
    .done    ( rs2_done             )
);

vectorial_splitter #(
    .IN_DATA_WIDTH  ( data_intf.DATA_WIDTH  ),
    .OUT_DATA_WIDTH ( config_intf.ALU_WIDTH )
) i_row_splitter (
    .clk        ( data_intf.clk         ),
    .rst_n      ( data_intf.rst_n       ),
    .reset      ( config_intf.start     ),
    .en         ( splitter_en           ),
    .dtype      ( config_intf.rs1.dtype ),
    .op_in      ( data_intf.op1_data    ),
    .op_out     ( op1_alu               ),
    .next       ( rs1_incr              )
);

sa_col_splitter #(
    .IN_DATA_WIDTH  ( data_intf.DATA_WIDTH  ),
    .OUT_DATA_WIDTH ( config_intf.ALU_WIDTH )
) i_col_splitter (
    .clk        ( data_intf.clk         ),
    .rst_n      ( data_intf.rst_n       ),
    .reset      ( config_intf.start     ),
    .en         ( splitter_en           ),
    .dtype      ( config_intf.rs2.dtype ),
    .op_in      ( data_intf.op2_data    ),
    .op_out     ( op2_alu               )
);

crossbar #(
    .DATA_WIDTH     ( config_intf.ALU_WIDTH ),
    .ARRAY_ELEMENTS ( SA_HEIGHT             )
) row_crossbar (
    .clk            ( data_intf.clk     ),
    .reset_n        ( data_intf.rst_n   ),
    .sync_reset_n   ( ~rsp_intf.done    ),
    .shift          ( concat_en         ),
    .data_i         ( op1_alu           ),
    .data_o         ( op1_sa            ) 
);

crossbar #(
    .DATA_WIDTH     ( config_intf.ALU_WIDTH ),
    .ARRAY_ELEMENTS ( SA_WIDTH              )
) col_crossbar (
    .clk            ( data_intf.clk     ),
    .reset_n        ( data_intf.rst_n   ),
    .sync_reset_n   ( ~rsp_intf.done    ),
    .shift          ( concat_en         ),
    .data_i         ( op2_alu           ),
    .data_o         ( op2_sa            ) 
);

systolic_array #(
    .ARRAY_WIDTH ( SA_WIDTH             ),
    .ARRAY_HEIGHT( SA_HEIGHT            ),
    .DATA_WIDTH  ( config_intf.ALU_WIDTH)
) array (
    .clk            ( data_intf.clk                     ),
    .reset_n        ( data_intf.rst_n & ~rsp_intf.done  ),
    .array_reset_n  ( array_reset_n                     ),
    .en             ( concat_en                         ),
    .dtype          ( config_intf.rs2.dtype             ),
    .a_array_input  ( op1_sa                            ),
    .b_array_input  ( op2_sa                            ),
    .c_array_output ( res_sa                            )
);

array_results_controller #(
    .ARRAY_HEIGHT    ( SA_HEIGHT            ),
    .ARRAY_WIDTH     ( SA_WIDTH             ),
    .DATA_WIDTH      ( config_intf.ALU_WIDTH)
) i_result_controller (
    .clk            ( data_intf.clk         ),
    .reset_n        ( data_intf.rst_n       ),
    .en             ( concat_en             ),
    .soft_reset     ( rsp_intf.done         ),
    .dtype          ( config_intf.rs2.dtype ),
    .start          ( config_intf.start     ),
    .rd             ( config_intf.rd        ),
    .rs1            ( config_intf.rs1       ),
    .rs2            ( config_intf.rs2       ),
    .array_results  ( res_sa                ),
    .array_reset_n  ( array_reset_n         ),
    .data_o         ( res_alu               ),
    .valid_o        ( sa_valid              )
);

vectorial_concat #(
    .OUT_DATA_WIDTH ( data_intf.DATA_WIDTH  ),
    .IN_DATA_WIDTH  ( config_intf.ALU_WIDTH )
) i_vectorial_concat (
    .clk        ( data_intf.clk         ),
    .rst_n      ( data_intf.rst_n       ),
    .reset      ( config_intf.start     ),
    .en         ( sa_valid              ),
    .dtype      ( config_intf.rd.dtype  ),
    .rez_in     ( res_alu               ),
    .rez_out    ( data_intf.rez_data    ),
    .valid      ( data_intf.rez.valid   )
);

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
    .incr    ( data_intf.rez.valid  ),
    .r       ( config_intf.rd       ),
    .i_out   ( data_intf.rez.i      ),
    .j_out   ( data_intf.rez.j      ),
    .done    ( rsp_intf.done        )
);

endmodule