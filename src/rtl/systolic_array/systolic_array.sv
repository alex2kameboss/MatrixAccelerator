module systolic_array #(
    parameter ARRAY_WIDTH   = 2,
    parameter ARRAY_HEIGHT  = 2,
    parameter DATA_WIDTH    = 8
) (
    // general signals
    input   logic                           clk                                                         ,
    input   logic                           reset_n                                                     ,
    // array control signals
    input   logic                           en                                                          ,
    input   logic                           array_reset_n   [ARRAY_HEIGHT - 1 : 0][ARRAY_WIDTH - 1 : 0] ,
    // data
    input   logic   [DATA_WIDTH - 1 : 0]    a_array_input   [ARRAY_HEIGHT - 1 : 0]                      ,
    input   logic   [DATA_WIDTH - 1 : 0]    b_array_input   [ARRAY_WIDTH - 1 : 0]                       ,
    output  logic   [DATA_WIDTH - 1 : 0]    c_array_output  [ARRAY_HEIGHT - 1 : 0][ARRAY_WIDTH - 1 : 0]  
);

genvar i, j;

wire    [DATA_WIDTH - 1 : 0]    a_pass  [ARRAY_HEIGHT -1 : 0][ARRAY_WIDTH : 0];
wire    [DATA_WIDTH - 1 : 0]    b_pass  [ARRAY_HEIGHT : 0][ARRAY_WIDTH -1 : 0];

generate
    for ( i = 0; i < ARRAY_HEIGHT; i = i + 1 ) begin : array_row
        for ( j = 0; j < ARRAY_WIDTH; j = j + 1 ) begin : array_col
            mac #(
                .DATA_WIDTH ( DATA_WIDTH )
            ) array_mac (
                .clk            ( clk               ),
                .reset_n        ( reset_n           ),
                .soft_reset_n   (array_reset_n[i][j]),
                .ld             ( en                ),
                .a_i            ( a_pass[i][j]      ),
                .b_i            ( b_pass[i][j]      ),
                .a_o            ( a_pass[i][j + 1]  ),
                .b_o            ( b_pass[i + 1][j]  ),
                .c_o            ( c_array_output[i][j])
            );
        end
    end
endgenerate

generate
    for ( i = 0; i < ARRAY_HEIGHT; i = i + 1 ) begin : assign_a_input
        assign a_pass[i]['d0] = a_array_input[i];
    end
endgenerate

generate
    for ( j = 0; j < ARRAY_WIDTH; j = j + 1 ) begin : assign_b_input
        assign b_pass['d0][j] = b_array_input[j];
    end
endgenerate

endmodule