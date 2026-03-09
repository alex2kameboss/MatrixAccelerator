module sa_col_splitter #(
    parameter   IN_DATA_WIDTH  =    128                 ,
    parameter   OUT_DATA_WIDTH =    32                  ,
    parameter   NO_LANES       =    8                   
) (
    input   logic                               clk                             ,
    input   logic                               rst_n                           ,
    input   logic                               reset                           ,
    input   logic                               en                              ,
    input   ma_pkg::dtype_t                     dtype                           ,
    input   logic   [IN_DATA_WIDTH - 1 : 0]     op_in                           ,
    output  logic   [OUT_DATA_WIDTH - 1 : 0]    op_out [NO_LANES - 1 : 0]       ,
    input   logic   [1 : 0]                     g_sel                           
);

logic is_signed;

logic   [IN_DATA_WIDTH / 2 - 1 : 0] group_16b [1 : 0], group16b_sel;
logic   [IN_DATA_WIDTH / 4 - 1 : 0] group_8b  [3 : 0], group8b_sel;

logic   [31 : 0]    data_out_32b [NO_LANES - 1 : 0];
logic   [16 : 0]    data_out_16b [NO_LANES - 1 : 0];
logic    [7 : 0]    data_out_8b  [NO_LANES - 1 : 0];

assign is_signed = dtype == ma_pkg::INT32 | dtype == ma_pkg::INT16 | dtype == ma_pkg::INT8;

assign group_16b[0] = op_in[1 * (IN_DATA_WIDTH / 2) - 1 -: (IN_DATA_WIDTH / 2)];
assign group_16b[1] = op_in[2 * (IN_DATA_WIDTH / 2) - 1 -: (IN_DATA_WIDTH / 2)];

assign group16b_sel = group_16b[g_sel[0]];

assign group_8b[0] = op_in[1 * (IN_DATA_WIDTH / 4) - 1 -: (IN_DATA_WIDTH / 4)];
assign group_8b[1] = op_in[2 * (IN_DATA_WIDTH / 4) - 1 -: (IN_DATA_WIDTH / 4)];
assign group_8b[2] = op_in[3 * (IN_DATA_WIDTH / 4) - 1 -: (IN_DATA_WIDTH / 4)];
assign group_8b[3] = op_in[4 * (IN_DATA_WIDTH / 4) - 1 -: (IN_DATA_WIDTH / 4)];

assign group8b_sel = group_8b[g_sel];

genvar iter_splitter;

generate;
    for ( iter_splitter = 0; iter_splitter < NO_LANES; iter_splitter = iter_splitter + 1 ) begin : out_splitter
assign data_out_32b[iter_splitter] = op_in[(iter_splitter + 1) * 32 - 1 -: 32];
assign data_out_16b[iter_splitter] = group16b_sel[(iter_splitter + 1) * 16 - 1 -: 16];
assign data_out_8b[iter_splitter] = group8b_sel[(iter_splitter + 1) * 8 - 1 -: 8];
    end
endgenerate

genvar iter_out;

generate;
    for ( iter_out = 0; iter_out < NO_LANES; iter_out = iter_out + 1 ) begin : dtype_selection
always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )
        op_out[iter_out] <= 'd0;
    else if (en) begin
        if ( dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32 ) begin
            op_out[iter_out] <= data_out_32b[iter_out];
        end else if ( dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16 ) begin
            op_out[iter_out] <= {{(OUT_DATA_WIDTH - 16){is_signed & data_out_16b[iter_out][15]}}, data_out_16b[iter_out]};
        end else begin
            op_out[iter_out] <= {{(OUT_DATA_WIDTH - 8){is_signed & data_out_8b[iter_out][7]}}, data_out_8b[iter_out]};
        end
    end
    end
endgenerate

endmodule