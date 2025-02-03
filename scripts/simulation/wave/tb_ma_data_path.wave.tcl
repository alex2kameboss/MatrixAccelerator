onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_ma_data_path/i_dut/aclk
add wave -noupdate /tb_ma_data_path/i_dut/addr
add wave -noupdate /tb_ma_data_path/i_dut/ADDR_WIDTH
add wave -noupdate /tb_ma_data_path/i_dut/ALU_WIDTH
add wave -noupdate /tb_ma_data_path/i_dut/arith
add wave -noupdate /tb_ma_data_path/i_dut/arith_done
add wave -noupdate /tb_ma_data_path/i_dut/arst_n
add wave -noupdate /tb_ma_data_path/i_dut/arth_data
add wave -noupdate /tb_ma_data_path/i_dut/clk
add wave -noupdate /tb_ma_data_path/i_dut/define
add wave -noupdate /tb_ma_data_path/i_dut/dma_addr_gen_en
add wave -noupdate /tb_ma_data_path/i_dut/dma_addr_gen_incr
add wave -noupdate /tb_ma_data_path/i_dut/DMA_DATA_WIDTH
add wave -noupdate /tb_ma_data_path/i_dut/dma_done
add wave -noupdate -radix unsigned /tb_ma_data_path/i_dut/dma_i_out
add wave -noupdate -radix unsigned /tb_ma_data_path/i_dut/dma_j_out
add wave -noupdate /tb_ma_data_path/i_dut/dma_read_addr
add wave -noupdate /tb_ma_data_path/i_dut/dma_read_data
add wave -noupdate /tb_ma_data_path/i_dut/dma_read_data_ready
add wave -noupdate /tb_ma_data_path/i_dut/dma_read_data_valid
add wave -noupdate /tb_ma_data_path/i_dut/dma_read_done
add wave -noupdate /tb_ma_data_path/i_dut/dma_read_incr
add wave -noupdate /tb_ma_data_path/i_dut/dma_read_len
add wave -noupdate /tb_ma_data_path/i_dut/dma_read_ready
add wave -noupdate /tb_ma_data_path/i_dut/dma_read_valid
add wave -noupdate /tb_ma_data_path/i_dut/dma_write_addr
add wave -noupdate /tb_ma_data_path/i_dut/dma_write_data
add wave -noupdate /tb_ma_data_path/i_dut/dma_write_data_ready
add wave -noupdate /tb_ma_data_path/i_dut/dma_write_done
add wave -noupdate /tb_ma_data_path/i_dut/dma_write_done_o
add wave -noupdate /tb_ma_data_path/i_dut/dma_write_incr
add wave -noupdate /tb_ma_data_path/i_dut/dma_write_len
add wave -noupdate /tb_ma_data_path/i_dut/dma_write_ready
add wave -noupdate /tb_ma_data_path/i_dut/dma_write_valid
add wave -noupdate /tb_ma_data_path/i_dut/dscheme
add wave -noupdate /tb_ma_data_path/i_dut/dtype
add wave -noupdate /tb_ma_data_path/i_dut/height
add wave -noupdate /tb_ma_data_path/i_dut/ld_st
add wave -noupdate /tb_ma_data_path/i_dut/load
add wave -noupdate /tb_ma_data_path/i_dut/start_addr_gen
add wave -noupdate /tb_ma_data_path/i_dut/prf_read
add wave -noupdate -radix unsigned /tb_ma_data_path/i_dut/read_i
add wave -noupdate -radix unsigned /tb_ma_data_path/i_dut/read_j
add wave -noupdate /tb_ma_data_path/i_dut/dma_write_data_valid
add wave -noupdate /tb_ma_data_path/i_dut/mem_r_op1
add wave -noupdate /tb_ma_data_path/i_dut/mem_r_op2
add wave -noupdate /tb_ma_data_path/i_dut/mem_w_data
add wave -noupdate /tb_ma_data_path/i_dut/NUMBER_OF_ALU
add wave -noupdate /tb_ma_data_path/i_dut/op
add wave -noupdate /tb_ma_data_path/i_dut/op_cfg
add wave -noupdate /tb_ma_data_path/i_dut/prf_write
add wave -noupdate /tb_ma_data_path/i_dut/prf_data_in
add wave -noupdate /tb_ma_data_path/i_dut/prf_data_out_r
add wave -noupdate /tb_ma_data_path/i_dut/prf_data_out_w
add wave -noupdate /tb_ma_data_path/i_dut/prf_define
add wave -noupdate /tb_ma_data_path/i_dut/PRF_LOG_M
add wave -noupdate /tb_ma_data_path/i_dut/PRF_LOG_N
add wave -noupdate /tb_ma_data_path/i_dut/PRF_LOG_P
add wave -noupdate /tb_ma_data_path/i_dut/PRF_LOG_Q
add wave -noupdate /tb_ma_data_path/i_dut/PRF_N_LANES
add wave -noupdate /tb_ma_data_path/i_dut/PRF_N_RPORTS
add wave -noupdate /tb_ma_data_path/i_dut/PRF_N_WPORTS
add wave -noupdate /tb_ma_data_path/i_dut/rd
add wave -noupdate -expand /tb_ma_data_path/i_dut/rd_cfg
add wave -noupdate /tb_ma_data_path/i_dut/ready
add wave -noupdate /tb_ma_data_path/i_dut/REGISTER_NUMBERS
add wave -noupdate /tb_ma_data_path/i_dut/rs1
add wave -noupdate /tb_ma_data_path/i_dut/rs1_cfg
add wave -noupdate /tb_ma_data_path/i_dut/rs2
add wave -noupdate /tb_ma_data_path/i_dut/rs2_cfg
add wave -noupdate /tb_ma_data_path/i_dut/rst_n
add wave -noupdate /tb_ma_data_path/i_dut/scalar
add wave -noupdate /tb_ma_data_path/i_dut/scalar_cfg
add wave -noupdate /tb_ma_data_path/i_dut/scalar_op
add wave -noupdate /tb_ma_data_path/i_dut/scalar_op_cfg
add wave -noupdate /tb_ma_data_path/i_dut/SRAM_WIDTH
add wave -noupdate /tb_ma_data_path/i_dut/store
add wave -noupdate /tb_ma_data_path/i_dut/taccess_read
add wave -noupdate /tb_ma_data_path/i_dut/taccess_write
add wave -noupdate /tb_ma_data_path/i_dut/valid
add wave -noupdate /tb_ma_data_path/i_dut/vu_done
add wave -noupdate /tb_ma_data_path/i_dut/vu_en
add wave -noupdate /tb_ma_data_path/i_dut/vu_rd_data
add wave -noupdate /tb_ma_data_path/i_dut/vu_rd_i_out
add wave -noupdate /tb_ma_data_path/i_dut/vu_rd_j_out
add wave -noupdate /tb_ma_data_path/i_dut/vu_rd_write
add wave -noupdate /tb_ma_data_path/i_dut/vu_rs1_data
add wave -noupdate /tb_ma_data_path/i_dut/vu_rs1_i_out
add wave -noupdate /tb_ma_data_path/i_dut/vu_rs1_j_out
add wave -noupdate /tb_ma_data_path/i_dut/vu_rs1_read
add wave -noupdate /tb_ma_data_path/i_dut/vu_rs2_data
add wave -noupdate /tb_ma_data_path/i_dut/vu_rs2_i_out
add wave -noupdate /tb_ma_data_path/i_dut/vu_rs2_j_out
add wave -noupdate /tb_ma_data_path/i_dut/vu_rs2_read
add wave -noupdate /tb_ma_data_path/i_dut/width
add wave -noupdate /tb_ma_data_path/i_dut/write_i
add wave -noupdate /tb_ma_data_path/i_dut/write_j
add wave -noupdate -divider vectorial_unit
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/ALU_WIDTH
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/clk
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/DMA_DATA_WIDTH
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/done
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/dtype
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/NUMBER_OF_ALU
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/op
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/en
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/start
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rs1_read
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rs1_data
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rs_addr_en
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/op1_alu
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/op2_alu
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/concat_en
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/res_alu
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rd
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rd_data
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rd_i_out
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rd_j_out
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rd_write
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rs1
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rs1_done
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rs1_i_out
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rs1_j_out
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rs2
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rs2_data
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rs2_done
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rs2_i_out
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rs2_j_out
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rs2_read
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rs_incr
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/rst_n
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/start_delayed
add wave -noupdate -divider concat
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/i_vectorial_concat/clk
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/i_vectorial_concat/cnt
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/i_vectorial_concat/dtype
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/i_vectorial_concat/en
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/i_vectorial_concat/IN_BYTES
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/i_vectorial_concat/IN_DATA_WIDTH
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/i_vectorial_concat/next
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/i_vectorial_concat/NUMBER_OF_ALU
add wave -noupdate -radix unsigned /tb_ma_data_path/i_dut/i_vectorial_unit/i_vectorial_concat/OUT_DATA_WIDTH
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/i_vectorial_concat/reset
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/i_vectorial_concat/rez_in
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/i_vectorial_concat/rez_in_byte
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/i_vectorial_concat/rez_out
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/i_vectorial_concat/rst_n
add wave -noupdate /tb_ma_data_path/i_dut/i_vectorial_unit/i_vectorial_concat/valid
add wave -noupdate -divider axi
add wave -noupdate -divider tb_ma_data_path/axi/AW
add wave -noupdate -group tb_ma_data_path/axi/AW /tb_ma_data_path/axi/aw_addr
add wave -noupdate -group tb_ma_data_path/axi/AW /tb_ma_data_path/axi/aw_len
add wave -noupdate -group tb_ma_data_path/axi/AW /tb_ma_data_path/axi/aw_size
add wave -noupdate -group tb_ma_data_path/axi/AW /tb_ma_data_path/axi/aw_atop
add wave -noupdate -group tb_ma_data_path/axi/AW /tb_ma_data_path/axi/aw_burst
add wave -noupdate -group tb_ma_data_path/axi/AW /tb_ma_data_path/axi/aw_cache
add wave -noupdate -group tb_ma_data_path/axi/AW /tb_ma_data_path/axi/aw_id
add wave -noupdate -group tb_ma_data_path/axi/AW /tb_ma_data_path/axi/aw_lock
add wave -noupdate -group tb_ma_data_path/axi/AW /tb_ma_data_path/axi/aw_prot
add wave -noupdate -group tb_ma_data_path/axi/AW /tb_ma_data_path/axi/aw_qos
add wave -noupdate -group tb_ma_data_path/axi/AW /tb_ma_data_path/axi/aw_region
add wave -noupdate -group tb_ma_data_path/axi/AW /tb_ma_data_path/axi/aw_user
add wave -noupdate /tb_ma_data_path/axi/aw_valid
add wave -noupdate /tb_ma_data_path/axi/aw_ready
add wave -noupdate -divider tb_ma_data_path/axi/W
add wave -noupdate -group tb_ma_data_path/axi/W /tb_ma_data_path/axi/w_data
add wave -noupdate -group tb_ma_data_path/axi/W /tb_ma_data_path/axi/w_last
add wave -noupdate -group tb_ma_data_path/axi/W /tb_ma_data_path/axi/w_strb
add wave -noupdate -group tb_ma_data_path/axi/W /tb_ma_data_path/axi/w_user
add wave -noupdate /tb_ma_data_path/axi/w_valid
add wave -noupdate /tb_ma_data_path/axi/w_ready
add wave -noupdate -divider tb_ma_data_path/axi/B
add wave -noupdate -group tb_ma_data_path/axi/B /tb_ma_data_path/axi/b_id
add wave -noupdate -group tb_ma_data_path/axi/B /tb_ma_data_path/axi/b_resp
add wave -noupdate -group tb_ma_data_path/axi/B /tb_ma_data_path/axi/b_user
add wave -noupdate /tb_ma_data_path/axi/b_valid
add wave -noupdate /tb_ma_data_path/axi/b_ready
add wave -noupdate -divider tb_ma_data_path/axi/AR
add wave -noupdate -group tb_ma_data_path/axi/AR /tb_ma_data_path/axi/ar_addr
add wave -noupdate -group tb_ma_data_path/axi/AR /tb_ma_data_path/axi/ar_len
add wave -noupdate -group tb_ma_data_path/axi/AR /tb_ma_data_path/axi/ar_size
add wave -noupdate -group tb_ma_data_path/axi/AR /tb_ma_data_path/axi/ar_burst
add wave -noupdate -group tb_ma_data_path/axi/AR /tb_ma_data_path/axi/ar_cache
add wave -noupdate -group tb_ma_data_path/axi/AR /tb_ma_data_path/axi/ar_id
add wave -noupdate -group tb_ma_data_path/axi/AR /tb_ma_data_path/axi/ar_lock
add wave -noupdate -group tb_ma_data_path/axi/AR /tb_ma_data_path/axi/ar_prot
add wave -noupdate -group tb_ma_data_path/axi/AR /tb_ma_data_path/axi/ar_qos
add wave -noupdate -group tb_ma_data_path/axi/AR /tb_ma_data_path/axi/ar_region
add wave -noupdate -group tb_ma_data_path/axi/AR /tb_ma_data_path/axi/ar_user
add wave -noupdate /tb_ma_data_path/axi/ar_valid
add wave -noupdate /tb_ma_data_path/axi/ar_ready
add wave -noupdate -divider tb_ma_data_path/axi/R
add wave -noupdate -group tb_ma_data_path/axi/R /tb_ma_data_path/axi/r_data
add wave -noupdate -group tb_ma_data_path/axi/R /tb_ma_data_path/axi/r_id
add wave -noupdate -group tb_ma_data_path/axi/R /tb_ma_data_path/axi/r_last
add wave -noupdate -group tb_ma_data_path/axi/R /tb_ma_data_path/axi/r_resp
add wave -noupdate -group tb_ma_data_path/axi/R /tb_ma_data_path/axi/r_user
add wave -noupdate /tb_ma_data_path/axi/r_valid
add wave -noupdate /tb_ma_data_path/axi/r_ready
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {595 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 452
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {3192 ns}
