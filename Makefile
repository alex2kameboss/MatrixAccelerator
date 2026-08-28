bender:
	bender script -D VERILATOR ${ARGS} -D COMMON_CELLS_ASSERTS_OFF -t test_wo_core vsim > runs/sim/compile.tcl

vsim_simple: bender
	cd runs/sim ; \
	vsim -l log.log -do "vlib work; source compile.tcl; vsim work.tb_ma_ntt -suppress vsim-8315 -suppress vsim-3009 -voptargs=+acc"

vsim: ARGS=-D PRF_DOUBLE_FREQ
vsim: vsim_simple
