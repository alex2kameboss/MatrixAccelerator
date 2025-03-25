module ma_mult #(
    parameter DATA_WIDTH = 8
) (
    input   [DATA_WIDTH - 1 : 0]    a   ,
    input   [DATA_WIDTH - 1 : 0]    b   ,
    output  [DATA_WIDTH - 1 : 0]    c   
);

assign c = a * b;

endmodule