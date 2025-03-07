if { ![info exists PROJECT_ROOT] } {
    set PROJECT_ROOT [file dirname [file dirname [file dirname [file normalize [info script]]]]]
}

source ${PROJECT_ROOT}/scripts/common/common.tcl

set_property include_dirs [list \
    ${PROJECT_ROOT}/src/ips/axi/include \
    ${PROJECT_ROOT}/src/ips/common_cells/include \
    ${PROJECT_ROOT}/src/ips/poly_mem/2dprf_sv/src/includes \
    ${PROJECT_ROOT}/src/includes \
] [current_fileset]

# ips
    # cv xi if
add_files ${PROJECT_ROOT}/src/ips/cv-x-if/src/core_v_xif.sv
    # axi
add_files ${PROJECT_ROOT}/src/ips/axi/src/axi_intf.sv
add_files ${PROJECT_ROOT}/src/ips/axi/src/axi_pkg.sv
    # polymem
add_files [findFiles ${PROJECT_ROOT}/src/ips/poly_mem/2dprf_sv/src/rtl/ *.sv]
add_files [findFiles ${PROJECT_ROOT}/src/ips/poly_mem/2dprf_sv/src/packages/ *.sv]

# packages
add_files [findFiles ${PROJECT_ROOT}/src/packages/ *.sv]
# interfaces
add_files [findFiles ${PROJECT_ROOT}/src/interfaces/ *.sv]
# rtl
add_files [findFiles ${PROJECT_ROOT}/src/rtl/ *.sv]
# top 
add_files ${PROJECT_ROOT}/src/tests/vivado/matrix_accelerator_vivado.sv

update_compile_order -fileset sources_1