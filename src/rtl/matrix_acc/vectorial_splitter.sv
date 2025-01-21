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

logic   [$clog2(NUMBER_OF_ALU) - 1 : 0]   cnt;

assign next = ((dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32) |
                cnt == 'd1 & (dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16) |
                cnt == 'd3 & (dtype == ma_pkg::INT8 | dtype == ma_pkg::UINT8)) & en;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       cnt <= 'd0;         else
    if ( reset )                        cnt <= 'd0;         else
    if ( en )   begin
        if ( next ) 
            cnt <= 'd0; 
        else
            cnt <= cnt + 1'b1;
    end

logic is_signed;

assign is_signed = dtype == ma_pkg::UINT32 | dtype == ma_pkg::UINT16 | dtype == ma_pkg::UINT8;

genvar i;

generate
    for ( i = 0; i < NUMBER_OF_ALU; i = i + 1 ) begin : dtype_selection
always_ff @(posedge clk, negedge rst_n)
    if (en) begin
        if ( dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32 ) begin
            op1_out[i] <= op1_in[(i + 1) * OUT_DATA_WIDTH - 1 -: OUT_DATA_WIDTH];
            op2_out[i] <= op2_in[(i + 1) * OUT_DATA_WIDTH - 1 -: OUT_DATA_WIDTH];
        end else if ( dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16 ) begin
            op1_out[i] <= {{(OUT_DATA_WIDTH - OUT_DATA_WIDTH / 2){is_signed & op1_in[(i + 1) * OUT_DATA_WIDTH - cnt * OUT_DATA_WIDTH / 2 - 1]}}, op1_in[(i + 1) * OUT_DATA_WIDTH - cnt * OUT_DATA_WIDTH / 2 - 1 -: OUT_DATA_WIDTH / 2]};
            op2_out[i] <= {{(OUT_DATA_WIDTH - OUT_DATA_WIDTH / 2){is_signed & op2_in[(i + 1) * OUT_DATA_WIDTH - cnt * OUT_DATA_WIDTH / 2 - 1]}}, op2_in[(i + 1) * OUT_DATA_WIDTH - cnt * OUT_DATA_WIDTH / 2 - 1 -: OUT_DATA_WIDTH / 2]};
        end else begin
            op1_out[i] <= {{(OUT_DATA_WIDTH - OUT_DATA_WIDTH / 4){is_signed & op1_in[(i + 1) * OUT_DATA_WIDTH - cnt * OUT_DATA_WIDTH / 4 - 1]}}, op1_in[(i + 1) * OUT_DATA_WIDTH - cnt * OUT_DATA_WIDTH / 4 - 1 -: OUT_DATA_WIDTH / 4]};
            op2_out[i] <= {{(OUT_DATA_WIDTH - OUT_DATA_WIDTH / 4){is_signed & op2_in[(i + 1) * OUT_DATA_WIDTH - cnt * OUT_DATA_WIDTH / 4 - 1]}}, op2_in[(i + 1) * OUT_DATA_WIDTH - cnt * OUT_DATA_WIDTH / 4 - 1 -: OUT_DATA_WIDTH / 4]};
        end
    end
end
endgenerate

endmodule