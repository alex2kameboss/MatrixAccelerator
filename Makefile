bender:
	bender script -D PRF_DOUBLE_FREQ -t test_wo_core vsim > runs/sim/compile.tcl

vsim: bender
	cd runs/sim ; vsim -do "vlib work; source compile.tcl; vsim work.tb_ma_wo_core -suppress vsim-8315; run -all"