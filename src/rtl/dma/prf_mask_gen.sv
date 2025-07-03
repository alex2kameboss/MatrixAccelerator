module prf_mask_gen #(
    parameter   PRF_N_LANES =   8           ,
    parameter   PRF_LOG_N   =   10          ,
    parameter   PRF_LOG_M   =   10          ,
    parameter   SRAM_WIDTH  =   32          ,
    localparam  SRAM_BYTES  =   SRAM_WIDTH / 8              ,
    localparam  MASK_WIDTH  =   PRF_N_LANES * SRAM_BYTES    
) (
    input   logic                                               clk     ,
    input   logic                                               rst_n   ,
    input   logic                                               en      ,
    input   logic                                               start   ,
    input   logic                                               incr    ,
    input   ma_pkg::register_file_line_t                        r       ,
    output  logic                       [MASK_WIDTH - 1 : 0]    mask    
);
    
localparam SRAM_BYTES_LOG2 = $clog2(SRAM_BYTES);

logic   [$clog2(MASK_WIDTH) - 1 : 0]        mask_value;
logic   [PRF_LOG_M + SRAM_BYTES_LOG2 : 0]   j_out, j_out_next, j_limit; // number of bytes
logic   j_done;

assign j_done = j_out_next >= j_limit;

assign j_out_next = j_out + MASK_WIDTH;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        j_limit <= 'd0;
    end else if ( en & start ) begin
        if ( r.dtype == ma_pkg::UINT32 || r.dtype == ma_pkg::INT32 ) begin
            j_limit <= {r.width[PRF_LOG_M + SRAM_BYTES_LOG2 - 2 : 0], 2'd0}; // * 4
        end else if ( r.dtype == ma_pkg::UINT16 || r.dtype == ma_pkg::INT16 ) begin
            j_limit <= {r.width[PRF_LOG_M + SRAM_BYTES_LOG2 - 1 : 0], 1'b0}; // * 2
        end else begin
            j_limit <= r.width[PRF_LOG_M + SRAM_BYTES_LOG2 : 0];
        end
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                   j_out <= 'd0;                       else
    if ( en ) begin
        if ( start )                j_out <= 'd0;                       else
        if ( incr ) begin
            if ( j_done )           j_out <= 'd0;                       else
                                    j_out <= j_out_next;
        end
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        mask_value <= 'd0;
    end else if ( en ) begin
        mask_value <= j_out_next < j_limit ? 'd0 : j_limit[$clog2(MASK_WIDTH) - 1 : 0];
    end

mask_generator #(
    .PRF_LOG_PARAM  ( $clog2(MASK_WIDTH)),
    .FF_OUT         ( 0                 )
) i_mask_generator (
    .clk    ( clk           ),
    .rst_n  ( rst_n         ),
    .en     ( en            ),
    .value  ( mask_value    ),
    .mask   ( mask          )
);

endmodule