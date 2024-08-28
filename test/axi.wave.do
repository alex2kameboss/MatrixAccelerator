# set TOP variable
add wave -noupdate -divider AW
add wave -noupdate -group AW /$TOP/axi/aw_addr
add wave -noupdate -group AW /$TOP/axi/aw_len
add wave -noupdate -group AW /$TOP/axi/aw_size
add wave -noupdate -group AW /$TOP/axi/aw_atop
add wave -noupdate -group AW /$TOP/axi/aw_burst
add wave -noupdate -group AW /$TOP/axi/aw_cache
add wave -noupdate -group AW /$TOP/axi/aw_id
add wave -noupdate -group AW /$TOP/axi/aw_lock
add wave -noupdate -group AW /$TOP/axi/aw_prot
add wave -noupdate -group AW /$TOP/axi/aw_qos
add wave -noupdate -group AW /$TOP/axi/aw_region
add wave -noupdate -group AW /$TOP/axi/aw_user
add wave -noupdate /$TOP/axi/aw_valid
add wave -noupdate /$TOP/axi/aw_ready

add wave -noupdate -divider W
add wave -noupdate -group W /$TOP/axi/w_data
add wave -noupdate -group W /$TOP/axi/w_last
add wave -noupdate -group W /$TOP/axi/w_strb
add wave -noupdate -group W /$TOP/axi/w_user
add wave -noupdate /$TOP/axi/w_valid
add wave -noupdate /$TOP/axi/w_ready

add wave -noupdate -divider B
add wave -noupdate -group B /$TOP/axi/b_id
add wave -noupdate -group B /$TOP/axi/b_resp
add wave -noupdate -group B /$TOP/axi/b_user
add wave -noupdate /$TOP/axi/b_valid
add wave -noupdate /$TOP/axi/b_ready

add wave -noupdate -divider AR
add wave -noupdate -group AR /$TOP/axi/ar_addr
add wave -noupdate -group AR /$TOP/axi/ar_len
add wave -noupdate -group AR /$TOP/axi/ar_size
add wave -noupdate -group AR /$TOP/axi/ar_burst
add wave -noupdate -group AR /$TOP/axi/ar_cache
add wave -noupdate -group AR /$TOP/axi/ar_id
add wave -noupdate -group AR /$TOP/axi/ar_lock
add wave -noupdate -group AR /$TOP/axi/ar_prot
add wave -noupdate -group AR /$TOP/axi/ar_qos
add wave -noupdate -group AR /$TOP/axi/ar_region
add wave -noupdate -group AR /$TOP/axi/ar_user
add wave -noupdate /$TOP/axi/ar_valid
add wave -noupdate /$TOP/axi/ar_ready

add wave -noupdate -divider R
add wave -noupdate -group R /$TOP/axi/r_data
add wave -noupdate -group R /$TOP/axi/r_id
add wave -noupdate -group R /$TOP/axi/r_last
add wave -noupdate -group R /$TOP/axi/r_resp
add wave -noupdate -group R /$TOP/axi/r_user
add wave -noupdate /$TOP/axi/r_valid
add wave -noupdate /$TOP/axi/r_ready
