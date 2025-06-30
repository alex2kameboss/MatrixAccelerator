module matrix_accelerator #(
    parameter OPCODE            =   7'h2B   ,
    parameter DMA_DATA_WIDTH    =   64      ,
    parameter ADDR_WIDTH        =   32      ,
    parameter REGISTER_NUMBERS  =   32      ,
    parameter PRF_LOG_P         =   1       ,
    parameter PRF_LOG_Q         =   2       ,
    parameter PRF_LOG_N         =   10      ,
    parameter PRF_LOG_M         =   10      
) (
    // generic signals
    input                                       clk             ,
    input                                       clk_2x          ,
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

localparam ALU_WIDTH = 32;

enum logic [2 : 0] {
    MEMORY          ,
    DMA             ,
    VECTOR          ,
    MATRIX          ,
    CNV             ,
    NUMBER_OF_UNITS
} units_t;

// interfaces
ma_config_bus #(
    .ALU_WIDTH  ( ALU_WIDTH )
) config_intf();

ma_rsp_intf rsp_intf[NUMBER_OF_UNITS - 1 : 0]();

ma_data_bus #(
    .PRF_LOG_P  ( PRF_LOG_P ),
    .PRF_LOG_Q  ( PRF_LOG_Q ),
    .PRF_LOG_N  ( PRF_LOG_N ),
    .PRF_LOG_M  ( PRF_LOG_M ),
    .SRAM_WIDTH ( ALU_WIDTH )
) data_intf[NUMBER_OF_UNITS - 1 : 0] ( 
    .clk    ( clk   ),
    .rst_n  ( rst_n )
); // one for every units + 1 for memory

// wires
logic                                                   valid ;
logic                                                   ready ;
ma_pkg::funct3_op_t                                     funct3;
ma_pkg::operation_t                                     op    ;
logic               [ADDR_WIDTH - 1 : 0]                addr  ;
logic               [ADDR_WIDTH - 1 : 0]                scalar;
logic               [$clog2(REGISTER_NUMBERS) - 1 : 0]  rd    ;
logic               [$clog2(REGISTER_NUMBERS) - 1 : 0]  rs1   ;
logic               [$clog2(REGISTER_NUMBERS) - 1 : 0]  rs2   ;
logic               [ADDR_WIDTH - 1 : 0]                reg1  ;
logic               [ADDR_WIDTH - 1 : 0]                reg2  ;
logic               [6 : 0]                             funct7;

// instances
ma_decoder #(
    .OPCODE             ( OPCODE            ),
    .ADDR_WIDTH         ( ADDR_WIDTH        ),
    .REGISTER_NUMBERS   ( REGISTER_NUMBERS  )
) i_decoder (
    .clk             ( clk          ),
    .rst_n           ( rst_n        ),
    .instr_if        ( instr_if     ),
    .registers_if    ( registers_if ),
    .commit_if       ( commit_if    ),
    .result_if       ( result_if    ),
    .valid           ( valid        ),
    .ready           ( ready        ),
    .funct3          ( funct3       ),                    
    .op              ( op           ),
    .addr            ( addr         ),
    .scalar          ( scalar       ),
    .rd              ( rd           ),
    .rs1             ( rs1          ),
    .rs2             ( rs2          ),
    .reg1            ( reg1         ),
    .reg2            ( reg2         ),
    .funct7          ( funct7       )  
);

ma_control_unit #(
    .ADDR_WIDTH         ( ADDR_WIDTH        ),
    .REGISTER_NUMBERS   ( REGISTER_NUMBERS  )
) i_control_unit (
    .clk            ( clk               ),
    .rst_n          ( rst_n             ),
    .config_intf    ( config_intf       ),
    .rsp_intf       ( rsp_intf[MEMORY]  ),
    .valid          ( valid             ),
    .ready          ( ready             ),
    .funct3         ( funct3            ),
    .op             ( op                ),
    .addr           ( addr              ),
    .scalar         ( scalar            ),
    .rd             ( rd                ),
    .rs1            ( rs1               ),
    .rs2            ( rs2               ),
    .reg1           ( reg1              ),
    .reg2           ( reg2              ),
    .funct7         ( funct7            )          
);

ma_dma i_dma_unit (
    .config_intf ( config_intf      ),
    .data_intf   ( data_intf[DMA]   ),
    .rsp_intf    ( rsp_intf[DMA]    ),
    .aclk        ( aclk             ),
    .arst_n      ( arst_n           ),
    .axi         ( axi              )
);

ma_vectorial_unit i_vectorial_unit (
    .config_intf ( config_intf          ),
    .data_intf   ( data_intf[VECTOR]    ),
    .rsp_intf    ( rsp_intf[VECTOR]     )
);

ma_matrix_unit i_matrix_unit (
    .config_intf ( config_intf          ),
    .data_intf   ( data_intf[MATRIX]    ),
    .rsp_intf    ( rsp_intf[MATRIX]     )
);

ma_convolution_unit i_convolution_unit (
    .config_intf    ( config_intf   ),
    .data_intf      ( data_intf[CNV]),
    .rsp_intf       ( rsp_intf[CNV] )
);

ma_memory i_memory (
    .clk_2x ( clk_2x            ),
    .intf   ( data_intf[MEMORY] )
);

ma_data_bus_arbiter i_memory_arbiter (
    .control    ( config_intf       ),
    .mem_intf   ( data_intf[MEMORY] ),
    .dma_intf   ( data_intf[DMA]    ),
    .vu_intf    ( data_intf[VECTOR] ),
    .mu_intf    ( data_intf[MATRIX] ),
    .cu_intf    ( data_intf[CNV]    )
);

ma_rsp_intf_arbiter #(
    .NUMBER_OF_UNITS    ( NUMBER_OF_UNITS - 1   )
) i_rsp_arbiter (
    .config_intf    ( config_intf                       ),
    .rsp_intf_out   ( rsp_intf[MEMORY]                  ),
    .rsp_intf_in    ( rsp_intf[NUMBER_OF_UNITS - 1 : 1] )
);

endmodule