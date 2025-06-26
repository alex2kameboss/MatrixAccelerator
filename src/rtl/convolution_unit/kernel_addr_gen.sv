module kernel_addr_gen #(
    parameter   PRF_LOG_P   =   1   ,
    parameter   PRF_LOG_Q   =   2   ,
    parameter   PRF_LOG_N   =   10  ,
    parameter   PRF_LOG_M   =   10  
) (
    input   logic                                               clk     ,
    input   logic                                               rst_n   ,
    input   logic                                               en      ,
    input   logic                                               start   ,
    input   logic                                               incr    ,
    input   ma_pkg::register_file_line_t                        r       ,
    output  logic                        [PRF_LOG_N - 1 : 0]    i_out   ,
    output  logic                        [PRF_LOG_M - 1 : 0]    j_out   
);

// Local Parameters Definition  ------------------------------------------------------------------------------
localparam PRF_N_LANES  = 2 ** (PRF_LOG_P + PRF_LOG_Q);


// Wires Definition ------------------------------------------------------------------------------------------
logic   [PRF_LOG_P + PRF_LOG_Q - 1 : 0] iteration;
logic                                   iteration_done;
logic   [PRF_LOG_N : 0]    i_kernel, i_kernel_next, i_kernel_limit;
logic   [PRF_LOG_M : 0]    j_kernel, j_kernel_next, j_kernel_limit, j_kernel_mux;
logic   i_kernel_done, j_kernel_done, kernel_done;


// Combinatorial Logic ---------------------------------------------------------------------------------------
assign i_out = r.prf_x[PRF_LOG_N - 1 : 0] + i_kernel;
assign j_out = r.prf_y[PRF_LOG_M - 1 : 0] + j_kernel_mux;
assign iteration_done = &iteration;

always_comb begin
    if ( r.dtype == ma_pkg::UINT32 || r.dtype == ma_pkg::INT32 ) begin
        j_kernel_mux = j_kernel;
    end else if ( r.dtype == ma_pkg::UINT16 || r.dtype == ma_pkg::INT16 ) begin
        j_kernel_mux = {1'd0, j_kernel[PRF_LOG_M - 1 : 1]};
    end else begin
        j_kernel_mux = {2'd0, j_kernel[PRF_LOG_M - 1 : 2]};
    end
end

assign i_kernel_next = i_kernel + (2 ** PRF_LOG_P);
assign j_kernel_next = j_kernel + (2 ** PRF_LOG_Q);
assign i_kernel_done = i_kernel_next >= i_kernel_limit;
assign j_kernel_done = j_kernel_next >= j_kernel_limit;
assign kernel_done = i_kernel_done & j_kernel_done;

// Sequential Logic ------------------------------------------------------------------------------------------
always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        i_kernel_limit <= 'd0;
        j_kernel_limit <= 'd0;
    end else if ( en & start ) begin
        i_kernel_limit <= r.height[PRF_LOG_N : 0];
        j_kernel_limit <= r.width[PRF_LOG_M : 0];
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   i_kernel <= 'd0;                        else
    if ( en & iteration_done ) begin
        if ( start )                i_kernel <= 'd0;                        else
        if ( j_kernel_done ) begin
            if ( ~i_kernel_done)    i_kernel <= i_kernel_next;              else
                                    i_kernel <= 'd0;
                                    
        end
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   j_kernel <= 'd0;                        else
    if ( en & iteration_done ) begin
        if ( start )                j_kernel <= 'd0;                        else
        if ( j_kernel_done )        j_kernel <= 'd0;                        else
                                    j_kernel <= j_kernel_next;
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   iteration <= 'd0;                       else
    if ( en ) begin
        if ( start )                iteration <= 'd0;                       else
        if ( incr )                 iteration <= iteration + 1'b1;
    end

// Modules Instances -----------------------------------------------------------------------------------------



endmodule