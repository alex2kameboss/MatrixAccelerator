cd [file dirname [file normalize [info script]]]/runs/sim

source ../../scripts/common/set_project_path.tcl
source ../../scripts/simulation/compile.tcl
vsim work.tb_ma_wo_core
run -all