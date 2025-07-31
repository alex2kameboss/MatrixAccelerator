module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 8    
) (
    // write interface
    input                           w_clk       ,   // write interface clock
    input                           w_reset_n   ,   // write interface async reset
    input                           w_incr_i    ,   // write interface increment
    output  logic                   w_full_o    ,   // write interface full
    input   [ DATA_WIDTH - 1 : 0 ]  w_data      ,   // write data
    // read interface    
    input                           r_clk       ,   // read interface clock
    input                           r_reset_n   ,   // read interface async reset
    input                           r_incr_i    ,   // read increment
    output  logic                   r_empty_o   ,   // read interface empty
    output  [ DATA_WIDTH - 1: 0 ]   r_data          // read data
);
    
`ifdef TARGET_VIVADO
localparam COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1;

xpm_fifo_async #(
    .FIFO_WRITE_DEPTH   ( FIFO_DEPTH    ),  // DECIMAL
    .RD_DATA_COUNT_WIDTH( COUNT_WIDTH   ),  // DECIMAL
    .READ_DATA_WIDTH    ( DATA_WIDTH    ),  // DECIMAL
    .READ_MODE          ( "fwft"        ),  // String
    .RELATED_CLOCKS     ( 1             ),  // DECIMAL
    .SIM_ASSERT_CHK     ( 0             ),  // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .USE_ADV_FEATURES   ( "0000"        ),  // String
    .WRITE_DATA_WIDTH   ( DATA_WIDTH    ),  // DECIMAL
    .WR_DATA_COUNT_WIDTH( COUNT_WIDTH   )   // DECIMAL
)
xpm_fifo_async_inst (
    .almost_empty   ( /* NOT CONNECTED */   ),  // 1-bit output: Almost Empty : When asserted, this signal indicates that
                                                // only one more read can be performed before the FIFO goes to empty.

    .almost_full    ( /* NOT CONNECTED */   ),  // 1-bit output: Almost Full: When asserted, this signal indicates that
                                                // only one more write can be performed before the FIFO is full.

    .data_valid     ( /* NOT CONNECTED */   ),  // 1-bit output: Read Data Valid: When asserted, this signal indicates
                                                // that valid data is available on the output bus (dout).

    .dbiterr        ( /* NOT CONNECTED */   ),  // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected
                                                // a double-bit error and data in the FIFO core is corrupted.

    .dout           ( r_data                ),  // READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
                                                // when reading the FIFO.

    .empty          ( r_empty_o             ),  // 1-bit output: Empty Flag: When asserted, this signal indicates that the
                                                // FIFO is empty. Read requests are ignored when the FIFO is empty,
                                                // initiating a read while empty is not destructive to the FIFO.

    .full           ( w_full_o              ),  // 1-bit output: Full Flag: When asserted, this signal indicates that the
                                                // FIFO is full. Write requests are ignored when the FIFO is full,
                                                // initiating a write when the FIFO is full is not destructive to the
                                                // contents of the FIFO.

    .overflow       ( /* NOT CONNECTED */   ),  // 1-bit output: Overflow: This signal indicates that a write request
                                                // (wren) during the prior clock cycle was rejected, because the FIFO is
                                                // full. Overflowing the FIFO is not destructive to the contents of the
                                                // FIFO.

    .prog_empty     ( /* NOT CONNECTED */   ),  // 1-bit output: Programmable Empty: This signal is asserted when the
                                                // number of words in the FIFO is less than or equal to the programmable
                                                // empty threshold value. It is de-asserted when the number of words in
                                                // the FIFO exceeds the programmable empty threshold value.

    .prog_full      ( /* NOT CONNECTED */   ),  // 1-bit output: Programmable Full: This signal is asserted when the
                                                // number of words in the FIFO is greater than or equal to the
                                                // programmable full threshold value. It is de-asserted when the number of
                                                // words in the FIFO is less than the programmable full threshold value.

    .rd_data_count  ( /* NOT CONNECTED */   ),  // RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the
                                                // number of words read from the FIFO.

    .rd_rst_busy    ( /* NOT CONNECTED */   ),  // 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read
                                                // domain is currently in a reset state.

    .sbiterr        ( /* NOT CONNECTED */   ),  // 1-bit output: Single Bit Error: Indicates that the ECC decoder detected
                                                // and fixed a single-bit error.

    .underflow      ( /* NOT CONNECTED */   ),  // 1-bit output: Underflow: Indicates that the read request (rd_en) during
                                                // the previous clock cycle was rejected because the FIFO is empty. Under
                                                // flowing the FIFO is not destructive to the FIFO.

    .wr_ack         ( /* NOT CONNECTED */   ),  // 1-bit output: Write Acknowledge: This signal indicates that a write
                                                // request (wr_en) during the prior clock cycle is succeeded.

    .wr_data_count  ( /* NOT CONNECTED */   ),  // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
                                                // the number of words written into the FIFO.

    .wr_rst_busy    ( /* NOT CONNECTED */   ),  // 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
                                                // write domain is currently in a reset state.

    .din            ( w_data                ),  // WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
                                                // writing the FIFO.

    .injectdbiterr  ( 1'b0                  ),  // 1-bit input: Double Bit Error Injection: Injects a double bit error if
                                                // the ECC feature is used on block RAMs or UltraRAM macros.

    .injectsbiterr  ( 1'b0                  ),  // 1-bit input: Single Bit Error Injection: Injects a single bit error if
                                                // the ECC feature is used on block RAMs or UltraRAM macros.

    .rd_clk         ( r_clk                 ),  // 1-bit input: Read clock: Used for read operation. rd_clk must be a free
                                                // running clock.

    .rd_en          ( r_incr_i              ),  // 1-bit input: Read Enable: If the FIFO is not empty, asserting this
                                                // signal causes data (on dout) to be read from the FIFO. Must be held
                                                // active-low when rd_rst_busy is active high.

    .rst            ( ~w_reset_n            ),  // 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be
                                                // unstable at the time of applying reset, but reset must be released only
                                                // after the clock(s) is/are stable.

    .sleep          ( 1'b0                  ),  // 1-bit input: Dynamic power saving: If sleep is High, the memory/fifo
                                                // block is in power saving mode.

    .wr_clk         ( w_clk                 ),  // 1-bit input: Write clock: Used for write operation. wr_clk must be a
                                                // free running clock.

    .wr_en          ( w_incr_i              )   // 1-bit input: Write Enable: If the FIFO is not full, asserting this
                                                // signal causes data (on din) to be written to the FIFO. Must be held
                                                // active-low when rst or wr_rst_busy is active high.

);


`else
wire [$clog2(FIFO_DEPTH) : 0] w_addr, r_addr, r_next_gray, w_next_gray;
wire [$clog2(FIFO_DEPTH) : 0] w_gray, r_gray, w_gray_sync, r_gray_sync;
logic w_stop, r_stop, w_en;


assign w_stop = ~w_full_o;
assign r_stop = ~r_empty_o;
assign w_en = w_incr_i & w_stop;


always_ff @ (posedge r_clk or negedge r_reset_n)
    if ( ~r_reset_n )   r_empty_o <= 1'd1;  else
                        r_empty_o <= r_next_gray == w_gray_sync;

always_ff @ (posedge w_clk or negedge w_reset_n)
    if ( ~w_reset_n )   w_full_o <= 1'd0;   else
                        w_full_o <= (w_next_gray[$clog2(FIFO_DEPTH)]         != r_gray_sync[$clog2(FIFO_DEPTH)]       ) &
                                    (w_next_gray[$clog2(FIFO_DEPTH) - 1]     != r_gray_sync[$clog2(FIFO_DEPTH) - 1]   ) &
                                    (w_next_gray[$clog2(FIFO_DEPTH) - 2 : 0] == r_gray_sync[$clog2(FIFO_DEPTH) - 2 : 0]);

gray_counter #(.WIDTH($clog2(FIFO_DEPTH) + 1)) write_counter_i (
    .clk(w_clk),
    .reset_n(w_reset_n),
    .inc_i(w_incr_i),
    .stop_i(w_stop),
    .addr_o(w_addr), 
    .ptr_o(w_gray),
    .next_gray_o(w_next_gray)
);

gray_counter #(.WIDTH($clog2(FIFO_DEPTH) + 1)) read_counter_i (
    .clk(r_clk),
    .reset_n(r_reset_n),
    .inc_i(r_incr_i),
    .stop_i(r_stop),
    .addr_o(r_addr), 
    .ptr_o(r_gray),
    .next_gray_o(r_next_gray)
);


// write -> read domain
synchronizer #(.DATA_WIDTH($clog2(FIFO_DEPTH) + 1)) r_synchronizer_i (
    .dest_clk(r_clk),
    .dest_reset_n(r_reset_n),
    .async_data_i(w_gray),
    .sync_data_o(w_gray_sync)
);

// read -> write domain
synchronizer #(.DATA_WIDTH($clog2(FIFO_DEPTH) + 1)) w_synchronizer_i (
    .dest_clk(w_clk),
    .dest_reset_n(w_reset_n),
    .async_data_i(r_gray),
    .sync_data_o(r_gray_sync)
);


memory #(.DATA_SIZE(DATA_WIDTH), .DEPTH(FIFO_DEPTH)) 
        fifo_memory_i (
    // write interface
    .w_clk(w_clk),
    .w_addr_i(w_addr[$clog2(FIFO_DEPTH) -1 : 0]),
    .w_data_i(w_data),
    .w_en_i(w_en),
    // read interface
    .r_addr_i(r_addr[$clog2(FIFO_DEPTH) -1 : 0]),
    .r_data_o(r_data)
);

`endif

endmodule