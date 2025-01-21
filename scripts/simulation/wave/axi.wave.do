# set TOP variable
add wave -noupdate -divider $TOP/AW
add wave -noupdate -group $TOP/AW /$TOP/aw_addr
add wave -noupdate -group $TOP/AW /$TOP/aw_len
add wave -noupdate -group $TOP/AW /$TOP/aw_size
add wave -noupdate -group $TOP/AW /$TOP/aw_atop
add wave -noupdate -group $TOP/AW /$TOP/aw_burst
add wave -noupdate -group $TOP/AW /$TOP/aw_cache
add wave -noupdate -group $TOP/AW /$TOP/aw_id
add wave -noupdate -group $TOP/AW /$TOP/aw_lock
add wave -noupdate -group $TOP/AW /$TOP/aw_prot
add wave -noupdate -group $TOP/AW /$TOP/aw_qos
add wave -noupdate -group $TOP/AW /$TOP/aw_region
add wave -noupdate -group $TOP/AW /$TOP/aw_user
add wave -noupdate /$TOP/aw_valid
add wave -noupdate /$TOP/aw_ready

add wave -noupdate -divider $TOP/W
add wave -noupdate -group $TOP/W /$TOP/w_data
add wave -noupdate -group $TOP/W /$TOP/w_last
add wave -noupdate -group $TOP/W /$TOP/w_strb
add wave -noupdate -group $TOP/W /$TOP/w_user
add wave -noupdate /$TOP/w_valid
add wave -noupdate /$TOP/w_ready

add wave -noupdate -divider $TOP/B
add wave -noupdate -group $TOP/B /$TOP/b_id
add wave -noupdate -group $TOP/B /$TOP/b_resp
add wave -noupdate -group $TOP/B /$TOP/b_user
add wave -noupdate /$TOP/b_valid
add wave -noupdate /$TOP/b_ready

add wave -noupdate -divider $TOP/AR
add wave -noupdate -group $TOP/AR /$TOP/ar_addr
add wave -noupdate -group $TOP/AR /$TOP/ar_len
add wave -noupdate -group $TOP/AR /$TOP/ar_size
add wave -noupdate -group $TOP/AR /$TOP/ar_burst
add wave -noupdate -group $TOP/AR /$TOP/ar_cache
add wave -noupdate -group $TOP/AR /$TOP/ar_id
add wave -noupdate -group $TOP/AR /$TOP/ar_lock
add wave -noupdate -group $TOP/AR /$TOP/ar_prot
add wave -noupdate -group $TOP/AR /$TOP/ar_qos
add wave -noupdate -group $TOP/AR /$TOP/ar_region
add wave -noupdate -group $TOP/AR /$TOP/ar_user
add wave -noupdate /$TOP/ar_valid
add wave -noupdate /$TOP/ar_ready

add wave -noupdate -divider $TOP/R
add wave -noupdate -group $TOP/R /$TOP/r_data
add wave -noupdate -group $TOP/R /$TOP/r_id
add wave -noupdate -group $TOP/R /$TOP/r_last
add wave -noupdate -group $TOP/R /$TOP/r_resp
add wave -noupdate -group $TOP/R /$TOP/r_user
add wave -noupdate /$TOP/r_valid
add wave -noupdate /$TOP/r_ready
