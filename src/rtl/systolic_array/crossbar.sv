module crossbar #(
    parameter   DATA_WIDTH      =   8,
    parameter   ARRAY_ELLEMENTS =   4
) (
    input   logic                           clk                                     ,
    input   logic                           reset_n                                 ,
    input   logic                           sync_reset_n                            ,
    input   logic                           shift                                   ,
    input   logic   [DATA_WIDTH - 1 : 0]    data_i      [ARRAY_ELLEMENTS - 1 : 0]   ,
    output  logic   [DATA_WIDTH - 1 : 0]    data_o      [ARRAY_ELLEMENTS - 1 : 0]      
);
    
genvar i;

generate
    for ( i = 0; i < ARRAY_ELLEMENTS; i = i + 1) begin : shift_block
        auto_shift_register #(
            .DATA_WIDTH ( DATA_WIDTH),
            .STEPS      ( i         )
        ) shifter (
            .clk            ( clk           ),
            .reset_n        ( reset_n       ),
            .sync_reset_n   ( sync_reset_n  ),
            .shift          ( shift         ),
            .data_i         ( data_i[i]     ),
            .data_o         ( data_o[i]     )
        );
    end
endgenerate

endmodule