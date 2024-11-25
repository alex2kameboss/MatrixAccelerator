source ../scripts/axi_intf.tcl

set dirs {pkg async_fifo common cv_x_if dma matrix_acc}
foreach dir $dirs {
    vlog ../src/${dir}/*.sv
}

vlog ../src/matrix_accelerator.sv
