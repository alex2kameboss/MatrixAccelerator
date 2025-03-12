bender:
	bender script -t test_wo_core vsim > runs/sim/compile.tcl

vsim: bender
	cd runs/sim ; vsim -do "vlib work; source compile.tcl; vsim work.tb_ma_wo_core; run -all"