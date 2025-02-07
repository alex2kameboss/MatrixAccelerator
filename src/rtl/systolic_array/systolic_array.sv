import ma_pkg::*;

module systolic_array #(
    parameter ARRAY_WIDTH   = 2,
    parameter ARRAY_HEIGHT  = 2,
    parameter DATA_WIDTH    = 8
) (
    // general signals
    input   logic                                   clk                                                         ,
    input   logic                                   reset_n                                                     ,
    // array control signals
    input   logic                                   en                                                          ,
    input   dtype_t                                 dtype                                                       ,
    input   logic                                   array_reset_n   [ARRAY_HEIGHT - 1 : 0][ARRAY_WIDTH - 1 : 0] ,
    // data
    input   logic           [DATA_WIDTH - 1 : 0]    a_array_input   [ARRAY_HEIGHT - 1 : 0]                      ,
    input   logic           [DATA_WIDTH - 1 : 0]    b_array_input   [ARRAY_WIDTH - 1 : 0]                       ,
    output  logic           [DATA_WIDTH - 1 : 0]    c_array_output  [ARRAY_HEIGHT - 1 : 0][ARRAY_WIDTH - 1 : 0]  
);

genvar i, j, i_en;

wire    [DATA_WIDTH - 1 : 0]    a_pass  [ARRAY_HEIGHT -1 : 0][ARRAY_WIDTH : 0];
wire    [DATA_WIDTH - 1 : 0]    b_pass  [ARRAY_HEIGHT : 0][ARRAY_WIDTH -1 : 0];

logic col_en [ARRAY_WIDTH - 1 : 0];

generate
    for ( i_en = 0; i_en < ARRAY_WIDTH / 4; i_en = i_en + 1 ) begin : b32_en
        assign col_en[i_en] = en & ( dtype == INT32 | dtype == UINT32 | dtype == INT16 | dtype == UINT16 | dtype == INT8 | dtype == UINT8 );
    end

    for ( i_en = ARRAY_WIDTH / 4; i_en < ARRAY_WIDTH / 2; i_en = i_en + 1 ) begin : b16_en
        assign col_en[i_en] = en & ( dtype == INT16 | dtype == UINT16 | dtype == INT8 | dtype == UINT8 );
    end

    for ( i_en = ARRAY_WIDTH / 2; i_en < ARRAY_WIDTH; i_en = i_en + 1 ) begin : b8_en
        assign col_en[i_en] = en & ( dtype == INT8 | dtype == UINT8 );
    end
endgenerate

generate
    for ( i = 0; i < ARRAY_HEIGHT; i = i + 1 ) begin : array_row
        for ( j = 0; j < ARRAY_WIDTH; j = j + 1 ) begin : array_col
            mac #(
                .DATA_WIDTH ( DATA_WIDTH )
            ) array_mac (
                .clk            ( clk               ),
                .reset_n        ( reset_n           ),
                .soft_reset_n   (array_reset_n[i][j]),
                .ld             ( col_en[j]         ),
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