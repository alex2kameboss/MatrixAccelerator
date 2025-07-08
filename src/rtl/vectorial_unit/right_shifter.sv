module right_shifter #(
    parameter   BIT_WIDTH       =   1   ,
    parameter   DATA_WIDTH      =   32  ,
    parameter   SHIFTER_WIDTH   =   32  ,
    localparam  IN_DATA_WIDTH   =   BIT_WIDTH * DATA_WIDTH
) (
    input                               is_signed   ,
    input   [IN_DATA_WIDTH - 1 : 0]     data_i      ,
    input   [SHIFTER_WIDTH - 1 : 0]     shifter_i   ,
    output  [IN_DATA_WIDTH - 1 : 0]     data_o       
);
    
logic   [IN_DATA_WIDTH - 1 : 0] shift   [SHIFTER_WIDTH : 0];
logic   [BIT_WIDTH - 1 : 0]     sign;

assign sign = {BIT_WIDTH{is_signed}} & data_i[IN_DATA_WIDTH - 1 -: BIT_WIDTH];

assign shift[SHIFTER_WIDTH] = data_i;

genvar level_idx;

generate;
    for ( level_idx = SHIFTER_WIDTH - 1; level_idx >= 0; level_idx = level_idx - 1 ) begin : shifter_by_level
assign shift[level_idx] = shifter_i[level_idx] ? {{2 ** level_idx{sign}}, shift[level_idx + 1][IN_DATA_WIDTH - 1 : (2 ** level_idx * BIT_WIDTH)]} : shift[level_idx + 1];
    end
endgenerate

assign data_o = shift[0];

endmodule