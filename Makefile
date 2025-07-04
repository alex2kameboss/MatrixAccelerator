bender:
	bender script -D VERILATOR -D PRF_DOUBLE_FREQ -D COMMON_CELLS_ASSERTS_OFF -t test_wo_core vsim > runs/sim/compile.tcl

vsim: bender
	cd runs/sim ; \
	vsim -c -l log.log -do "vlib work; source compile.tcl; vsim work.tb_ma_wo_core -suppress vsim-8315 +acc; run -all"
