module ma_data_bus_arbiter (
    ma_config_bus.arbiter   control     ,
    ma_data_bus.accelerator mem_intf    ,
    ma_data_bus.memory      dma_intf    ,
    ma_data_bus.memory      vu_intf     ,
    ma_data_bus.memory      mu_intf     ,
    ma_data_bus.memory      cu_intf     ,
    ma_data_bus.memory      fft_intf     
);

always_comb begin
    unique case ( control.dst_unit )
        ma_intf_pkg::DMA_UNIT : begin
            mem_intf.rez       = dma_intf.rez     ;
            mem_intf.op1       = dma_intf.op1     ;
            mem_intf.op2       = dma_intf.op2     ;
            mem_intf.rez_data  = dma_intf.rez_data;
        end
        ma_intf_pkg::VECTORIAL_UNIT : begin
            mem_intf.rez       = vu_intf.rez     ;
            mem_intf.op1       = vu_intf.op1     ;
            mem_intf.op2       = vu_intf.op2     ;
            mem_intf.rez_data  = vu_intf.rez_data;
        end
        ma_intf_pkg::MATRIX_UNIT : begin
            mem_intf.rez       = mu_intf.rez     ;
            mem_intf.op1       = mu_intf.op1     ;
            mem_intf.op2       = mu_intf.op2     ;
            mem_intf.rez_data  = mu_intf.rez_data;
        end
        ma_intf_pkg::CNV_UNIT : begin
            mem_intf.rez       = cu_intf.rez     ;
            mem_intf.op1       = cu_intf.op1     ;
            mem_intf.op2       = cu_intf.op2     ;
            mem_intf.rez_data  = cu_intf.rez_data;
        end
        ma_intf_pkg::FFT_UNIT : begin
            mem_intf.rez       = fft_intf.rez     ;
            mem_intf.op1       = fft_intf.op1     ;
            mem_intf.op2       = fft_intf.op2     ;
            mem_intf.rez_data  = fft_intf.rez_data;
        end
        ma_intf_pkg::NONE_MODULE: begin
                mem_intf.rez        = 'd0;
                mem_intf.op1        = 'd0;
                mem_intf.op2        = 'd0;
                mem_intf.rez_data   = 'd0;
        end
    endcase
end

assign mu_intf.op1_data  = mem_intf.op1_data;
assign mu_intf.op2_data  = mem_intf.op2_data;
assign vu_intf.op1_data  = mem_intf.op1_data;
assign vu_intf.op2_data  = mem_intf.op2_data;
assign dma_intf.op1_data = mem_intf.op1_data;
assign dma_intf.op2_data = mem_intf.op2_data;
assign cu_intf.op1_data = mem_intf.op1_data;
assign cu_intf.op2_data = mem_intf.op2_data;
assign fft_intf.op1_data = mem_intf.op1_data;
assign fft_intf.op2_data = mem_intf.op2_data;

endmodule