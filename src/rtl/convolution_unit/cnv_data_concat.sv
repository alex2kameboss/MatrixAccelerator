module cnv_data_concat #(
    parameter   PRF_N_LANES     =   8   ,
    parameter   IN_DATA_WIDTH   =   32  ,
    parameter   PRF_LOG_N       =   10  ,
    parameter   PRF_LOG_M       =   10  ,
    localparam  OUT_DATA_WIDTH  =   PRF_N_LANES * IN_DATA_WIDTH   
) (
    input   logic                                                   clk                                         ,
    input   logic                                                   rst_n                                       ,
    input   logic                                                   reset                                       ,
    input   logic                                                   en                                          ,
    input   ma_pkg::register_file_line_t                            r                                           ,
    input   logic                                                   array_rst_n [PRF_N_LANES - 1 : 0][ 0 : 0]   ,
    input   logic                        [IN_DATA_WIDTH - 1 : 0]    res_sa      [PRF_N_LANES - 1 : 0][ 0 : 0]   ,
    output  logic                       [OUT_DATA_WIDTH - 1 : 0]    res_out                                     ,
    output  logic                                                   valid                                       ,
    output  logic                            [PRF_LOG_N - 1 : 0]    i_out                                       ,
    output  logic                            [PRF_LOG_M - 1 : 0]    j_out                                       ,
    output  logic                          [PRF_N_LANES - 1 : 0]    lane_valid                                  ,
    output  logic                                                   done                                        
);

// Local Parameters Definition  ------------------------------------------------------------------------------
localparam PRF_LOG_N_LANES  =   $clog2(PRF_N_LANES);


// Wires Definition ------------------------------------------------------------------------------------------
logic   [PRF_LOG_N_LANES - 1 : 0]   iteration_32b;
logic   [PRF_LOG_N_LANES + 0 : 0]   iteration_16b;
logic   [PRF_LOG_N_LANES + 1 : 0]   iteration_8b;
logic   iteration_done, iteration_32b_done, iteration_16b_done, iteration_8b_done;
wor     incr;
logic   [PRF_LOG_N : 0] i_out_next;
logic   [PRF_LOG_M : 0] j_out_next, j_out_internal_next;
logic   [PRF_LOG_M - 1 : 0] j_out_internal;
logic   i_done, j_done;

logic   [OUT_DATA_WIDTH - 1 : 0]    res_out_d;
logic   [4 * PRF_N_LANES - 1 : 0]   lane_valid_d, lane_valid_q;

logic   [IN_DATA_WIDTH - 1 : 0]    res_in;
logic   [ 32 - 1 : 0 ]  res_in_32b;
logic   [ 16 - 1 : 0 ]  res_in_16b;
logic    [ 8 - 1 : 0 ]  res_in_8b;

logic   [PRF_LOG_N - 1 : 0]    i_out_before;
logic   [PRF_LOG_M - 1 : 0]    j_out_before;

logic [1 : 0]   cnt;
logic           valid_8b, valid_16b, valid_32b;


// Combinatorial Logic ---------------------------------------------------------------------------------------
assign iteration_32b_done = &iteration_32b;
assign iteration_16b_done = &iteration_16b;
assign iteration_8b_done = &iteration_8b;

always_comb begin
    if ( r.dtype == ma_pkg::UINT32 || r.dtype == ma_pkg::INT32 ) begin
        iteration_done = iteration_32b_done;
    end else if ( r.dtype == ma_pkg::UINT16 || r.dtype == ma_pkg::INT16 ) begin
        iteration_done = iteration_16b_done;
    end else begin
        iteration_done = iteration_8b_done;
    end
end

assign res_in = j_done ? 'd0 : res_sa[iteration_32b][0];
assign res_in_32b = res_in[32 - 1 : 0];
assign res_in_16b = res_in[16 - 1 : 0];
assign res_in_8b = res_in[8 - 1 : 0];

assign i_out_next = i_out_before + 1'b1;
assign j_out_next = j_out_before + PRF_N_LANES;
assign j_out_internal_next = j_out_internal + 1'b1;
assign i_done = i_out_next - r.prf_x[PRF_LOG_N - 1 : 0] >= r.height[PRF_LOG_N : 0];
assign j_done = j_out_internal >= r.width[PRF_LOG_M : 0];

genvar  incr_idx;
generate;
    for ( incr_idx = 0 ; incr_idx < PRF_N_LANES; incr_idx = incr_idx + 1 ) begin : incr_or_generator
assign incr = ~array_rst_n[incr_idx][0];
assign lane_valid[incr_idx] = |lane_valid_q[4 * (incr_idx + 1) - 1 -: 4];
    end
endgenerate

always_comb begin
    if ( r.dtype == ma_pkg::UINT32 || r.dtype == ma_pkg::INT32 ) begin
        res_out_d = {res_in_32b, res_out[OUT_DATA_WIDTH - 1 : 32]};
    end else if ( r.dtype == ma_pkg::UINT16 || r.dtype == ma_pkg::INT16 ) begin
        res_out_d = {res_in_16b, res_out[OUT_DATA_WIDTH - 1 : 16]};
    end else begin
        res_out_d = {res_in_8b, res_out[OUT_DATA_WIDTH - 1 : 8]};
    end
end

always_comb begin
    if ( r.dtype == ma_pkg::UINT32 || r.dtype == ma_pkg::INT32 ) begin
        lane_valid_d = {{4{~j_done}}, lane_valid_q[4 * PRF_N_LANES - 1 : 4]};
    end else if ( r.dtype == ma_pkg::UINT16 || r.dtype == ma_pkg::INT16 ) begin
        lane_valid_d = {{2{~j_done}}, lane_valid_q[4 * PRF_N_LANES - 1 : 2]};
    end else begin
        lane_valid_d = {~j_done, lane_valid_q[4 * PRF_N_LANES - 1 : 1]};
    end
end

always_comb begin
    if ( r.dtype == ma_pkg::UINT32 || r.dtype == ma_pkg::INT32 ) begin
        valid = valid_32b;
    end else if ( r.dtype == ma_pkg::UINT16 || r.dtype == ma_pkg::INT16 ) begin
        valid = valid_16b;
    end else begin
        valid = valid_8b;
    end
end


// Sequential Logic ------------------------------------------------------------------------------------------
always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   iteration_32b <= 'd0;               else
    if ( en ) begin
        if ( reset )                iteration_32b <= 'd0;               else
        if ( incr )                 iteration_32b <= iteration_32b + 1'b1;
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   iteration_16b <= 'd0;               else
    if ( en ) begin
        if ( reset )                iteration_16b <= 'd0;               else
        if ( incr )                 iteration_16b <= iteration_16b + 1'b1;
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   iteration_8b <= 'd0;                else
    if ( en ) begin
        if ( reset )                iteration_8b <= 'd0;                else
        if ( incr )                 iteration_8b <= iteration_8b + 1'b1;
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   lane_valid_q <= 'd0;                else
    if ( en ) begin
        if ( reset )                lane_valid_q <= 'd0;                else
        if ( incr )                 lane_valid_q <= lane_valid_d;
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   res_out <= 'd0;                     else
    if ( en ) begin
        if ( reset )                res_out <= 'd0;                     else
        if ( incr )                 res_out <= res_out_d;
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   valid_32b <= 'd0;                   else
    if ( en ) begin
        if ( reset )                valid_32b <= 'd0;                   else
                                    valid_32b <= iteration_32b_done;
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   valid_16b <= 'd0;                   else
    if ( en ) begin
        if ( reset )                valid_16b <= 'd0;                   else
                                    valid_16b <= iteration_16b_done;
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   valid_8b <= 'd0;                    else
    if ( en ) begin
        if ( reset )                valid_8b <= 'd0;                    else
                                    valid_8b <= iteration_8b_done;
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   j_out_internal <= 'd0;              else
    if ( en ) begin
        if ( reset )                j_out_internal <= 'd0;              else
        if ( incr ) begin
            if ( j_done & iteration_done ) 
                j_out_internal <= 'd0;
            else
                j_out_internal <= j_out_internal_next[PRF_LOG_M - 1 : 0];
        end
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   i_out_before <= 'd0;                       else
    if ( en ) begin
        if ( reset )                i_out_before <= r.prf_x[PRF_LOG_N - 1 : 0];else
        if ( incr & iteration_done ) begin
            if ( j_done ) 
                i_out_before <= i_out_next[PRF_LOG_N - 1 : 0];
        end
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   j_out_before <= 'd0;                       else
    if ( en ) begin
        if ( reset )                j_out_before <= r.prf_y[PRF_LOG_M - 1 : 0];else
        if ( incr & iteration_done ) begin
            if ( j_done ) 
                j_out_before <= r.prf_y[PRF_LOG_M - 1 : 0];
            else
                j_out_before <= j_out_next[PRF_LOG_M - 1 : 0];
        end
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   i_out <= 'd0;                       else
    if ( en )                       i_out <= i_out_before;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   j_out <= 'd0;                       else
    if ( en )                       j_out <= j_out_before;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   done <= 'd0;                        else
    if ( en ) begin
        if ( reset )                done <= 'd0;                        else
                                    done <= incr & iteration_done & i_done & j_done;      
    end


// Modules Instances -----------------------------------------------------------------------------------------



endmodule