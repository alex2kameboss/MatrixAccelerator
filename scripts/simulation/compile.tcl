if { ![info exists PROJECT_ROOT] } {
    puts "Source scripts/common/set_project_path.tcl!"
    return
}

puts "Source compile script"
source ${PROJECT_ROOT}/scripts/common/common.tcl

vlib work

set include "+incdir+${PROJECT_ROOT}/src/include"

# compile packages
foreach file [findFiles ${PROJECT_ROOT}/src/package/ *.sv] {
    vlog $include $file
}
# compile interfaces
foreach file [findFiles ${PROJECT_ROOT}/src/interface/ *.sv] {
    vlog $include $file
}
# compile ips
source ${PROJECT_ROOT}/scripts/simulation/ip.tcl
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
foreach file [findFiles ${PROJECT_ROOT}/src/test/ *.sv] {
    vlog +incdir+${PROJECT_ROOT}/src/ip/axi/include/ $include $file
}
foreach file [findFiles ${PROJECT_ROOT}/src/test/ *.v] {
    vlog $include $file
}
