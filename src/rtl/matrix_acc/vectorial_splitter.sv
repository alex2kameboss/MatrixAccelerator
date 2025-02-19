// TODO: update for one operand

module vectorial_splitter #(
    parameter   IN_DATA_WIDTH  =   128  ,
    parameter   OUT_DATA_WIDTH =    32  
) (
    input   logic                               clk                                                 ,
    input   logic                               rst_n                                               ,
    input   logic                               reset                                               ,
    input   logic                               en                                                  ,
    input   ma_pkg::dtype_t                     dtype                                               ,
    input   logic   [IN_DATA_WIDTH - 1 : 0]     op1_in                                              ,
    input   logic   [IN_DATA_WIDTH - 1 : 0]     op2_in                                              ,
    output  logic   [OUT_DATA_WIDTH - 1 : 0]    op1_out [IN_DATA_WIDTH / OUT_DATA_WIDTH - 1 : 0]    ,
    output  logic   [OUT_DATA_WIDTH - 1 : 0]    op2_out [IN_DATA_WIDTH / OUT_DATA_WIDTH - 1 : 0]    ,
    output  logic                               next                                                
);

localparam NUMBER_OF_ALU = IN_DATA_WIDTH / OUT_DATA_WIDTH;
localparam ALU_BYTES = OUT_DATA_WIDTH / 8; 
localparam IN_BYTES = OUT_DATA_WIDTH / 8;

logic   [$clog2(IN_BYTES) - 1 : 0]   cnt;

assign limit = ((dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32) |
                cnt == 'd1 & (dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16) |
                cnt == 'd3 & (dtype == ma_pkg::INT8 | dtype == ma_pkg::UINT8)) & en;
assign next = ((dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32) |
                cnt == 'd0 & (dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16) |
                cnt == 'd2 & (dtype == ma_pkg::INT8 | dtype == ma_pkg::UINT8)) & en; // need early by 1 clk

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       cnt <= 'd0;         else
    if ( reset )                        cnt <= 'd0;         else
    if ( en )   begin
        if ( limit ) 
            cnt <= 'd0; 
        else
            cnt <= cnt + 1'b1;
    end

logic is_signed;

assign is_signed = dtype == ma_pkg::INT32 | dtype == ma_pkg::INT16 | dtype == ma_pkg::INT8;

logic [7 : 0] op1_in_byte [NUMBER_OF_ALU - 1 : 0][IN_BYTES - 1 : 0];
logic [7 : 0] op2_in_byte [NUMBER_OF_ALU - 1 : 0][IN_BYTES - 1 : 0];

genvar i_split, j_split;
generate
    for ( i_split = 0 ; i_split < NUMBER_OF_ALU; i_split = i_split + 1 ) begin : splitter_outer_loop
        for ( j_split = 0; j_split < IN_BYTES; j_split = j_split + 1 ) begin : splitter_inner_loop
assign op1_in_byte[i_split][j_split] = op1_in[i_split * OUT_DATA_WIDTH + (j_split + 1) * 8 - 1 -: 8];
assign op2_in_byte[i_split][j_split] = op2_in[i_split * OUT_DATA_WIDTH + (j_split + 1) * 8 - 1 -: 8];
        end
    end
endgenerate

genvar i;

generate
    for ( i = 0; i < NUMBER_OF_ALU; i = i + 1 ) begin : dtype_selection
always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n ) begin
        op1_out[i] <= 'd0;
        op2_out[i] <= 'd0;
    end else if (en) begin
        if ( dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32 ) begin
            op1_out[i] <= op1_in[(i + 1) * OUT_DATA_WIDTH - 1 -: OUT_DATA_WIDTH];
            op2_out[i] <= op2_in[(i + 1) * OUT_DATA_WIDTH - 1 -: OUT_DATA_WIDTH];
        end else if ( dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16 ) begin
            op1_out[i] <= {{(OUT_DATA_WIDTH - 16){is_signed & op1_in_byte[i][2 * cnt + 1][7]}}, op1_in_byte[i][2 * cnt + 1], op1_in_byte[i][2 * cnt + 0]};
            op2_out[i] <= {{(OUT_DATA_WIDTH - 16){is_signed & op2_in_byte[i][2 * cnt + 1][7]}}, op2_in_byte[i][2 * cnt + 1], op2_in_byte[i][2 * cnt + 0]};
        end else begin
            op1_out[i] <= {{(OUT_DATA_WIDTH - 8){is_signed & op1_in_byte[i][cnt][7]}}, op1_in_byte[i][cnt]};
            op2_out[i] <= {{(OUT_DATA_WIDTH - 8){is_signed & op2_in_byte[i][cnt][7]}}, op2_in_byte[i][cnt]};
        end
    end
end
endgenerate

endmodule