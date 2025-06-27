package ma_intf_pkg;
    
typedef enum logic[2 : 0] { 
    CONTROL_UNIT    ,
    MEMORY          ,
    DMA_UNIT        ,
    VECTORIAL_UNIT  ,
    MATRIX_UNIT     ,
    CNV_UNIT        ,
    NONE_MODULE               
} unit_id_t;

typedef enum logic[3 : 0] {
    // VECTOR-VECTOR
    ADD_VV  ,
    SUB_VV  ,
    CNV_VV  ,
    DIV_VV  ,
    MUL_VV  ,
    SMUL_VV ,
    // VECTOR-SCALAR
    ADD_VS  ,
    SUB_VS  ,
    DIV_VS  ,
    MUL_VS  ,
    // MEMORY
    LOAD    ,
    STORE   ,
    NOP     
} internal_op_t;

endpackage