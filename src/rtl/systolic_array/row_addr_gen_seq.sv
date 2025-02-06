module row_addr_gen_seq #(
    parameter                           PRF_N_LANES =   8           ,
    parameter                           PRF_LOG_N   =   10          ,
    parameter                           PRF_LOG_M   =   10          
) (
    input   logic                                               clk     ,
    input   logic                                               rst_n   ,
    input   logic                                               en      ,
    input   logic                                               start   ,
    input   logic                                               incr    ,
    input   ma_pkg::register_file_line_t                        r       ,
    input   logic                        [31 : 0]               repeater,
    output  logic                        [PRF_LOG_N - 1 : 0]    i_out   ,
    output  logic                        [PRF_LOG_M - 1 : 0]    j_out   ,
    output  logic                                               done    
);
    
logic   [PRF_LOG_N : 0]    i_out_next, i_limit;
logic   [PRF_LOG_M : 0]    j_out_next, j_limit;
logic   [31 : 0]           repeater_cnt, repeater_cnt_next, repeater_limit;
logic i_done, j_done, repeater_done;


assign i_done = i_out_next - r.prf_x[PRF_LOG_N - 1 : 0] >= i_limit;
assign j_done = j_out_next - r.prf_y[PRF_LOG_M - 1 : 0] >= j_limit;
assign repeater_done = repeater_cnt_next >= repeater_limit;
assign done = en & incr & i_done & j_done & repeater_done;

assign repeater_cnt_next = repeater_cnt + PRF_N_LANES;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        i_limit <= 'd0;
        j_limit <= 'd0;
        repeater_limit <= 'd0;
    end else if ( en & start ) begin
        i_limit <= r.height[PRF_LOG_N : 0];
        repeater_limit <= repeater;
        if ( r.dtype == ma_pkg::UINT32 || r.dtype == ma_pkg::INT32 ) begin
            j_limit <= r.width[PRF_LOG_M : 0];
        end else if ( r.dtype == ma_pkg::UINT16 || r.dtype == ma_pkg::INT16 ) begin
            j_limit <= r.width[PRF_LOG_M + 1 : 1];
        end else begin
            j_limit <= r.width[PRF_LOG_M + 2 : 2];
        end
    end


assign i_out_next = i_out + PRF_N_LANES;
assign j_out_next = j_out + 1'b1;    


always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   repeater_cnt <= 'd0;                else
    if ( done )                     repeater_cnt <= 'd0;                else
    if ( en & start )               repeater_cnt <= 'd0;                else
    if ( en & incr & j_done ) begin
        if ( repeater_done )        repeater_cnt <= 'd0;                else
                                    repeater_cnt <= repeater_cnt_next;
    end      

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   i_out <= 'd0;                       else
    if ( done )                     i_out <= 'd0;                       else
    if ( en & start )               i_out <= r.prf_x[PRF_LOG_N - 1 : 0];else
    if ( en & incr & 
            j_done & repeater_done )i_out <= i_out_next[PRF_LOG_N - 1 : 0];

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   j_out <= 'd0;                       else
    if ( done )                     j_out <= 'd0;                       else
    if ( en & start )               j_out <= r.prf_y[PRF_LOG_M - 1 : 0];else
    if ( en & incr ) begin
        if ( j_done )               j_out <= r.prf_y[PRF_LOG_M - 1 : 0];else
                                    j_out <= j_out_next[PRF_LOG_M - 1 : 0];
    end

endmodule