module vectorial_concat #(
    parameter   OUT_DATA_WIDTH  =   128  ,
    parameter   IN_DATA_WIDTH   =   32  
) (
    input   logic                               clk                                                 ,
    input   logic                               rst_n                                               ,
    input   logic                               reset                                               ,
    input   logic                               en                                                  ,
    input   ma_pkg::dtype                       dtype                                               ,
    input   logic   [IN_DATA_WIDTH - 1 : 0]     rez_in  [OUT_DATA_WIDTH / IN_DATA_WIDTH - 1 : 0]    ,
    output  logic   [OUT_DATA_WIDTH - 1 : 0]    rez_out                                             ,
    output  logic                               valid                                               
);

localparam NUMBER_OF_ALU = OUT_DATA_WIDTH / IN_DATA_WIDTH;

logic   [$clog2(NUMBER_OF_ALU) - 1 : 0] cnt;
logic                                   next;

always_ff @( posedge clk, negedge rst_n )
    valid <= next;

assign next = (dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32) |
                cnt == 'd1 & (dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16) |
                cnt == 'd3 & (dtype == ma_pkg::INT8 | dtype == ma_pkg::UINT8);

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       cnt <= 'd0;         else
    if ( reset )                        cnt <= 'd0;         else
    if ( en )   begin
        if ( next ) 
            cnt <= 'd0; 
        else
            cnt <= cnt + 1'b1;
    end

localparam IN_BYTES = IN_DATA_WIDTH / 8;
logic [7 : 0] rez_in_byte [NUMBER_OF_ALU - 1 : 0][0 : IN_BYTES - 1];

genvar j;
generate
    for ( j = 0 ; j < OUT_DATA_WIDTH / 8; j = j + 1 ) begin : splitter
assign rez_in_byte[j / NUMBER_OF_ALU][j % IN_BYTES] = rez_in[j / NUMBER_OF_ALU][(j % IN_BYTES + 1) * 8 - 1 -: 8];
    end
endgenerate

genvar i;

//generate
//    for ( i = 0; i < NUMBER_OF_ALU; i = i + 1 ) begin : dtype_selection
//always_ff @(posedge clk, negedge rst_n)
//    if (en) begin
//        if ( dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32 ) begin
//            rez_out[(i + 1) * IN_DATA_WIDTH - 1 -: IN_DATA_WIDTH] <= rez_in[i];
//        end else if ( dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16 ) begin
//            rez_out[(i + 1) * IN_DATA_WIDTH - cnt * IN_DATA_WIDTH / 2 - 1 -: IN_DATA_WIDTH / 2] <= rez_in[i][IN_DATA_WIDTH / 2 - 1 : 0];
//        end else begin
//            rez_out[(i + 1) * IN_DATA_WIDTH - cnt * IN_DATA_WIDTH / 4 - 1 -: IN_DATA_WIDTH / 4] <= rez_in[i][IN_DATA_WIDTH / 4 - 1 : 0];
//        end
//    end
//end
//endgenerate

generate
    for ( i = OUT_DATA_WIDTH / 8 - 1; i >= 0 ; i  = i - 1 ) begin : dtype_selection
always_ff @( posedge clk, negedge rst_n )
    if ( en ) begin
        if (dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32)
            rez_out[(i + 1) * 8 - 1 -: 8] <= rez_in_byte[i / NUMBER_OF_ALU][ i % IN_BYTES ];
        else if ((dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16) & i / 2 % 2 == cnt)
            rez_out[(i + 1) * 8 - 1 -: 8] <= rez_in_byte[i / NUMBER_OF_ALU][i % 2];
        else if ((dtype == ma_pkg::INT8 | dtype == ma_pkg::UINT8) & (NUMBER_OF_ALU - 1 - i % NUMBER_OF_ALU == cnt))
            rez_out[(i + 1) * 8 - 1 -: 8] <= rez_in_byte[i / NUMBER_OF_ALU][0];
    end
end

endgenerate

endmodule