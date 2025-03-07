module ma_data_bus_arbiter (
    ma_config_bus.arbiter   control     ,
    ma_data_bus.accelerator mem_intf    ,
    ma_data_bus.memory      dma_intf    ,
    ma_data_bus.memory      vu_intf     ,
    ma_data_bus.memory      mu_intf     
);

int i, j;

always_comb begin
    case ( control.dst_unit )
        ma_intf_pkg::DMA_UNIT : begin
            mem_intf.rez       = dma_intf.rez     ;
            mem_intf.op1       = dma_intf.op1     ;
            mem_intf.op2       = dma_intf.op2     ;
            mem_intf.rez_data  = dma_intf.rez_data;

            dma_intf.op1_data  = mem_intf.op1_data;
            dma_intf.op2_data  = mem_intf.op2_data;
        end
        ma_intf_pkg::VECTORIAL_UNIT : begin
            mem_intf.rez       = vu_intf.rez     ;
            mem_intf.op1       = vu_intf.op1     ;
            mem_intf.op2       = vu_intf.op2     ;
            mem_intf.rez_data  = vu_intf.rez_data;

            vu_intf.op1_data  = mem_intf.op1_data;
            vu_intf.op2_data  = mem_intf.op2_data;
        end
        ma_intf_pkg::MATRIX_UNIT : begin
            mem_intf.rez       = mu_intf.rez     ;
            mem_intf.op1       = mu_intf.op1     ;
            mem_intf.op2       = mu_intf.op2     ;
            mem_intf.rez_data  = mu_intf.rez_data;

            mu_intf.op1_data  = mem_intf.op1_data;
            mu_intf.op2_data  = mem_intf.op2_data;
        end
        default: begin
                mem_intf.rez.valid  = 'd0;
                mem_intf.rez.i      = 'd0;
                mem_intf.rez.j      = 'd0;
                mem_intf.rez.scheme = prf_dtypes::ROW;
                mem_intf.op1.valid  = 'd0;
                mem_intf.op1.i      = 'd0;
                mem_intf.op1.j      = 'd0;
                mem_intf.op1.scheme = prf_dtypes::ROW;
                mem_intf.op2.valid  = 'd0;
                mem_intf.op2.i      = 'd0;
                mem_intf.op2.j      = 'd0;
                mem_intf.op2.scheme = prf_dtypes::ROW;
                mem_intf.rez_data   = 'd0;
        end
    endcase
end

endmodule