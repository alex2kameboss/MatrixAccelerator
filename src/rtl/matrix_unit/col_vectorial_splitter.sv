module col_vectorial_splitter #(
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

logic   [$clog2(IN_BYTES) - 1 : 0]   cnt;

logic   [OUT_DATA_WIDTH - 1 : 0]    op_out_32b [NUMBER_OF_ALU - 1 : 0]; 
logic   [OUT_DATA_WIDTH - 1 : 0]    op_out_16b [NUMBER_OF_ALU * 2 - 1 : 0]; 
logic   [OUT_DATA_WIDTH - 1 : 0]    op_out_8b  [NUMBER_OF_ALU * 4 - 1 : 0];
logic is_signed;

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

genvar loop_32b, loop_16b, loop_8b;

generate
    for ( loop_32b = 0; loop_32b < NUMBER_OF_ALU; loop_32b = loop_32b + 1 ) begin : assign_32b_data
assign op_out_32b[loop_32b] = op_in[(loop_32b + 1) * OUT_DATA_WIDTH - 1 -: OUT_DATA_WIDTH];
    end
endgenerate

generate  
    for ( loop_16b = 0; loop_16b < NUMBER_OF_ALU; loop_16b = loop_16b + 1 ) begin : assign_16b_data
assign op_out_16b[2 * loop_16b + 0] = {{(OUT_DATA_WIDTH / 2){is_signed & op_in[((2 * loop_16b + 0) + 1) * OUT_DATA_WIDTH / 2 - 1]}}, op_in[((2 * loop_16b + 0) + 1) * OUT_DATA_WIDTH / 2 - 1 -: OUT_DATA_WIDTH / 2]};
assign op_out_16b[2 * loop_16b + 1] = {{(OUT_DATA_WIDTH / 2){is_signed & op_in[((2 * loop_16b + 1) + 1) * OUT_DATA_WIDTH / 2 - 1]}}, op_in[((2 * loop_16b + 1) + 1) * OUT_DATA_WIDTH / 2 - 1 -: OUT_DATA_WIDTH / 2]};
    end
endgenerate

generate
    for ( loop_8b = 0; loop_8b < NUMBER_OF_ALU; loop_8b = loop_8b + 1 ) begin : assign_8b_data
assign op_out_8b[4 * loop_8b + 0] = {{(OUT_DATA_WIDTH * 3 / 4){is_signed & op_in[((4 * loop_8b + 0) + 1) * OUT_DATA_WIDTH / 4 - 1]}}, op_in[((4 * loop_8b + 0) + 1) * OUT_DATA_WIDTH / 4 - 1 -: OUT_DATA_WIDTH / 4]};
assign op_out_8b[4 * loop_8b + 1] = {{(OUT_DATA_WIDTH * 3 / 4){is_signed & op_in[((4 * loop_8b + 1) + 1) * OUT_DATA_WIDTH / 4 - 1]}}, op_in[((4 * loop_8b + 1) + 1) * OUT_DATA_WIDTH / 4 - 1 -: OUT_DATA_WIDTH / 4]};
assign op_out_8b[4 * loop_8b + 2] = {{(OUT_DATA_WIDTH * 3 / 4){is_signed & op_in[((4 * loop_8b + 2) + 1) * OUT_DATA_WIDTH / 4 - 1]}}, op_in[((4 * loop_8b + 2) + 1) * OUT_DATA_WIDTH / 4 - 1 -: OUT_DATA_WIDTH / 4]};
assign op_out_8b[4 * loop_8b + 3] = {{(OUT_DATA_WIDTH * 3 / 4){is_signed & op_in[((4 * loop_8b + 3) + 1) * OUT_DATA_WIDTH / 4 - 1]}}, op_in[((4 * loop_8b + 3) + 1) * OUT_DATA_WIDTH / 4 - 1 -: OUT_DATA_WIDTH / 4]};
    end
endgenerate

assign is_signed = dtype == ma_pkg::INT32 | dtype == ma_pkg::INT16 | dtype == ma_pkg::INT8;

genvar i;

generate
    for ( i = 0; i < NUMBER_OF_ALU; i = i + 1 ) begin : dtype_selection
always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n ) begin
        op_out[i] <= 'd0;
    end else if (en) begin
        if ( dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32 ) begin
            op_out[i] <= op_out_32b[i];
        end else if ( dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16 ) begin
            op_out[i] <= op_out_16b[NUMBER_OF_ALU * cnt[$clog2(IN_BYTES) / 2 - 1 : 0] + i];
        end else begin
            op_out[i] <= op_out_8b[NUMBER_OF_ALU * cnt + i];
        end
    end
end
endgenerate

endmodule