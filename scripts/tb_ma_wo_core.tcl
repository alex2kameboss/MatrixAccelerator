source ../scripts/ma.tcl
vlog ../test/clk_rstn.sv
vlog ../src/riscv_pkg.sv
vlog ../src/matrix_accelerator.sv
vlog ../external/cv-x-if/src/core_v_xif.sv
vlog ../src/cv_x_if/extension_driver.sv

if {![info exists dependecies]} {
    set dependecies 1

    vlog ../external/common_cells/src/cf_math_pkg.sv +incdir+../external/common_cells/include
    vlog ../external/common_cells/src/spill_register.sv +incdir+../external/common_cells/include
    vlog ../external/axi/src/axi_pkg.sv +incdir+../external/axi/include

    set modules {axi_mux axi_demux axi_demux_simple axi_err_slv axi_multicut axi_atop_filter axi_cut axi_id_prepend}
    foreach module $modules {
        vlog ../external/axi/src/${module}.sv +incdir+../external/axi/include +incdir+../external/common_cells/include
    }

    vlog ../external/axi/src/axi_xbar_unmuxed.sv +incdir+../external/axi/include
    vlog ../external/axi/src/axi_xbar.sv +incdir+../external/axi/include
    vlog ../external/axi/src/axi_sim_mem.sv +incdir+../external/axi/include
}

vlog ../src/matrix_acc/*.sv
vlog ../src/posedge_detector.sv
vlog ../test/tb_ma_wo_core.sv +incdir+../external/axi/include