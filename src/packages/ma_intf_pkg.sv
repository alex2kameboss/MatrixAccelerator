package ma_intf_pkg;
    
typedef enum logic[3 : 0] { 
    CONTROL_UNIT    ,
    MEMORY          ,
    DMA_UNIT        ,
    VECTORIAL_UNIT  ,
    MATRIX_UNIT     ,
    CNV_UNIT        ,
    NEWTON_UNIT     ,
    FFT_UNIT        ,
    NTT_UNIT        ,
    NONE_MODULE               
} unit_id_t;

typedef enum logic[4 : 0] {
    // VECTOR-VECTOR
    ADD_VV      ,
    SUB_VV      ,
    CNV_VV      ,
    DIV_VV      ,
    MUL_VV      ,
    SMUL_VV     ,
    NEWTON_VV   ,
    BROADCAST_L ,
    BROADCAST_R ,
    // VECTOR-SCALAR
    ADD_VS      ,
    SUB_VS      ,
    DIV_VS      ,
    SLL_VS      ,
    SRL_VS      ,
    SRA_VS      ,
    MUL_VS      ,
    NEWTON_VS   ,
    // MEMORY
    LOAD        ,
    STORE       ,
    // FFT
    FFT         ,
    IFFT        ,
    NTT         ,
    NOP     
} internal_op_t;

endpackage