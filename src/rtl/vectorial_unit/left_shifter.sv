module left_shifter #(
    parameter   BIT_WIDTH       =   1   ,
    parameter   DATA_WIDTH      =   32  ,
    parameter   SHIFTER_WIDTH   =   5   ,
    localparam  IN_DATA_WIDTH   =   BIT_WIDTH * DATA_WIDTH
) (
    input   [IN_DATA_WIDTH - 1 : 0]     data_i      ,
    input   [SHIFTER_WIDTH - 1 : 0]     shifter_i   ,
    output  [IN_DATA_WIDTH - 1 : 0]     data_o       
);
    
logic   [IN_DATA_WIDTH - 1 : 0] shift   [SHIFTER_WIDTH : 0];

genvar level_idx;

assign shift[SHIFTER_WIDTH] = data_i;

generate;
    for ( level_idx = SHIFTER_WIDTH - 1; level_idx >= 0; level_idx = level_idx - 1 ) begin : shifter_by_level
assign shift[level_idx] = shifter_i[level_idx] ? {shift[level_idx + 1][IN_DATA_WIDTH - 2 ** level_idx * BIT_WIDTH - 1 : 0], {(2 ** level_idx * BIT_WIDTH){1'b0}}} : shift[level_idx + 1];
    end
endgenerate

assign data_o = shift[0];

endmodule