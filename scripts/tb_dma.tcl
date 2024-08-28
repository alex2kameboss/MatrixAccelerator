source ../scripts/dma.tcl
vlog ../test/clk_rstn.sv
vlog ../external/axi/src/axi_sim_mem.sv +incdir+../external/axi/include
vlog ../test/tb_dma.sv +incdir+../external/axi/include