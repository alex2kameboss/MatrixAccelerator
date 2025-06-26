module cnv_data_splitter #(
    parameter   PRF_LOG_P       =   1   ,
    parameter   PRF_LOG_Q       =   2   ,
    parameter   OUT_DATA_WIDTH  =   32  ,
    parameter   NUMBER_OF_ALU   =   2 ** (PRF_LOG_P + PRF_LOG_Q)    ,
    localparam  IN_DATA_WIDTH   =   NUMBER_OF_ALU * OUT_DATA_WIDTH  
) (
    input   logic                               clk                             ,
    input   logic                               rst_n                           ,
    input   logic                               reset                           ,
    input   logic                               en                              ,
    input   logic   [1 : 0]                     selector                        ,
    input   ma_pkg::dtype_t                     dtype                           ,
    input   logic   [IN_DATA_WIDTH - 1 : 0]     op_in                           ,
    output  logic   [OUT_DATA_WIDTH - 1 : 0]    op_out [NUMBER_OF_ALU - 1 : 0]  
);

// Local Parameters Definition  ------------------------------------------------------------------------------
localparam PRF_P = 2 ** PRF_LOG_P;
localparam PRF_Q = 2 ** PRF_LOG_Q;


// Wires Definition ------------------------------------------------------------------------------------------
logic   [ 8 - 1 : 0]    data_8b  [IN_DATA_WIDTH / 8 - 1 : 0];
logic   [16 - 1 : 0]    data_16b[IN_DATA_WIDTH / 16 - 1 : 0];
logic   [32 - 1 : 0]    data_32b[IN_DATA_WIDTH / 32 - 1 : 0];

logic is_signed;


// Combinatorial Logic ---------------------------------------------------------------------------------------
assign is_signed = dtype == ma_pkg::INT32 | dtype == ma_pkg::INT16 | dtype == ma_pkg::INT8;

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

genvar i, j;

generate
    for ( i = 0; i < PRF_P; i = i + 1 ) begin : row_loop
        for ( j = 0; j < PRF_Q; j = j + 1 ) begin : column_loop

logic   [ 8 - 1 : 0]    win_data_8b ;
logic   [16 - 1 : 0]    win_data_16b;
logic   [32 - 1 : 0]    win_data_32b;

assign win_data_8b  = data_8b [i * PRF_Q + j + selector[1 : 0]];
assign win_data_16b = data_16b[i * PRF_Q + j + selector[0]];
assign win_data_32b = data_32b[i * PRF_Q + j];

logic   [OUT_DATA_WIDTH - 1 : 0]    out;

always_comb begin : dtype_selection
    if ( dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32 ) begin
        out = {{(OUT_DATA_WIDTH - 32){is_signed & win_data_32b[31]}}, win_data_32b};
    end else if ( dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16 ) begin
        out = {{(OUT_DATA_WIDTH - 16){is_signed & win_data_16b[15]}}, win_data_16b};
    end else begin
        out = {{(OUT_DATA_WIDTH - 8){is_signed & win_data_8b[7]}}, win_data_8b};
    end
end

always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n ) begin
        op_out[i * PRF_Q + j] <= 'd0;
    end else if ( en )
        op_out[i * PRF_Q + j] <= out;
end
    end
endgenerate

// Sequential Logic ------------------------------------------------------------------------------------------



// Modules Instances -----------------------------------------------------------------------------------------



endmodule