module matrix_acclerator #(
    parameter OPCODE            =   7'h2B   ,
    parameter ADDR_WIDTH        =   32      ,
    parameter REGISTER_NUMBERS  =   32      ,
    parameter PRF_LOG_P         =   1       ,
    parameter PRF_LOG_Q         =   2       ,
    parameter PRF_LOG_N         =   10      ,
    parameter PRF_LOG_M         =   10      
) (
    // generic signals
    input                                       clk             ,
    input                                       rst_n           ,
    // xif interface
    core_v_xif.core_v_xif_coprocessor_issue     instr_if        ,
    core_v_xif.core_v_xif_coprocessor_register  registers_if    ,
    core_v_xif.core_v_xif_coprocessor_commit    commit_if       ,
    core_v_xif.core_v_xif_coprocessor_result    result_if       ,
    // axi interface
    input                                       aclk            ,
    input                                       arst_n          ,
    AXI_BUS.Master                              axi             
);
    
logic                                                   valid    ;
logic                                                   ready    ;
logic                                                   arth_data;   // 1 arithmetic operation, 0 data operation
logic                                                   define   ;   // 1 define register, 0 memory operation
logic                                                   ld_st    ;   // 1 load, 0 store
logic               [ADDR_WIDTH - 1 : 0]                addr     ;
ma_pkg::operation_t                                     op       ;
logic                                                   scalar_op;
logic               [ADDR_WIDTH - 1 : 0]                scalar   ;
logic               [$clog2(REGISTER_NUMBERS) - 1 : 0]  rd       ;
logic               [$clog2(REGISTER_NUMBERS) - 1 : 0]  rs1      ;
logic               [$clog2(REGISTER_NUMBERS) - 1 : 0]  rs2      ;
logic               [ADDR_WIDTH - 1 : 0]                width    ;
logic               [ADDR_WIDTH - 1 : 0]                height   ;
ma_pkg::dtype_t                                         dtype    ; 

extension_driver #(
    .OPCODE            ( OPCODE             ),
    .ADDR_WIDTH        ( ADDR_WIDTH         ),
    .REGISTER_NUMBERS  ( REGISTER_NUMBERS   )
) i_xif (
    .clk            ( clk           ),
    .rst_n          ( rst_n         ),
    .instr_if       ( instr_if      ),
    .registers_if   ( registers_if  ),
    .commit_if      ( commit_if     ),
    .result_if      ( result_if     ),
    .valid          ( valid         ),
    .ready          ( ready         ),
    .arth_data      ( arth_data     ),   // 1 arithmetic operation, 0 data operation
    .define         ( define        ),   // 1 define register, 0 memory operation
    .ld_st          ( ld_st         ),   // 1 load, 0 store
    .addr           ( addr          ),
    .op             ( op            ),
    .scalar_op      ( scalar_op     ),
    .scalar         ( scalar        ),
    .rd             ( rd            ),
    .rs1            ( rs1           ),
    .rs2            ( rs2           ),
    .width          ( width         ),
    .height         ( height        ),
    .dtype          ( dtype         )  
);

ma_data_path #(
    .ADDR_WIDTH        ( ADDR_WIDTH         ),
    .REGISTER_NUMBERS  ( REGISTER_NUMBERS   ),
    .PRF_LOG_P         ( PRF_LOG_P          ),
    .PRF_LOG_Q         ( PRF_LOG_Q          ),
    .PRF_LOG_N         ( PRF_LOG_N          ), 
    .PRF_LOG_M         ( PRF_LOG_M          ) 
) i_data_path (
    .aclk       ( aclk      ),
    .arst_n     ( arst_n    ),
    .axi        ( axi       ),
    .clk        ( clk       ),
    .rst_n      ( rst_n     ),
    .valid      ( valid     ),
    .ready      ( ready     ),
    .arth_data  ( arth_data ),   // 1 arithmetic operation, 0 data operation
    .define     ( define    ),   // 1 define register, 0 memory operation
    .ld_st      ( ld_st     ),   // 1 load, 0 store
    .addr       ( addr      ),
    .op         ( op        ),
    .scalar_op  ( scalar_op ),
    .scalar     ( scalar    ),
    .rd         ( rd        ),
    .rs1        ( rs1       ),
    .rs2        ( rs2       ),
    .width      ( width     ),
    .height     ( height    ),
    .dtype      ( dtype     )               
);

endmodule