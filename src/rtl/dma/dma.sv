module dma #(
    parameter ADDR_WIDTH = 32   ,
    parameter DATA_WIDTH = 128   // data size inside the core
) (
    // generic signals
    input   logic                           clk                         ,
    input   logic                           rst_n                       ,
    // write chanel
    input   logic                           write_valid_i               ,
    output  logic                           write_ready_o               ,
    input   logic   [ADDR_WIDTH - 1 : 0]    write_addr_i                ,
    input   logic   [ADDR_WIDTH - 1 : 0]    write_len_i                 ,
    output  logic                           write_done_o                ,
    // read chanel
    input   logic                           read_valid_i                ,
    output  logic                           read_ready_o                ,
    input   logic   [ADDR_WIDTH - 1 : 0]    read_addr_i                 ,
    input   logic   [ADDR_WIDTH - 1 : 0]    read_len_i                  ,
    output  logic                           read_done_o                 ,
    // data fifos
    // write fifo
    input   logic   [DATA_WIDTH - 1 : 0]    write_data_i                ,
    input   logic                           write_data_valid_i          ,
    output  logic                           write_data_ready_o          ,
    // read fifo
    output  logic   [DATA_WIDTH - 1 : 0]    read_data_o                 ,
    output  logic                           read_data_valid_o           ,
    input   logic                           read_data_ready_i           ,
    // axi interface
    input   logic                           aclk                        ,
    input   logic                           arst_n                      ,
    AXI_BUS.Master                          axi                         
);

// for AXI interface
localparam DATA_BYTES       = axi.AXI_DATA_WIDTH / 8;
localparam MAX_BURST_SIZE   = 256 * DATA_BYTES >= 4 * 1024 ? 4 * 1024 : 256 * DATA_BYTES; // max 4 KB
localparam MAX_BURST        = MAX_BURST_SIZE / DATA_BYTES;
localparam MAX_TRANSACTIONS = 8'(MAX_BURST - 1);

// const protocol signals
assign axi.aw_lock      =   'd0;
assign axi.aw_cache     =   'd0;
assign axi.aw_prot      =   'd0;
assign axi.aw_qos       =   'd0;
assign axi.aw_region    =   'd0;
assign axi.aw_atop      =   'd0;
assign axi.aw_user      =   'd0;
assign axi.aw_id        =   'd0;
// ---------------------------
assign axi.ar_lock      =   'd0;
assign axi.ar_cache     =   'd0;
assign axi.ar_prot      =   'd0;
assign axi.ar_qos       =   'd0;
assign axi.ar_region    =   'd0;
assign axi.ar_user      =   'd0;
assign axi.ar_id        =   'd0;

// write side

logic [ADDR_WIDTH - 1 : 0]  write_cnt;
logic                       start_write, aw_accepted, write_ready_aclk, write_valid_aclk, write_done_aclk, b_accepted;
logic [ADDR_WIDTH - 1 : 0]  write_len, write_addr, write_len_aclk, write_addr_aclk;
logic [ADDR_WIDTH - 1 : 0]  write_transactions_counter;
logic [$clog2(DATA_BYTES) - 1 : 0]  write_len_remain_bits;

assign start_write = write_valid_aclk & write_ready_aclk;
assign aw_accepted = axi.aw_ready & axi.aw_valid;
assign write_done_aclk = ~|write_transactions_counter & ~|write_len;
assign b_accepted = axi.b_ready & axi.b_valid;

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  write_ready_aclk <= 1'b0;           else
    if ( write_ready_aclk )         write_ready_aclk <= 1'b0;           else
    if ( write_valid_aclk & write_done_aclk ) write_ready_aclk <= 1'b1;

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  write_len <= 'd0;               else
    if ( start_write )              write_len <= write_len_aclk / DATA_BYTES + |write_len_aclk[$clog2(DATA_BYTES) - 1 : 0];       else
    if ( aw_accepted )              write_len <= write_len - ({1'b0, axi.aw_len} + 1'b1);

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  write_len_remain_bits <= 'd0;               else
    if ( start_write )              write_len_remain_bits <= write_len_aclk[$clog2(DATA_BYTES) - 1 : 0];

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  write_addr <= 'd0;              else
    if ( start_write )              write_addr <= write_addr_aclk;     else
    if ( aw_accepted )              write_addr <= write_addr + ({1'b0, axi.aw_len} + 1'b1) * DATA_BYTES;

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                      write_transactions_counter <= 1'b0;                                 else
    if ( aw_accepted )                  write_transactions_counter <= write_transactions_counter + 1'b1;    else
    if ( b_accepted )                   write_transactions_counter <= write_transactions_counter - 1'b1;

// write control chanels
always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  axi.aw_valid <= 1'b0;           else
    if ( aw_accepted )              axi.aw_valid <= 1'b0;           else
    if ( |write_len & ~|write_cnt )  axi.aw_valid <= 1'b1;           

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  axi.aw_addr <= 'd0;             else
    if ( aw_accepted )              axi.aw_addr <= 'd0;             else
    if ( |write_len & ~|write_cnt )               axi.aw_addr <= write_addr;      

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  axi.aw_len <= 'd0;              else
    if ( aw_accepted )              axi.aw_len <= 'd0;              else
    if ( |write_len & ~|write_cnt ) axi.aw_len <= (write_len + write_addr[11 : $clog2(DATA_BYTES)]) >= MAX_BURST ? MAX_TRANSACTIONS - write_addr[11 : $clog2(DATA_BYTES)] : write_len - 1'b1;              

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  axi.aw_size <= 'd0;             else
    if ( aw_accepted )              axi.aw_size <= 'd0;             else
    if ( |write_len & ~|write_cnt )               axi.aw_size <= 3'($clog2(DATA_BYTES));

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  axi.aw_burst <= 'd0;            else
    if ( aw_accepted )              axi.aw_burst <= 'd0;            else
    if ( |write_len & ~|write_cnt )               axi.aw_burst <= 'd1;            // INCR burst

// b chanel
always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  axi.b_ready <= 1'b1;

// write chanel

logic [DATA_BYTES - 1 : 0]  write_strobe;

strobe_generator #(
    .STROBE_WIDTH(DATA_BYTES)
) i_write_strobe_generator (
    .en      ( ~|write_len & |write_len_remain_bits & write_cnt == 'd1 ),   // if not enable, the strobe is all 1
    .value   ( write_len_remain_bits ),
    .strobe  ( write_strobe )
);

assign axi.w_user = 'd0;

//always_ff @( posedge aclk, negedge arst_n )
//    if ( ~arst_n )                  axi.aw_id <= 'd0;              else
//    if ( aw_accepted )              axi.aw_id <= axi.aw_id + 1'b1;

assign axi.w_strb = write_strobe & {DATA_BYTES{axi.w_valid}};

//always_ff @( posedge aclk, negedge arst_n )
//    if ( ~arst_n )                  axi.w_strb <= 'd0;              else
//    if ( |write_cnt )               axi.w_strb <= write_strobe;

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  write_cnt <= 'd0;               else
    if ( axi.w_ready & axi.w_valid )write_cnt <= write_cnt - 1'b1;  else
    if ( aw_accepted )              write_cnt <= {1'b0, axi.aw_len} + 1'b1;

assign axi.w_last = axi.w_valid & write_cnt == 'd1;

// read side

logic                       start_read, ar_accepted, read_valid_aclk, read_ready_aclk, read_done_aclk;
logic [ADDR_WIDTH - 1 : 0]  read_len, read_addr, read_len_aclk, read_addr_aclk;
logic [ADDR_WIDTH - 1 : 0]  read_transactions_counter;

assign start_read   =   read_valid_aclk & read_ready_aclk;
assign ar_accepted  =   axi.ar_valid & axi.ar_ready;
assign read_done_aclk =   ~|read_transactions_counter & ~|read_len;

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  read_ready_aclk <= 1'b0;                   else
    if ( read_ready_aclk )          read_ready_aclk <= 1'b0;                   else
    if ( read_valid_aclk & read_done_aclk ) read_ready_aclk <= 1'b1;

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  read_len <= 'd0;                        else
    if ( start_read )               read_len <= read_len_aclk / DATA_BYTES + |read_len_aclk[$clog2(DATA_BYTES) - 1 : 0]; else // if are less B than data bus
    if ( ar_accepted )              read_len <= read_len - ({1'b0, axi.ar_len} + 1'b1);

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  read_addr <= 'd0;                       else
    if ( start_read )               read_addr <= read_addr_aclk;               else
    if ( ar_accepted )              read_addr <= read_addr + ({1'b0, axi.ar_len} + 1'b1) * DATA_BYTES;

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  read_transactions_counter <= 'd0;                               else
    if ( ar_accepted & axi.r_ready & 
        axi.r_valid & axi.r_last )  read_transactions_counter <= read_transactions_counter;         else
    if ( ar_accepted )              read_transactions_counter <= read_transactions_counter + 1'b1;  else
    if ( axi.r_ready & 
        axi.r_valid & axi.r_last )  read_transactions_counter <= read_transactions_counter - 1'b1;

// read control chanel
always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  axi.ar_valid <= 1'b0;               else
    if ( ar_accepted )              axi.ar_valid <= 1'b0;               else
    if ( |read_len )                axi.ar_valid <= 1'b1;               

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  axi.ar_addr <= 'd0;                 else
    if ( ar_accepted )              axi.ar_addr <= 'd0;                 else
    if ( |read_len )                axi.ar_addr <= read_addr;

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  axi.ar_len <= 'd0;                  else
    if ( ar_accepted )              axi.ar_len <= 'd0;                  else
    if ( |read_len )                axi.ar_len <= (read_len + read_addr[11 : $clog2(DATA_BYTES)]) >= MAX_BURST ? MAX_TRANSACTIONS - read_addr[11 : $clog2(DATA_BYTES)] : (read_len - 1'b1);

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  axi.ar_size <= 'd0;                 else
    if ( ar_accepted )              axi.ar_size <= 'd0;                 else
    if ( |read_len )                axi.ar_size <= 3'($clog2(DATA_BYTES));

always_ff @( posedge aclk, negedge arst_n )
    if ( ~arst_n )                  axi.ar_burst <= 'd0;                else
    if ( ar_accepted )              axi.ar_burst <= 'd0;                else
    if ( |read_len )                axi.ar_burst <= 'd1;                // INCR burst


// fifos

logic [axi.AXI_DATA_WIDTH - 1 : 0]  write_strobed_data;

genvar write_fifo_i;
generate
    for ( write_fifo_i = 0; write_fifo_i < DATA_BYTES; write_fifo_i = write_fifo_i + 1 )
    assign axi.w_data[(write_fifo_i + 1) * 8 - 1 : write_fifo_i * 8] = write_strobed_data[(write_fifo_i + 1) * 8 - 1 : write_fifo_i * 8] & {8{write_strobe[write_fifo_i] & axi.w_valid}};
endgenerate

generate
    if ( DATA_WIDTH == axi.AXI_DATA_WIDTH ) begin : equal_sizes
logic write_fifo_w_incr, write_fifo_r_incr;
logic write_fifo_w_full, write_fifo_r_empty;

assign write_fifo_w_incr    = write_data_valid_i & write_data_ready_o;
assign write_fifo_r_incr    = axi.w_ready & axi.w_valid;
assign write_data_ready_o   = ~write_fifo_w_full;
assign axi.w_valid          = ~write_fifo_r_empty;

async_fifo #(
    .DATA_WIDTH( DATA_WIDTH ),
    .FIFO_DEPTH( MAX_BURST )    
) write_fifo (
    .w_clk     ( clk                ) ,   // write interface clock
    .w_reset_n ( rst_n              ) ,   // write interface async reset
    .w_incr_i  ( write_fifo_w_incr  ) ,   // write iterface increment
    .w_full_o  ( write_fifo_w_full  ) ,   // write interface full
    .w_data    ( write_data_i       ) ,   // write data
    .r_clk     ( aclk               ) ,   // read interface clock
    .r_reset_n ( arst_n             ) ,   // read interface async reset
    .r_incr_i  ( write_fifo_r_incr  ) ,   // read increment
    .r_empty_o ( write_fifo_r_empty ) ,   // read interface empty
    .r_data    ( write_strobed_data )     // read data
);

logic read_fifo_w_incr, read_fifo_r_incr;
logic read_fifo_w_full, read_fifo_r_empty;

assign read_fifo_w_incr     = axi.r_ready & axi.r_valid;
assign read_fifo_r_incr     = read_data_valid_o & read_data_ready_i;
assign read_data_valid_o    = ~read_fifo_r_empty;
assign axi.r_ready          = ~read_fifo_w_full;

async_fifo #(
    .DATA_WIDTH( DATA_WIDTH ),
    .FIFO_DEPTH( MAX_BURST )    
) read_fifo (
    .w_clk     ( aclk               ) ,   // write interface clock
    .w_reset_n ( arst_n             ) ,   // write interface async reset
    .w_incr_i  ( read_fifo_w_incr   ) ,   // write iterface increment
    .w_full_o  ( read_fifo_w_full   ) ,   // write interface full
    .w_data    ( axi.r_data         ) ,   // write data
    .r_clk     ( clk                ) ,   // read interface clock
    .r_reset_n ( rst_n              ) ,   // read interface async reset
    .r_incr_i  ( read_fifo_r_incr   ) ,   // read increment
    .r_empty_o ( read_fifo_r_empty  ) ,   // read interface empty
    .r_data    ( read_data_o        )     // read data
);
    end else if ( DATA_WIDTH > axi.AXI_DATA_WIDTH ) begin : larger_size
logic write_fifo_w_incr, write_fifo_r_incr;
logic write_fifo_w_full, write_fifo_r_empty, write_concat_full;
logic [axi.AXI_DATA_WIDTH - 1 : 0]  write_fifo_data;


assign write_fifo_r_incr    = axi.w_ready & axi.w_valid;
assign write_data_ready_o   = ~write_concat_full;
assign axi.w_valid          = ~write_fifo_r_empty;

async_fifo #(
    .DATA_WIDTH( axi.AXI_DATA_WIDTH ),
    .FIFO_DEPTH( MAX_BURST          )    
) write_fifo (
    .w_clk     ( clk                ) ,   // write interface clock
    .w_reset_n ( rst_n              ) ,   // write interface async reset
    .w_incr_i  ( write_fifo_w_incr  ) ,   // write iterface increment
    .w_full_o  ( write_fifo_w_full  ) ,   // write interface full
    .w_data    ( write_fifo_data    ) ,   // write data
    .r_clk     ( aclk               ) ,   // read interface clock
    .r_reset_n ( arst_n             ) ,   // read interface async reset
    .r_incr_i  ( write_fifo_r_incr  ) ,   // read increment
    .r_empty_o ( write_fifo_r_empty ) ,   // read interface empty
    .r_data    ( write_strobed_data )     // read data
);

write_concat #(
    .FIFO_DATA_WIDTH    ( axi.AXI_DATA_WIDTH                ),
    .DATA_MULTIPLIER    ( DATA_WIDTH / axi.AXI_DATA_WIDTH   )
) i_write_concat (
    .clk         ( clk                  ),
    .rst_n       ( rst_n                ),
    .fifo_data   ( write_fifo_data      ),
    .fifo_full   ( write_fifo_w_full    ),
    .fifo_incr   ( write_fifo_w_incr    ),
    .data        ( write_data_i         ),
    .full        ( write_concat_full    ),
    .incr        ( write_data_valid_i   )
);

logic read_fifo_w_incr, read_fifo_r_incr;
logic read_fifo_w_full, read_fifo_r_empty, read_concat_empty;
logic [axi.AXI_DATA_WIDTH - 1 : 0]  read_fifo_data;

assign read_fifo_w_incr     = axi.r_ready & axi.r_valid;
assign read_data_valid_o    = ~read_concat_empty;
assign axi.r_ready          = ~read_fifo_w_full;

async_fifo #(
    .DATA_WIDTH( axi.AXI_DATA_WIDTH ),
    .FIFO_DEPTH( MAX_BURST          )    
) read_fifo (
    .w_clk     ( aclk               ) ,   // write interface clock
    .w_reset_n ( arst_n             ) ,   // write interface async reset
    .w_incr_i  ( read_fifo_w_incr   ) ,   // write iterface increment
    .w_full_o  ( read_fifo_w_full   ) ,   // write interface full
    .w_data    ( axi.r_data         ) ,   // write data
    .r_clk     ( clk                ) ,   // read interface clock
    .r_reset_n ( rst_n              ) ,   // read interface async reset
    .r_incr_i  ( read_fifo_r_incr   ) ,   // read increment
    .r_empty_o ( read_fifo_r_empty  ) ,   // read interface empty
    .r_data    ( read_fifo_data     )     // read data
);        

read_concat #(
    .FIFO_DATA_WIDTH    ( axi.AXI_DATA_WIDTH                ),
    .DATA_MULTIPLIER    ( DATA_WIDTH / axi.AXI_DATA_WIDTH   )
) i_read_concat (
    .clk         ( clk                                  ),
    .rst_n       ( rst_n                                ),
    .fifo_data   ( read_fifo_data                       ),
    .fifo_empty  ( read_fifo_r_empty                    ),
    .fifo_incr   ( read_fifo_r_incr                     ),
    .data        ( read_data_o                          ),
    .empty       ( read_concat_empty                    ),
    .incr        ( read_data_valid_o & read_data_ready_i)
);

    end
endgenerate

// syncronizers

// clk -> aclk
syncronizer #(
    .DATA_WIDTH( 1 )
) i_write_valid (
    .dest_clk      ( aclk               ) ,
    .dest_reset_n  ( arst_n             ) ,
    .async_data_i  ( write_valid_i      ) ,
    .sync_data_o   ( write_valid_aclk   ) 
);

syncronizer #(
    .DATA_WIDTH( ADDR_WIDTH )
) i_write_addr (
    .dest_clk      ( aclk               ) ,
    .dest_reset_n  ( arst_n             ) ,
    .async_data_i  ( write_addr_i       ) ,
    .sync_data_o   ( write_addr_aclk    ) 
);

syncronizer #(
    .DATA_WIDTH( ADDR_WIDTH )
) i_write_len (
    .dest_clk      ( aclk               ) ,
    .dest_reset_n  ( arst_n             ) ,
    .async_data_i  ( write_len_i        ) ,
    .sync_data_o   ( write_len_aclk     ) 
);

syncronizer #(
    .DATA_WIDTH( 1 )
) i_read_valid (
    .dest_clk      ( aclk               ) ,
    .dest_reset_n  ( arst_n             ) ,
    .async_data_i  ( read_valid_i       ) ,
    .sync_data_o   ( read_valid_aclk    ) 
);

syncronizer #(
    .DATA_WIDTH( ADDR_WIDTH )
) i_read_addr (
    .dest_clk      ( aclk               ) ,
    .dest_reset_n  ( arst_n             ) ,
    .async_data_i  ( read_addr_i        ) ,
    .sync_data_o   ( read_addr_aclk     ) 
);

syncronizer #(
    .DATA_WIDTH( ADDR_WIDTH )
) i_read_len (
    .dest_clk      ( aclk               ) ,
    .dest_reset_n  ( arst_n             ) ,
    .async_data_i  ( read_len_i         ) ,
    .sync_data_o   ( read_len_aclk      ) 
);

// aclk -> clk
syncronizer #(
    .DATA_WIDTH( 1 )
) i_write_ready (
    .dest_clk      ( clk                ) ,
    .dest_reset_n  ( rst_n              ) ,
    .async_data_i  ( write_ready_aclk   ) ,
    .sync_data_o   ( write_ready_o      ) 
);

syncronizer #(
    .DATA_WIDTH( 1 )
) i_write_done (
    .dest_clk      ( clk                ) ,
    .dest_reset_n  ( rst_n              ) ,
    .async_data_i  ( write_done_aclk    ) ,
    .sync_data_o   ( write_done_o       ) 
);

syncronizer #(
    .DATA_WIDTH( 1 )
) i_read_ready (
    .dest_clk      ( clk                ) ,
    .dest_reset_n  ( rst_n              ) ,
    .async_data_i  ( read_ready_aclk    ) ,
    .sync_data_o   ( read_ready_o       ) 
);

syncronizer #(
    .DATA_WIDTH( 1 )
) i_read_done (
    .dest_clk      ( clk                ) ,
    .dest_reset_n  ( rst_n              ) ,
    .async_data_i  ( read_done_aclk     ) ,
    .sync_data_o   ( read_done_o        ) 
);

endmodule