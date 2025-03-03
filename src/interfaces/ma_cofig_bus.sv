interface ma_config_bus #(
    parameter   ALU_WIDTH   =   32  
);
    
ma_intf_pkg::unit_id_t                              dst_unit;
ma_pkg::register_file_line_t                        rs1;
ma_pkg::register_file_line_t                        rs2;
ma_pkg::register_file_line_t                        rd;
logic                                               start;
logic                           [ALU_WIDTH - 1 : 0] scalar;

modport control (
    output  dst_unit,
            rs1     ,
            rs2     ,
            rd      ,
            start   ,
            scalar  
);

modport accelerator (
    input   dst_unit,
            rs1     ,
            rs2     ,
            rd      ,
            start   ,
            scalar  
);

modport arbiter (
    input   dst_unit,
            rs1     ,
            rs2     ,
            rd      ,
            start   ,
            scalar  
);

endinterface //ma_config_bus