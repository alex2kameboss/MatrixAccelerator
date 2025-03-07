module ma_rsp_intf_arbiter #(
    parameter   NUMBER_OF_UNITS =   3
) (
    ma_config_bus.arbiter   config_intf                             ,
    ma_rsp_intf.accelerator rsp_intf_out                            ,
    ma_rsp_intf.control     rsp_intf_in [ NUMBER_OF_UNITS - 1 : 0 ] 
);
    
wor done;

assign rsp_intf_out.done = done;

genvar i;
generate
    for ( i = 0; i < NUMBER_OF_UNITS; i = i + 1 ) begin : assign_done
        assign done = config_intf.dst_unit == rsp_intf_in[i].unit_id & rsp_intf_in[i].done;
    end
endgenerate

endmodule