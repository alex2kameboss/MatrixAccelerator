module prf_complex_addr_gen_seq #(
    parameter                           PRF_N_LANES =   8                   ,
    parameter                           PRF_LOG_N   =   10                  ,
    parameter                           PRF_LOG_M   =   10                  ,
    localparam                          LOG_N_LANES =   $clog2(PRF_N_LANES) 
) (
    input   logic                                           clk     ,
    input   logic                                           rst_n   ,
    input   logic                                           en      ,
    input   logic                                           start   ,
    input   logic                                           incr    ,
    input   ma_pkg::register_file_line_t                    r       ,
    output  logic                       [PRF_LOG_N - 1 : 0] i_re_out,
    output  logic                       [PRF_LOG_M - 1 : 0] j_re_out,
    output  logic                       [PRF_LOG_N - 1 : 0] i_im_out,
    output  logic                       [PRF_LOG_M - 1 : 0] j_im_out,
    output  logic                                           done    
);
    
logic   [PRF_LOG_N + 1 : 0]    i_out_next, i_limit;
logic   [PRF_LOG_M + 1 : 0]    j_out_next, j_limit;
logic i_done, j_done;

assign i_done = $signed(i_out_next - r.prf_x[PRF_LOG_N - 1 : 0]) >= $signed(i_limit);
assign j_done = $signed(j_out_next - r.prf_y[PRF_LOG_M - 1 : 0]) >= $signed(j_limit);
assign done = en & incr & i_done & j_done;

assign i_out_next = i_re_out + 2'd2;
assign j_out_next = j_re_out + PRF_N_LANES;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        i_limit <= 'd0;
        j_limit <= 'd0;
    end else if ( en & start ) begin
        i_limit <= r.height[PRF_LOG_N + 1 : 0];
        if ( r.dtype == ma_pkg::UINT32 || r.dtype == ma_pkg::INT32 ) begin
            j_limit <= r.width[PRF_LOG_M + 1 : 0];
        end else if ( r.dtype == ma_pkg::UINT16 || r.dtype == ma_pkg::INT16 ) begin
            j_limit <= r.width[PRF_LOG_M + 2 : 1];
        end else begin
            j_limit <= r.width[PRF_LOG_M + 3 : 2];
        end
    end

assign j_im_out = j_re_out;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   i_re_out <= 'd0;                       else
    if ( done )                     i_re_out <= 'd0;                       else
    if ( en & start )               i_re_out <= r.prf_x[PRF_LOG_N - 1 : 0];else
    if ( en & incr & j_done )       i_re_out <= i_out_next[PRF_LOG_N - 1 : 0];

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   j_re_out <= 'd0;                       else
    if ( done )                     j_re_out <= 'd0;                       else
    if ( en & start )               j_re_out <= r.prf_y[PRF_LOG_M - 1 : 0];else
    if ( en & incr ) begin
        if ( j_done )               j_re_out <= r.prf_y[PRF_LOG_M - 1 : 0];else
                                    j_re_out <= j_out_next[PRF_LOG_M - 1 : 0];
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   i_im_out <= 'd0;                                else
    if ( done )                     i_im_out <= 'd0;                                else
    if ( en & start )               i_im_out <= r.prf_x[PRF_LOG_N - 1 : 0] + 1'b1;  else
    if ( en & incr & j_done )       i_im_out <= i_out_next[PRF_LOG_N - 1 : 0] + 1'b1;

endmodule