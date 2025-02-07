# Matrix Accelerator

## Software

1. QuestaSim

## Usage

1. Create *sim* folder inside *runs* folder
1. Open QuestaSim inside *runs/sim*
1. Run following commands to run the test

```tcl
source ../../scripts/common/set_project_path.tcl
source ../../scripts/simulation/compile.tcl
vsim work.tb_ma_wo_core
run -all
```