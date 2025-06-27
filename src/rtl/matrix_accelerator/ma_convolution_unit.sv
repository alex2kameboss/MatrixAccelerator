module ma_convolution_unit (
    ma_config_bus.accelerator   config_intf ,
    ma_data_bus.accelerator     data_intf   ,
    ma_rsp_intf.accelerator     rsp_intf    
);

// Local Parameters Definition  ------------------------------------------------------------------------------
localparam NUMBER_OF_ALU = data_intf.DATA_WIDTH / config_intf.ALU_WIDTH;
localparam SA_HEIGHT = data_intf.PRF_N_LANES;
localparam SA_WIDTH = 1;
localparam PRF_P = 2 ** data_intf.PRF_LOG_P;
localparam PRF_Q = 2 ** data_intf.PRF_LOG_Q;


// Wires Definition ------------------------------------------------------------------------------------------
logic   en, start_1, start_2, start_3;
logic   splitter_en, addr_gen_en, addr_gen_en_q, addr_gen_done;

logic                                       array_reset_n   [SA_HEIGHT - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]     matrix_data     [SA_HEIGHT - 1 : 0], matrix_mask     [SA_HEIGHT - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]     kernel_data     [SA_HEIGHT - 1 : 0], kernel_mask     [SA_HEIGHT - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]     matrix_data_sa  [SA_HEIGHT - 1 : 0], matrix_data_shifter  [SA_HEIGHT - 1 : 0], matrix_mask_shifter  [SA_HEIGHT - 1 : 0];
logic   [config_intf.ALU_WIDTH - 1 : 0]     kernel_data_sa, kernel_data_shifter;                          ;
logic   [config_intf.ALU_WIDTH - 1 : 0]     res_sa          [SA_HEIGHT - 1 : 0];
logic kernel_mask_shifter;

logic   [PRF_P - 1 : 0] matrix_mask_row, kernel_mask_row;
logic   [PRF_Q - 1 : 0] matrix_mask_col, kernel_mask_col;

logic   [1 : 0] matrix_selector, matrix_selector_1, kernel_selector, kernel_selector_1;

logic   matrix_shifter_en [SA_HEIGHT - 1 : 0], matrix_shifter_load [SA_HEIGHT - 1 : 0], matrix_shifter_shift[SA_HEIGHT - 1 : 0];
wor   kernel_shifter_en, kernel_shifter_shift;
logic kernel_shifter_load;

// Combinatorial Logic ---------------------------------------------------------------------------------------
assign data_intf.unit_id = ma_intf_pkg::CNV_UNIT;
assign data_intf.op1.scheme = prf_dtypes::RECT;
assign data_intf.op2.scheme = prf_dtypes::RECT;
assign data_intf.rez.lane_valid = {data_intf.PRF_N_LANES{1'b1}};
assign en = config_intf.dst_unit == data_intf.unit_id;

genvar data_selector_idx;
assign kernel_data_sa = kernel_mask_shifter ? kernel_data_shifter : 'd0;
generate;
    for ( data_selector_idx = 0; data_selector_idx < SA_HEIGHT; data_selector_idx = data_selector_idx + 1 ) begin : systolic_array_data_selector
assign matrix_data_sa[data_selector_idx] = matrix_mask_shifter[data_selector_idx] ? matrix_data_shifter[data_selector_idx] : 'd0;
assign kernel_shifter_en = matrix_shifter_en[data_selector_idx]; 
assign kernel_shifter_shift = matrix_shifter_shift[data_selector_idx];
    end
endgenerate

assign kernel_shifter_load = matrix_shifter_load[0];

assign addr_gen_en = (config_intf.start | addr_gen_en_q) & en;


// Sequential Logic ------------------------------------------------------------------------------------------
genvar mask_row_idx, mask_col_idx;
generate;
    for ( mask_row_idx = 0; mask_row_idx < PRF_P; mask_row_idx = mask_row_idx + 1 ) begin : mask_generation_row
        for ( mask_col_idx = 0; mask_col_idx < PRF_Q; mask_col_idx = mask_col_idx + 1 ) begin: mask_generator_col
always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n ) begin
        matrix_mask[mask_row_idx * (PRF_Q) + mask_col_idx] <= 'd0;
        kernel_mask[mask_row_idx * (PRF_Q) + mask_col_idx] <= 'd0;
    end else if ( en ) begin
        matrix_mask[mask_row_idx * (PRF_Q) + mask_col_idx] <= matrix_mask_row[mask_row_idx] & matrix_mask_col[mask_col_idx];
        kernel_mask[mask_row_idx * (PRF_Q) + mask_col_idx] <= kernel_mask_row[mask_row_idx] & kernel_mask_col[mask_col_idx];
    end
        end
    end
endgenerate

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )         addr_gen_en_q <= 1'b0;                  else
    if ( en ) begin
        if ( data_intf.start )      addr_gen_en_q <= 1'b1;                  else
        if ( addr_gen_done )        addr_gen_en_q <= 1'b0;
    end

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )         start_1 <= 'd0;                         else
    if ( en )                       start_1 <= config_intf.start;

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )         start_2 <= 'd0;                         else
    if ( en )                       start_2 <= start_1;

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )         start_3 <= 'd0;                         else
    if ( en )                       start_3 <= start_3;

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )         data_intf.op1.valid <= 1'b0;            else
    if ( en ) begin
        if (start_1)                data_intf.op1.valid <= 1'b1;            
    end

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )         data_intf.op2.valid <= 1'b0;            else
    if ( en ) begin
        if (start_1)                data_intf.op2.valid <= 1'b1;            
    end

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )         splitter_en <= 1'b0;                    else
    if ( en )                       splitter_en <= data_intf.op1.valid;

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )         matrix_selector_1 <= 'd0;               else
    if ( en )                       matrix_selector_1 <= matrix_selector;

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )         kernel_selector_1 <= 'd0;               else
    if ( en )                       kernel_selector_1 <= kernel_selector;

// data feeder for SA
always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )         matrix_shifter_en[0] <= 1'b0;           else
    if ( en )                       matrix_shifter_en[0] <= splitter_en;

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )         matrix_shifter_load[0] <= 1'b0;         else
    if ( en ) begin
        if ( start_3 )              matrix_shifter_load[0] <= 1'b1;         else
                                    matrix_shifter_load[0] <= matrix_shifter_load[SA_HEIGHT - 1];
    end

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )         matrix_shifter_shift[0] <= 1'b0;        else
    if ( en )                       matrix_shifter_shift[0] <= splitter_en;

genvar shifter_ctrl_idx;
generate;
    for ( shifter_ctrl_idx = 1; shifter_ctrl_idx < data_intf.PRF_N_LANES; shifter_ctrl_idx = shifter_ctrl_idx + 1 ) begin : shifter_ctrl_loop
always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )         matrix_shifter_en[shifter_ctrl_idx] <= 1'b0;    else
    if ( en )                       matrix_shifter_en[shifter_ctrl_idx] <= matrix_shifter_en[shifter_ctrl_idx - 1];

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )         matrix_shifter_load[shifter_ctrl_idx] <= 1'b0;  else
    if ( en )                       matrix_shifter_load[shifter_ctrl_idx] <= matrix_shifter_load[shifter_ctrl_idx - 1];

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )         matrix_shifter_shift[shifter_ctrl_idx] <= 1'b0;    else
    if ( en )                       matrix_shifter_shift[shifter_ctrl_idx] <= matrix_shifter_shift[shifter_ctrl_idx - 1];
    end
endgenerate


// Modules Instances -----------------------------------------------------------------------------------------
matrix_addr_gen #(
    .PRF_LOG_P  ( data_intf.PRF_LOG_P   ),
    .PRF_LOG_Q  ( data_intf.PRF_LOG_Q   ),
    .PRF_LOG_N  ( data_intf.PRF_LOG_N   ),
    .PRF_LOG_M  ( data_intf.PRF_LOG_M   ),
    .SRAM_WIDTH ( data_intf.SRAM_WIDTH  )
) i_matrix_addr_gen (
    .clk        ( data_intf.clk     ),
    .rst_n      ( data_intf.rst_n   ),
    .en         ( addr_gen_en       ),
    .start      ( config_intf.start ),
    .incr       ( 1'b1              ),
    .r          ( config_intf.rs1   ),
    .r_k        ( config_intf.rs2   ),
    .i_out      ( data_intf.op1.i   ),
    .j_out      ( data_intf.op1.j   ),
    .row_mask   ( matrix_mask_row   ), // 1 clk after addr
    .col_mask   ( matrix_mask_col   ), // 1 clk after addr
    .done       ( addr_gen_done     ),
    .selector   ( matrix_selector   )      
);

kernel_addr_gen #(
    .PRF_LOG_P  ( data_intf.PRF_LOG_P   ),
    .PRF_LOG_Q  ( data_intf.PRF_LOG_Q   ),
    .PRF_LOG_N  ( data_intf.PRF_LOG_N   ),
    .PRF_LOG_M  ( data_intf.PRF_LOG_M   )
) i_kernel_addr_gen (
    .clk        ( data_intf.clk     ),
    .rst_n      ( data_intf.rst_n   ),
    .en         ( addr_gen_en       ),
    .start      ( config_intf.start ),
    .incr       ( 1'b1              ),
    .r          ( config_intf.rs2   ),
    .i_out      ( data_intf.op1.i   ),
    .j_out      ( data_intf.op1.j   ),
    .row_mask   ( kernel_mask_row   ),
    .col_mask   ( kernel_mask_col   ),
    .selector   ( kernel_selector   )
);

cnv_data_splitter #(
    .PRF_LOG_P      ( data_intf.PRF_LOG_P ),
    .PRF_LOG_Q      ( data_intf.PRF_LOG_Q ),
    .OUT_DATA_WIDTH ( config_intf.ALU_WIDTH )
) i_matrix_data_splitter (
    .clk        ( data_intf.clk         ),
    .rst_n      ( data_intf.rst_n       ),
    .reset      ( config_intf.start     ),
    .en         ( splitter_en           ),
    .selector   ( matrix_selector_1     ),
    .dtype      ( config_intf.rs1.dtype ),
    .op_in      ( data_intf.op1_data    ),
    .op_out     ( matrix_data           )
);

cnv_data_splitter #(
    .PRF_LOG_P      ( data_intf.PRF_LOG_P ),
    .PRF_LOG_Q      ( data_intf.PRF_LOG_Q ),
    .OUT_DATA_WIDTH ( config_intf.ALU_WIDTH )
) i_kernel_data_splitter (
    .clk        ( data_intf.clk         ),
    .rst_n      ( data_intf.rst_n       ),
    .reset      ( config_intf.start     ),
    .en         ( splitter_en           ),
    .selector   ( kernel_selector_1     ),
    .dtype      ( config_intf.rs2.dtype ),
    .op_in      ( data_intf.op2_data    ),
    .op_out     ( kernel_data           )
);

systolic_array #(
    .ARRAY_WIDTH ( SA_WIDTH             ),
    .ARRAY_HEIGHT( SA_HEIGHT            ),
    .DATA_WIDTH  ( config_intf.ALU_WIDTH)
) array (
    .clk            ( data_intf.clk     ),
    .reset_n        ( config_intf.start ),
    .array_reset_n  ( array_reset_n     ),
    .en             (                   ),
    .dtype          ( ma_pkg::INT32     ),
    .a_array_input  ( matrix_data_sa    ),
    .b_array_input  ( kernel_data_sa    ),
    .c_array_output ( res_sa            )
);

genvar shifter_idx;

generate;
    for ( shifter_idx = 0; shifter_idx < SA_HEIGHT; shifter_idx = shifter_idx + 1 ) begin : shifter_generation
parallel_to_serial #(
    .SERIAL_DATA_WIDTH  ( config_intf.ALU_WIDTH ),
    .DEPTH              ( SA_HEIGHT             )
) i_matrix_data_shifter (
    .clk    ( data_intf.clk                     ),
    .rst_n  ( data_intf.rst_n                   ),
    .en     ( matrix_shifter_en[shifter_idx]    ),
    .clear  ( config_intf.start                 ),
    .load   ( matrix_shifter_load[shifter_idx]  ),
    .shift  ( matrix_shifter_shift[shifter_idx] ),
    .data_i ( matrix_data                       ),
    .data_o ( matrix_data_shifter[shifter_idx]  )
);

parallel_to_serial #(
    .SERIAL_DATA_WIDTH  ( config_intf.ALU_WIDTH ),
    .DEPTH              ( SA_HEIGHT             )
) i_mask_data_shifter (
    .clk    ( data_intf.clk                     ),
    .rst_n  ( data_intf.rst_n                   ),
    .en     ( matrix_shifter_en[shifter_idx]    ),
    .clear  ( config_intf.start                 ),
    .load   ( matrix_shifter_load[shifter_idx]  ),
    .shift  ( matrix_shifter_shift[shifter_idx] ),
    .data_i ( matrix_mask                       ),
    .data_o ( matrix_mask_shifter[shifter_idx]  )
);
    end
endgenerate

parallel_to_serial #(
    .SERIAL_DATA_WIDTH  ( config_intf.ALU_WIDTH ),
    .DEPTH              ( SA_HEIGHT             )
) i_kernel_data_shifter (
    .clk    ( data_intf.clk         ),
    .rst_n  ( data_intf.rst_n       ),
    .en     ( kernel_shifter_en     ),
    .clear  ( config_intf.start     ),
    .load   ( kernel_shifter_load   ),
    .shift  ( kernel_shifter_shift  ),
    .data_i ( kernel_data           ),
    .data_o ( kernel_data_shifter   )
);

parallel_to_serial #(
    .SERIAL_DATA_WIDTH  ( config_intf.ALU_WIDTH ),
    .DEPTH              ( SA_HEIGHT             )
) i_mask_data_shifter (
    .clk    ( data_intf.clk         ),
    .rst_n  ( data_intf.rst_n       ),
    .en     ( kernel_shifter_en     ),
    .clear  ( config_intf.start     ),
    .load   ( kernel_shifter_load   ),
    .shift  ( kernel_shifter_shift  ),
    .data_i ( kernel_mask           ),
    .data_o ( kernel_mask_shifter   )
);

endmodule