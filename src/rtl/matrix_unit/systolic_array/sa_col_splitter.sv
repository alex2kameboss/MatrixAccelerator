// TODO: update for one operand

module sa_col_splitter #(
    parameter   IN_DATA_WIDTH  =    128                 ,
    parameter   OUT_DATA_WIDTH =    32                  ,
    localparam  NUMBER_OF_ALU  =    IN_DATA_WIDTH / 8  
) (
    input   logic                               clk                             ,
    input   logic                               rst_n                           ,
    input   logic                               reset                           ,
    input   logic                               en                              ,
    input   ma_pkg::dtype_t                     dtype                           ,
    input   logic   [IN_DATA_WIDTH - 1 : 0]     op_in                           ,
    output  logic   [OUT_DATA_WIDTH - 1 : 0]    op_out [NUMBER_OF_ALU - 1 : 0]     
);

localparam INPUT_BYTES = IN_DATA_WIDTH / 8;

logic is_signed;

assign is_signed = dtype == ma_pkg::INT32 | dtype == ma_pkg::INT16 | dtype == ma_pkg::INT8;

logic [7 : 0] op_in_byte [INPUT_BYTES - 1 : 0];

genvar i_split;
generate
    for ( i_split = 0 ; i_split < INPUT_BYTES; i_split = i_split + 1 ) begin : splitter_loop
assign op_in_byte[i_split] = op_in[(i_split + 1) * 8 - 1 -: 8];
    end
endgenerate

genvar i;

generate
    for ( i = 0; i < NUMBER_OF_ALU / 4; i = i + 1 ) begin : dtype_selection_32b
always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )
        op_out[i] <= 'd0;
    else if (en) begin
        if ( dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32 ) begin
            op_out[i] <= op_in[(i + 1) * OUT_DATA_WIDTH - 1 -: OUT_DATA_WIDTH];
        end else if ( dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16 ) begin
            op_out[i] <= {{(OUT_DATA_WIDTH - 16){is_signed & op_in_byte[2 * i + 1][7]}}, op_in_byte[2 * i + 1], op_in_byte[2 * i + 0]};
        end else begin
            op_out[i] <= {{(OUT_DATA_WIDTH - 8){is_signed & op_in_byte[i][7]}}, op_in_byte[i]};
        end
    end
end

for ( i = NUMBER_OF_ALU / 4; i < NUMBER_OF_ALU / 2; i = i + 1 ) begin : dtype_selection_16b
always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )
        op_out[i] <= 'd0;
    else if (en) begin
        if ( dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32 ) begin
            op_out[i] <= 'd0;
        end else if ( dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16 ) begin
            op_out[i] <= {{(OUT_DATA_WIDTH - 16){is_signed & op_in_byte[2 * i + 1][7]}}, op_in_byte[2 * i + 1], op_in_byte[2 * i + 0]};
        end else begin
            op_out[i] <= {{(OUT_DATA_WIDTH - 8){is_signed & op_in_byte[i][7]}}, op_in_byte[i]};
        end
    end
end

for ( i = NUMBER_OF_ALU / 2; i < NUMBER_OF_ALU; i = i + 1 ) begin : dtype_selection_8b
always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )
        op_out[i] <= 'd0;
    else if (en) begin
        if ( dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32 ) begin
            op_out[i] <= 'd0;
        end else if ( dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16 ) begin
            op_out[i] <= 'd0;
        end else begin
            op_out[i] <= {{(OUT_DATA_WIDTH - 8){is_signed & op_in_byte[i][7]}}, op_in_byte[i]};
        end
    end
end

endgenerate

endmodule