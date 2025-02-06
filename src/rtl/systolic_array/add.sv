module add #(
    parameter DATA_WIDTH = 16
) (
    input   [DATA_WIDTH - 1 : 0]    a   ,
    input   [DATA_WIDTH - 1 : 0]    b   ,
    output  [DATA_WIDTH - 1 : 0]    c   
);

assign c = a + b;

endmodule