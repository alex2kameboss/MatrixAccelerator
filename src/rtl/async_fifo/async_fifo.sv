module async_fifo #(
    parameter WRITE_WIDTH   =   16  ,
    parameter READ_WIDTH    =   8   ,
    parameter FIFO_DEPTH    =   8       
) (
    // write interface
    input                           w_clk       ,   // write interface clock
    input                           w_reset_n   ,   // write interface async reset
    input                           w_incr_i    ,   // write iterface increment
    output  logic                   w_full_o    ,   // write interface full
    input   [ WRITE_WIDTH - 1 : 0 ] w_data      ,   // write data
    // read interface    
    input                           r_clk       ,   // read interface clock
    input                           r_reset_n   ,   // read interface async reset
    input                           r_incr_i    ,   // read increment
    output  logic                   r_empty_o   ,   // read interface empty
    output  [ READ_WIDTH - 1: 0 ]   r_data          // read data
);
    
localparam MAX_WIDTH = WRITE_WIDTH > READ_WIDTH ? WRITE_WIDTH : READ_WIDTH;
localparam MIN_WIDTH = WRITE_WIDTH < READ_WIDTH ? WRITE_WIDTH : READ_WIDTH;
localparam WIDTH_RATIO = MAX_WIDTH / MIN_WIDTH;
localparam WRITE_STEP = WRITE_WIDTH == MAX_WIDTH ? WIDTH_RATIO : 1;
localparam READ_STEP = READ_WIDTH == MAX_WIDTH ? WIDTH_RATIO : 1;

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

gray_counter #(.WIDTH($clog2(FIFO_DEPTH) + 1), .STEP(WRITE_STEP)) write_counter_i (
    .clk(w_clk),
    .reset_n(w_reset_n),
    .inc_i(w_incr_i),
    .stop_i(w_stop),
    .addr_o(w_addr), 
    .ptr_o(w_gray),
    .next_gray_o(w_next_gray)
);

gray_counter #(.WIDTH($clog2(FIFO_DEPTH) + 1), .STEP(READ_STEP)) read_counter_i (
    .clk(r_clk),
    .reset_n(r_reset_n),
    .inc_i(r_incr_i),
    .stop_i(r_stop),
    .addr_o(r_addr), 
    .ptr_o(r_gray),
    .next_gray_o(r_next_gray)
);


// write -> read domain
syncronizer #(.DATA_WIDTH($clog2(FIFO_DEPTH) + 1)) r_syncronizer_i (
    .dest_clk(r_clk),
    .dest_reset_n(r_reset_n),
    .async_data_i(w_gray),
    .sync_data_o(w_gray_sync)
);

// read -> write domain
syncronizer #(.DATA_WIDTH($clog2(FIFO_DEPTH) + 1)) w_syncronizer_i (
    .dest_clk(w_clk),
    .dest_reset_n(w_reset_n),
    .async_data_i(r_gray),
    .sync_data_o(r_gray_sync)
);


//memory #(.DATA_SIZE(DATA_WIDTH), .DEPTH(FIFO_DEPTH)) 
//        fifo_memeory_i (
//    // write interface
//    .w_clk(w_clk),
//    .w_addr_i(w_addr[$clog2(FIFO_DEPTH) -1 : 0]),
//    .w_data_i(w_data),
//    .w_en_i(w_en),
//    // read interface
//    .r_addr_i(r_addr[$clog2(FIFO_DEPTH) -1 : 0]),
//    .r_data_o(r_data)
//);

logic [ $clog2(FIFO_DEPTH) - 1 : 0 ]   w_addr_i;   // write address
logic [ $clog2(FIFO_DEPTH) - 1 : 0 ]   r_addr_i;   // readd address

assign r_addr_i = r_addr[$clog2(FIFO_DEPTH) -1 : 0];
assign w_addr_i = w_addr[$clog2(FIFO_DEPTH) -1 : 0];

reg [ MIN_WIDTH - 1 : 0 ] mem [ FIFO_DEPTH - 1 : 0 ];

genvar i;
generate
    if ( WRITE_WIDTH > READ_WIDTH ) begin
assign r_data = mem[r_addr_i];
    for ( i = 0; i < WIDTH_RATIO; i = i + 1 ) begin
always_ff @ (posedge w_clk)
    if ( w_en )
        mem[w_addr_i + i] <= w_data[(i + 1) * READ_WIDTH -: READ_WIDTH];
    end
    end else if ( WRITE_WIDTH < READ_WIDTH ) begin
for ( i = 0; i < WIDTH_RATIO; i = i + 1 ) begin
    assign r_data[(i + 1) * WRITE_WIDTH -: WRITE_WIDTH] = mem[r_addr_i + i];
end
always_ff @ (posedge w_clk)
    if ( w_en )   mem[w_addr_i] <= w_data;
    end else begin
assign r_data = mem[r_addr_i];
always_ff @ (posedge w_clk)
    if ( w_en )   mem[w_addr_i] <= w_data; 
    end
endgenerate


endmodule