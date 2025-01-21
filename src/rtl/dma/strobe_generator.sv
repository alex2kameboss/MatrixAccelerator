module strobe_generator #(
    parameter STROBE_WIDTH  =   16
) (
    input                                   en      ,   // if not enable, the strobe is all 1
    input   [$clog2(STROBE_WIDTH) - 1 : 0]  value   ,
    output  [STROBE_WIDTH - 1 : 0]          strobe  
);
    
genvar i;

generate
    for ( i = 0; i < STROBE_WIDTH; i = i + 1) begin
        assign strobe[i] = ~en | value > i;
    end
endgenerate

endmodule