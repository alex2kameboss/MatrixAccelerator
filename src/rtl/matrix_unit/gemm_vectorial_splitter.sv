module gemm_vectorial_splitter #(
    parameter   IN_DATA_WIDTH  =   128  ,
    parameter   OUT_DATA_WIDTH =    32  
) (
    input   logic                               clk                                                 ,
    input   logic                               rst_n                                               ,
    input   logic                               reset                                               ,
    input   logic                               en                                                  ,
    input   ma_pkg::dtype_t                     dtype                                               ,
    input   logic   [IN_DATA_WIDTH - 1 : 0]     op_in                                               ,
    output  logic   [OUT_DATA_WIDTH - 1 : 0]    op_out [IN_DATA_WIDTH / OUT_DATA_WIDTH - 1 : 0]     ,
    output  logic                               next                                                
);

localparam NUMBER_OF_ALU = IN_DATA_WIDTH / OUT_DATA_WIDTH;
localparam ALU_BYTES = OUT_DATA_WIDTH / 8; 
localparam IN_BYTES = OUT_DATA_WIDTH / 8;

logic       [$clog2(IN_BYTES) - 1 : 0]  cnt, cnt_8b;
logic   [$clog2(IN_BYTES / 2) - 1 : 0]  cnt_16b;
logic                                   cnt_32b;
logic                                   limit;

logic   [ 8 - 1 : 0]    data_8b  [IN_DATA_WIDTH / 8 - 1 : 0];
logic   [16 - 1 : 0]    data_16b[IN_DATA_WIDTH / 16 - 1 : 0];
logic   [32 - 1 : 0]    data_32b[IN_DATA_WIDTH / 32 - 1 : 0];

logic is_signed;

assign limit = ((dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32) |
                cnt == 'd1 & (dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16) |
                cnt == 'd3 & (dtype == ma_pkg::INT8 | dtype == ma_pkg::UINT8)) & en;
assign next = ((dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32) |
                cnt == 'd0 & (dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16) |
                cnt == 'd2 & (dtype == ma_pkg::INT8 | dtype == ma_pkg::UINT8)) & en; // need early by 1 clk

assign cnt_8b = cnt;
assign cnt_16b = cnt[$clog2(IN_BYTES - 2) - 1 : 0];
assign cnt_32b = 1'b0; // TODO: improve

genvar i_8b, i_16b, i_32b;

generate
    for ( i_32b = 0; i_32b < IN_DATA_WIDTH / 32; i_32b = i_32b + 1 ) begin : loop_32b_data
assign data_32b[i_32b] = op_in[(i_32b + 1) * 32 - 1 -: 32];
    end
endgenerate

generate
    for ( i_16b = 0; i_16b < IN_DATA_WIDTH / 16; i_16b = i_16b + 1 ) begin : loop_16b_data
assign data_16b[i_16b] = op_in[(i_16b + 1) * 16 - 1 -: 16];
    end
endgenerate

generate
    for ( i_8b = 0; i_8b < IN_DATA_WIDTH / 8; i_8b = i_8b + 1 ) begin : loop_8b_data
assign data_8b[i_8b] = op_in[(i_8b + 1) * 8 - 1 -: 8];
    end
endgenerate

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       cnt <= 'd0;         else
    if ( reset )                        cnt <= 'd0;         else
    if ( en )   begin
        if ( limit ) 
            cnt <= 'd0; 
        else
            cnt <= cnt + 1'b1;
    end

assign is_signed = dtype == ma_pkg::INT32 | dtype == ma_pkg::INT16 | dtype == ma_pkg::INT8;

genvar i;

generate
    for ( i = 0; i < NUMBER_OF_ALU; i = i + 1 ) begin : dtype_selection

logic   [ 8 - 1 : 0]    mux_data_8b [OUT_DATA_WIDTH / 8  - 1 : 0];
logic   [16 - 1 : 0]    mux_data_16b[OUT_DATA_WIDTH / 16 - 1 : 0];
logic   [32 - 1 : 0]    mux_data_32b[OUT_DATA_WIDTH / 32 - 1 : 0];

assign mux_data_8b  = data_8b [(i + 1) * OUT_DATA_WIDTH / 8  - 1 -: OUT_DATA_WIDTH / 8 ];
assign mux_data_16b = data_16b[(i + 1) * OUT_DATA_WIDTH / 16 - 1 -: OUT_DATA_WIDTH / 16];
assign mux_data_32b = data_32b[(i + 1) * OUT_DATA_WIDTH / 32 - 1 -: OUT_DATA_WIDTH / 32];

logic   [ 8 - 1 : 0]    win_data_8b ;
logic   [16 - 1 : 0]    win_data_16b;
logic   [32 - 1 : 0]    win_data_32b;

assign win_data_8b  = mux_data_8b [cnt_8b];
assign win_data_16b = mux_data_16b[cnt_16b];
assign win_data_32b = mux_data_32b[cnt_32b];

logic   [OUT_DATA_WIDTH - 1 : 0]    out;

always_comb
    if ( dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32 ) begin
        out = {{(OUT_DATA_WIDTH - 32){is_signed & win_data_32b[31]}}, win_data_32b};
    end else if ( dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16 ) begin
        out = {{(OUT_DATA_WIDTH - 16){is_signed & win_data_16b[15]}}, win_data_16b};
    end else begin
        out = {{(OUT_DATA_WIDTH - 8){is_signed & win_data_8b[7]}}, win_data_8b};
    end

always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n ) begin
        op_out[i] <= 'd0;
    end else if (en)
        op_out[i] <= out;
end
endgenerate

endmodule