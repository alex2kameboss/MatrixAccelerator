set PROJECT_ROOT [file dirname [file dirname [file dirname [file normalize [info script]]]]]
set PROJECT_NAME "run_[clock format [clock seconds] -format {%d-%m-%Y-%H%M%S}]"

create_project ${PROJECT_NAME} ${PROJECT_ROOT}/runs/ -part xcvu37p-fsvh2892-2L-e
set_property board_part xilinx.com:vcu128:part0:1.0 [current_project]

source ${PROJECT_ROOT}/scripts/vivado/add_files.tcl