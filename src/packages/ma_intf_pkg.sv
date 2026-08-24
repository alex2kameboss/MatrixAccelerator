package ma_intf_pkg;
    
typedef enum logic[4 : 0] { 
    DMA_UNIT            ,
    VECTORIAL_UNIT      ,
    MATRIX_UNIT         ,
    CNV_UNIT            ,
    NEWTON_UNIT         ,
    FFT_UNIT            ,
    COMPLEX_MULT_UNIT   ,
    NTT_REAL_UNIT       ,
    NTT_COMPLEX_UNIT    ,         
    INTT_COMPLEX_UNIT   ,
    INTT_REAL_UNIT      ,
    MEMORY              ,
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
    // NTT
    NTT_R       ,
    NTT_C       ,
    INTT_C      ,
    INTT_R      ,
    CM          , // complex mult
    CMC         , // complex mult with conjugate
    NOP     
} internal_op_t;

endpackage