if { ![info exists PROJECT_ROOT] } {
    puts "Source scripts/common/set_project_path.tcl!"
    return
}

puts "Source compile script"
source ${PROJECT_ROOT}/scripts/common/common.tcl

vlib work

set include "+incdir+${PROJECT_ROOT}/src/includes"

# compile packages
foreach file [findFiles ${PROJECT_ROOT}/src/packages/ *.sv] {
    vlog $include $file
}
# compile interfaces
foreach file [findFiles ${PROJECT_ROOT}/src/interfaces/ *.sv] {
    vlog $include $file
}
# compile ips
source ${PROJECT_ROOT}/scripts/simulation/ips.tcl
# compile rtl
foreach file [findFiles ${PROJECT_ROOT}/src/rtl/ *.sv] {
    vlog $include $file
}
foreach file [findFiles ${PROJECT_ROOT}/src/rtl/ *.v] {
    vlog $include $file
}
foreach file [findFiles ${PROJECT_ROOT}/src/rtl/ *.vhd] {
    vlog $file
}
# compile tests
foreach file [findFiles ${PROJECT_ROOT}/src/tests/ *.sv] {
    vlog +incdir+${PROJECT_ROOT}/src/ips/axi/include/ $include $file
}
foreach file [findFiles ${PROJECT_ROOT}/src/tests/ *.v] {
    vlog $include $file
}
