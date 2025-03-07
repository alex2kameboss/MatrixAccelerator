interface ma_rsp_intf;
    
ma_intf_pkg::unit_id_t  unit_id;
logic                   done;

modport control (
    output  unit_id ,
    input   done    
);

modport accelerator (
    output  unit_id ,
            done    
);

endinterface //ma_rsp_intf