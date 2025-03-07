module ma_memory (
    ma_data_bus.memory  intf    
);

// Local Parameters Definition  ------------------------------------------------------------------------------
localparam PRF_N_RPORTS  = 2 ;
localparam PRF_N_WPORTS  = 1 ;


// Wires Definition ------------------------------------------------------------------------------------------
logic                   [intf.SRAM_WIDTH - 1 : 0]   prf_data_in     [0 : PRF_N_WPORTS - 1][0 : intf.PRF_N_LANES - 1]    ;
logic                                               prf_read        [0 : PRF_N_RPORTS - 1]                              ;
logic                                               prf_write       [0 : PRF_N_RPORTS - 1]                              ;
logic                   [intf.PRF_LOG_N - 1 : 0]    read_i          [0 : PRF_N_RPORTS - 1]                              ;
logic                   [intf.PRF_LOG_M - 1 : 0]    read_j          [0 : PRF_N_RPORTS - 1]                              ;
logic                   [intf.PRF_LOG_N - 1 : 0]    write_i         [0 : PRF_N_WPORTS - 1]                              ;
logic                   [intf.PRF_LOG_M - 1 : 0]    write_j         [0 : PRF_N_WPORTS - 1]                              ;
prf_dtypes::dscheme_t                               dscheme                                                             ;
prf_dtypes::taccess_t   [PRF_N_RPORTS - 1 : 0]      taccess_read                                                        ;
prf_dtypes::taccess_t   [PRF_N_WPORTS - 1 : 0]      taccess_write                                                       ;
logic                   [intf.SRAM_WIDTH - 1 : 0]   prf_data_out_r  [0 : PRF_N_RPORTS - 1][0 : intf.PRF_N_LANES - 1]    ;
logic                   [intf.SRAM_WIDTH - 1 : 0]   prf_data_out_w  [0 : PRF_N_RPORTS - 1][0 : intf.PRF_N_LANES - 1]    ;


// Combinatorial Logic ---------------------------------------------------------------------------------------
assign dscheme = prf_dtypes::ROW_COL;
// rez
assign taccess_write[0] = intf.rez.scheme;
assign prf_write[1] = ~intf.rez.valid;
assign write_i[0] = intf.rez.i;
assign write_j[0] = intf.rez.j;
// op1
assign taccess_read[0] = intf.op1.scheme;
assign prf_read[1] = ~intf.op1.valid; // wtf, read 1 for port 0
assign read_i[0] = intf.op1.i;
assign read_j[0] = intf.op1.j;
// op2
assign taccess_read[1] = intf.op2.scheme;
assign prf_read[0] = ~intf.op2.valid; // wtf, read 0 for port 1
assign read_i[1] = intf.op2.i;
assign read_j[1] = intf.op2.j;

genvar i;
generate
    for ( i = 0; i < intf.PRF_N_LANES; i = i + 1 ) begin : data_assign
        assign prf_data_in[0][i] = intf.rez_data[(i + 1) * intf.SRAM_WIDTH - 1 : i * intf.SRAM_WIDTH];
        assign intf.op1_data[(i + 1) * intf.SRAM_WIDTH - 1 : i * intf.SRAM_WIDTH] = prf_data_out_r[0][i];
        assign intf.op2_data[(i + 1) * intf.SRAM_WIDTH - 1 : i * intf.SRAM_WIDTH] = prf_data_out_r[1][i];
    end
endgenerate


// Sequential Logic ------------------------------------------------------------------------------------------



// Modules Instances -----------------------------------------------------------------------------------------
prf2d_wrapper #(
    .prf_n_rports  ( PRF_N_RPORTS   ), 
    .prf_n_wports  ( PRF_N_WPORTS   ), 
    .sram_width    ( intf.SRAM_WIDTH),
    .prf_log_p     ( intf.PRF_LOG_P ),
    .prf_log_q     ( intf.PRF_LOG_Q ),
    .prf_log_n     ( intf.PRF_LOG_N ),
    .prf_log_m     ( intf.PRF_LOG_M )
) i_mem (
    .clk            ( intf.clk       ),  
    .prf_data_in    ( prf_data_in    ),
    .prf_read       ( prf_read       ),
    .prf_write      ( prf_write      ),
    .read_i         ( read_i         ),
    .read_j         ( read_j         ),
    .write_i        ( write_i        ),
    .write_j        ( write_j        ),
    .dscheme        ( dscheme        ),
    .taccess_read   ( taccess_read   ),
    .taccess_write  ( taccess_write  ),
    .prf_data_out_r ( prf_data_out_r ),
    .prf_data_out_w ( prf_data_out_w ) 
);

endmodule