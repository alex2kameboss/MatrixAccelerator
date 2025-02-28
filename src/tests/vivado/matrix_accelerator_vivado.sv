module matrix_accelerator_vivado #(
    parameter OPCODE            =   7'h2B   ,
    parameter ADDR_WIDTH        =   32      ,
    parameter REGISTER_NUMBERS  =   32      ,
    parameter PRF_LOG_P         =   1       ,
    parameter PRF_LOG_Q         =   2       ,
    parameter PRF_LOG_N         =   8       ,
    parameter PRF_LOG_M         =   8       
) (
    input   clk     ,
    input   rst_n   
);

localparam DATA_WIDTH   = 32'd32 * 2 ** (PRF_LOG_P + PRF_LOG_Q);

core_v_xif #(
    .X_NUM_RS              ( 2  ),
    .X_ID_WIDTH            ( 4  ),
    .X_RFR_WIDTH           ( 32 ),
    .X_RFW_WIDTH           ( 32 ),
    .X_NUM_HARTS           ( 1  ),
    .X_HARTID_WIDTH        ( 1  ),
    .X_MISA                ( '0 ),
    .X_DUALREAD            ( 0  ),
    .X_DUALWRITE           ( 0  ),
    .X_ISSUE_REGISTER_SPLIT( 0  ),
    .X_MEM_WIDTH           ( 32 ) 
) xif ();

AXI_BUS #(
  .AXI_ADDR_WIDTH ( ADDR_WIDTH  ),
  .AXI_DATA_WIDTH ( DATA_WIDTH  ),
  .AXI_ID_WIDTH   ( 32'd5       ),
  .AXI_USER_WIDTH ( 32'd5       )
) axi ();

matrix_accelerator #(
    .OPCODE             ( OPCODE            ),
    .ADDR_WIDTH         ( ADDR_WIDTH        ),
    .REGISTER_NUMBERS   ( REGISTER_NUMBERS  ),
    .PRF_LOG_P          ( PRF_LOG_P         ),
    .PRF_LOG_Q          ( PRF_LOG_Q         ),
    .PRF_LOG_N          ( PRF_LOG_N         ),
    .PRF_LOG_M          ( PRF_LOG_M         )
) i_ma (
    .clk            ( clk   ),
    .rst_n          ( rst_n ),
    .instr_if       ( xif   ),
    .registers_if   ( xif   ),
    .commit_if      ( xif   ),
    .result_if      ( xif   ),
    .aclk           ( clk   ),
    .arst_n         ( rst_n ),
    .axi            ( axi   )
);

endmodule