module vectorial_concat #(
    parameter   OUT_DATA_WIDTH  =   128  ,
    parameter   IN_DATA_WIDTH   =   32   ,
    localparam  NUMBER_OF_ALU   = OUT_DATA_WIDTH / IN_DATA_WIDTH
) (
    input   logic                               clk                             ,
    input   logic                               rst_n                           ,
    input   logic                               reset                           ,
    input   logic                               en                              ,
    input   ma_pkg::dtype_t                     dtype                           ,
    input   logic   [IN_DATA_WIDTH - 1 : 0]     rez_in  [NUMBER_OF_ALU - 1 : 0] ,
    output  logic   [OUT_DATA_WIDTH - 1 : 0]    rez_out                         ,
    output  logic                               valid                           
);

localparam IN_BYTES = IN_DATA_WIDTH / 8;
logic   [$clog2(IN_BYTES) - 1 : 0]      cnt;
logic                                   next;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       valid <= 'd0;       else
    if ( en )                           valid <= next;      else
                                        valid <= 'd0;       

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

logic [7 : 0] rez_in_byte [NUMBER_OF_ALU - 1 : 0][IN_BYTES - 1 : 0];

genvar i_split, j_split;
generate
    for ( i_split = 0 ; i_split < NUMBER_OF_ALU; i_split = i_split + 1 ) begin : splitter_outer_loop
        for ( j_split = 0; j_split < IN_BYTES; j_split = j_split + 1 ) begin : splitter_inner_loop
assign rez_in_byte[i_split][j_split] = rez_in[i_split][(j_split + 1) * 8 - 1 -: 8];
        end
    end
endgenerate

genvar i_reg, j_reg;
generate
    for ( i_reg = NUMBER_OF_ALU - 1; i_reg >= 0 ; i_reg  = i_reg - 1 ) begin : dtype_selection_outer
        for ( j_reg = IN_BYTES - 1; j_reg >= 0; j_reg = j_reg - 1 ) begin : dtype_selection_inner
always_ff @( posedge clk, negedge rst_n )
    if ( en ) begin
        if (dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32)
            rez_out[(i_reg * IN_BYTES + j_reg + 1) * 8 - 1 -: 8] <= rez_in_byte[i_reg][j_reg];
        else if ((dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16) & ((IN_BYTES - 1 - j_reg) / 2) == cnt)
            rez_out[(i_reg * IN_BYTES + j_reg + 1) * 8 - 1 -: 8] <= rez_in_byte[i_reg][j_reg % 2];
        else if ((dtype == ma_pkg::INT8 | dtype == ma_pkg::UINT8) & (IN_BYTES - 1 - j_reg == cnt))
            rez_out[(i_reg * IN_BYTES + j_reg + 1) * 8 - 1 -: 8] <= rez_in_byte[i_reg][0];
    end
        end
    end

endgenerate

endmodule