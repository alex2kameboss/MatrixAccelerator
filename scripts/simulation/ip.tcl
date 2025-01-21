puts "Source ip compile script"

if {![info exists IPS]} {
    set IPS 1

    # cv-x-if
    vlog ${PROJECT_ROOT}/src/ip/cv-x-if/src/core_v_xif.sv

    # axi
    vlog ${PROJECT_ROOT}/src/ip/axi/src/axi_pkg.sv +incdir+${PROJECT_ROOT}/src/ip/axi/include
    vlog ${PROJECT_ROOT}/src/ip/axi/src/axi_intf.sv +incdir+${PROJECT_ROOT}/src/ip/axi/include
    vlog ${PROJECT_ROOT}/src/ip/common_cells/src/cf_math_pkg.sv +incdir+${PROJECT_ROOT}/src/ip/common_cells/include
    vlog ${PROJECT_ROOT}/src/ip/common_cells/src/spill_register.sv +incdir+${PROJECT_ROOT}/src/ip/common_cells/include
    vlog ${PROJECT_ROOT}/src/ip/axi/src/axi_pkg.sv +incdir+${PROJECT_ROOT}/src/ip/axi/include

    set modules {axi_mux axi_demux axi_demux_simple axi_err_slv axi_multicut axi_atop_filter axi_cut axi_id_prepend}
    foreach module $modules {
        vlog ${PROJECT_ROOT}/src/ip/axi/src/${module}.sv +incdir+${PROJECT_ROOT}/src/ip/axi/include +incdir+${PROJECT_ROOT}/src/ip/common_cells/include
    }

    vlog ${PROJECT_ROOT}/src/ip/axi/src/axi_xbar_unmuxed.sv +incdir+${PROJECT_ROOT}/src/ip/axi/include
    vlog ${PROJECT_ROOT}/src/ip/axi/src/axi_xbar.sv +incdir+${PROJECT_ROOT}/src/ip/axi/include
    vlog ${PROJECT_ROOT}/src/ip/axi/src/axi_sim_mem.sv +incdir+${PROJECT_ROOT}/src/ip/axi/include
}