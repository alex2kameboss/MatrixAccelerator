module matrix_addr_gen #(
    parameter   PRF_LOG_P   =   1   ,
    parameter   PRF_LOG_Q   =   2   ,
    parameter   PRF_LOG_N   =   10  ,
    parameter   PRF_LOG_M   =   10  ,
    parameter   SRAM_WIDTH  =   32  ,
    localparam  PRF_P       =   2 ** PRF_LOG_P  ,
    localparam  PRF_Q       =   2 ** PRF_LOG_Q  
) (
    input   logic                                               clk             ,
    input   logic                                               rst_n           ,
    input   logic                                               en              ,
    input   logic                                               start           ,
    input   logic                                               incr            ,
    input   ma_pkg::register_file_line_t                        r               ,
    input   ma_pkg::register_file_line_t                        r_k             ,
    output  logic                           [PRF_LOG_N - 1 : 0] i_out           ,
    output  logic                           [PRF_LOG_M - 1 : 0] j_out           ,
    output  logic                               [PRF_P - 1 : 0] row_mask        , // 1 clk after addr
    output  logic                               [PRF_Q - 1 : 0] col_mask        , // 1 clk after addr
    output  logic                                               done            ,
    output  logic                                       [1 : 0] selector    
);

// Local Parameters Definition  ------------------------------------------------------------------------------
localparam PRF_N_LANES  = 2 ** (PRF_LOG_P + PRF_LOG_Q);


// Wires Definition ------------------------------------------------------------------------------------------
logic   [PRF_LOG_P + PRF_LOG_Q - 1 : 0] iteration;
logic iteration_done, kernel_next, done_internal;

logic   [PRF_LOG_P - 1 : 0] row_mask_value;
logic   [PRF_LOG_Q - 1 : 0] col_mask_value;

logic   [PRF_LOG_N : 0]    i_out_internal, i_out_next, i_limit, i_start, i_start_next;
logic   [PRF_LOG_M : 0]    j_out_internal, j_out_internal_mux, j_out_next, j_limit, j_start, j_start_next;
logic   [PRF_LOG_N : 0]    i_kernel, i_kernel_next, i_kernel_limit, i_kernel_next_q;
logic   [PRF_LOG_M : 0]    j_kernel, j_kernel_next, j_kernel_limit, j_kernel_next_q;
logic i_done, j_done, i_kernel_done, j_kernel_done, kernel_done;


// Combinatorial Logic ---------------------------------------------------------------------------------------
always_comb begin
    if ( r.dtype == ma_pkg::UINT32 || r.dtype == ma_pkg::INT32 ) begin
        j_out_internal_mux = j_out_internal;
    end else if ( r.dtype == ma_pkg::UINT16 || r.dtype == ma_pkg::INT16 ) begin
        j_out_internal_mux = {1'd0, j_out_internal[PRF_LOG_M - 1 : 1]};
    end else begin
        j_out_internal_mux = {2'd0, j_out_internal[PRF_LOG_M - 1 : 2]};
    end
end

assign i_kernel_next = i_kernel + (2 ** PRF_LOG_P);
assign j_kernel_next = j_kernel + (2 ** PRF_LOG_Q);
assign i_done = i_start > i_limit;
assign j_done = j_out_internal - j_kernel >= j_limit;
assign i_kernel_done = i_kernel_next >= i_kernel_limit;
assign j_kernel_done = j_kernel_next >= j_kernel_limit;
assign done_internal = en & incr & i_done & j_done & iteration_done & (~|i_kernel) & (~|j_kernel);
assign iteration_done = &iteration;
assign kernel_next = &iteration[PRF_LOG_P + PRF_LOG_Q - 1 : 1] & ~iteration[0] & incr;
assign kernel_done = i_kernel_done & j_kernel_done;

always_comb begin
    i_out_next = i_out_internal;
    if ( iteration_done ) begin
        i_out_next = i_start + i_kernel;
    end
end

always_comb begin
    j_out_next = j_out_internal;
    if ( iteration_done ) begin
            j_out_next = j_start + j_kernel;
    end else begin
        if ( ~j_done )
            j_out_next = j_out_internal + 1'b1;    
    end
end

always_comb begin
    i_start_next = i_start;
    if ( kernel_done & j_done )
        i_start_next = i_start + 1'b1;
end

always_comb begin
    j_start_next = j_start;
    if ( kernel_done ) begin
        if ( j_done )
            j_start_next = 'd0;
        else
            j_start_next = j_out_internal + 2'd2 - j_kernel;
    end
end


// Sequential Logic ------------------------------------------------------------------------------------------
always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        i_out <= 'd0;
        j_out <= 'd0;
        selector <= 'd0;
        done <= 1'b0;
    end else if ( en & incr ) begin
        i_out <= r.prf_x[PRF_LOG_N - 1 : 0] + i_out_internal;
        j_out <= r.prf_y[PRF_LOG_M - 1 : 0] + j_out_internal_mux;
        selector <= j_out_internal[1 : 0];
        done <= done_internal;
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        i_limit <= 'd0;
        j_limit <= 'd0;
    end else if ( en & start ) begin
        i_limit <= r.height[PRF_LOG_N : 0] - r_k.height[PRF_LOG_N : 0];
        j_limit <= r.width[PRF_LOG_M : 0] - r_k.width[PRF_LOG_M : 0];
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        i_kernel_limit <= 'd0;
        j_kernel_limit <= 'd0;
    end else if ( en & start ) begin
        i_kernel_limit <= r_k.height[PRF_LOG_N : 0];
        j_kernel_limit <= r_k.width[PRF_LOG_M : 0];
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   i_kernel <= 'd0;                        else
    if ( done_internal )            i_kernel <= 'd0;                        else
    if ( en ) begin
        if ( start )                i_kernel <= 'd0;                        else
        if ( kernel_next ) begin 
            if ( kernel_done )      i_kernel <= 'd0;                        else
            if ( j_kernel_done )    i_kernel <= i_kernel_next;
        end
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   j_kernel <= 'd0;                        else
    if ( done_internal )            j_kernel <= 'd0;                        else
    if ( en ) begin
        if ( start )                j_kernel <= 'd0;                        else
        if ( kernel_next ) begin
            if ( j_kernel_done )    j_kernel <= 'd0;                        else
                                    j_kernel <= j_kernel_next;
        end
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   iteration <= 'd0;                       else
    if ( done_internal )            iteration <= 'd0;                       else
    if ( en ) begin
        if ( start )                iteration <= 'd0;                       else
        if ( incr )                 iteration <= iteration + 1'b1;
    end


always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   i_out_internal <= 'd0;                  else
    if ( done_internal )            i_out_internal <= 'd0;                  else
    if ( en ) begin
        if ( start )                i_out_internal <= 'd0;                  else
        if ( incr  )                i_out_internal <= i_out_next;       
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   j_out_internal<= 'd0;                   else
    if ( done_internal )            j_out_internal<= 'd0;                   else
    if ( en ) begin
        if ( start )                j_out_internal<= 'd0;                   else
        if ( incr )                 j_out_internal<= j_out_next;
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   i_start <= 'd0;                         else
    if ( done_internal )            i_start <= 'd0;                         else
    if ( en ) begin
        if ( start )                i_start <= 'd0;                         else
        if ( kernel_next )          i_start <= i_start_next;
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   j_start <= 'd0;                         else
    if ( done_internal )            j_start <= 'd0;                         else
    if ( en ) begin
        if ( start )                j_start <= 'd0;                         else
        if ( kernel_next )          j_start <= j_start_next;
    end
   
always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        i_kernel_next_q <= 'd0;
        j_kernel_next_q <= 'd0;
    end else if ( en ) begin
        i_kernel_next_q <= i_kernel_next;
        j_kernel_next_q <= j_kernel_next;
    end

generate;
    if ( PRF_LOG_P != 0 ) begin
always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        row_mask_value <= 'd0;
    end else if ( en ) begin
        row_mask_value <= i_kernel_next_q < r_k.height ? 'd0 : r_k.height[PRF_LOG_P - 1 : 0];
    end
    end else begin
always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        row_mask_value <= 'd0;
    end
    end
endgenerate

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        col_mask_value <= 'd0;
    end else if ( en ) begin
        col_mask_value <= j_kernel_next_q < r_k.width ? 'd0 : r_k.width[PRF_LOG_Q - 1 : 0];
    end


// Modules Instances -----------------------------------------------------------------------------------------
mask_generator #(
    .PRF_LOG_PARAM  ( PRF_LOG_P )
) i_row_mask_generator (
    .clk    ( clk           ),
    .rst_n  ( rst_n         ),
    .en     ( en            ),
    .value  ( row_mask_value),
    .mask   ( row_mask      )
);

mask_generator #(
    .PRF_LOG_PARAM  ( PRF_LOG_Q )
) i_col_mask_generator (
    .clk    ( clk           ),
    .rst_n  ( rst_n         ),
    .en     ( en            ),
    .value  ( col_mask_value),
    .mask   ( col_mask      )
);


endmodule