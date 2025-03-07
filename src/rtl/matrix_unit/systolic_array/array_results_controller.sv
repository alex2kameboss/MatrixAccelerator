// TODO: add start signal to reset result_reset_n

module array_results_controller #(
    parameter   ARRAY_HEIGHT        =   4   ,
    parameter   ARRAY_WIDTH         =   32  ,
    parameter   DATA_WIDTH          =   32  
) (
    input   logic                                                   clk                                                         ,
    input   logic                                                   reset_n                                                     ,
    input   logic                                                   en                                                          ,
    input   ma_pkg::dtype_t                                         dtype                                                       ,
    input   logic                                                   start                                                       ,
    input   ma_pkg::register_file_line_t                            rd                                                          ,
    input   ma_pkg::register_file_line_t                            rs1                                                         ,
    input   ma_pkg::register_file_line_t                            rs2                                                         ,
    input   logic                           [DATA_WIDTH - 1 : 0]    array_results   [ARRAY_HEIGHT - 1 : 0][ARRAY_WIDTH - 1 : 0] ,
    output  logic                                                   array_reset_n   [ARRAY_HEIGHT - 1 : 0][ARRAY_WIDTH - 1 : 0] ,
    output  logic                           [DATA_WIDTH - 1 : 0]    data_o          [ARRAY_HEIGHT - 1 : 0]                      ,
    output  logic                                                   valid_o                                                     
);
    
localparam DIAGONAL_COUNTS  =   ARRAY_HEIGHT + ARRAY_WIDTH - 1;

logic   [DATA_WIDTH - 1 : 0]    m, n, p;

always_ff @( posedge clk or negedge reset_n )
    if ( ~reset_n ) begin
        m <= 'd0;
        n <= 'd0;
        p <= 'd0;
    end else if ( start ) begin
        m <= rd.height;
        n <= rs1.width;
        p <= rd.width;
    end

logic                                       loop_done;

genvar i_en;
logic col_en [ARRAY_WIDTH - 1 : 0];

generate
    for ( i_en = 0; i_en < ARRAY_WIDTH / 4; i_en = i_en + 1 ) begin : b32_en
        assign col_en[i_en] = en & ( dtype == ma_pkg::INT32 | dtype == ma_pkg::UINT32 | dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16 | dtype == ma_pkg::INT8 | dtype == ma_pkg::UINT8 );
    end

    for ( i_en = ARRAY_WIDTH / 4; i_en < ARRAY_WIDTH / 2; i_en = i_en + 1 ) begin : b16_en
        assign col_en[i_en] = en & ( dtype == ma_pkg::INT16 | dtype == ma_pkg::UINT16 | dtype == ma_pkg::INT8 | dtype == ma_pkg::UINT8 );
    end

    for ( i_en = ARRAY_WIDTH / 2; i_en < ARRAY_WIDTH; i_en = i_en + 1 ) begin : b8_en
        assign col_en[i_en] = en & ( dtype == ma_pkg::INT8 | dtype == ma_pkg::UINT8 );
    end
endgenerate

always_ff @( posedge clk or negedge reset_n )
    if ( ~reset_n ) begin
        for ( int ii = 0; ii < ARRAY_HEIGHT; ii = ii + 1 )
            for ( int jj = 0; jj < ARRAY_WIDTH; jj = jj + 1 )
                array_reset_n[ii][jj] <= 1'b1;
    end else begin
        for ( int ii = 0; ii < ARRAY_HEIGHT; ii = ii + 1 )
            for ( int jj = 0; jj < ARRAY_WIDTH; jj = jj + 1 )
                if ( col_en[jj] ) begin
                    if ( ii == 0 & jj == 0 )
                        array_reset_n[ii][jj] <= ~loop_done;
                    else if ( ii >= jj )
                        array_reset_n[ii][jj] <= array_reset_n[ii - 1][jj];
                    else
                        array_reset_n[ii][jj] <= array_reset_n[ii][jj - 1];
                end
    end

logic   [DATA_WIDTH - 1 : 0] loop_counter, loop_counter_1;

assign loop_counter_1   =   loop_counter + 1'b1;
assign loop_done        =   loop_counter_1 == n; // n != 0

always_ff @( posedge clk or negedge reset_n )
    if ( ~reset_n )                         loop_counter <= 'd0;            else
    if ( start )                            loop_counter <= 'd0;            else
    if ( loop_done )                        loop_counter <= 'd0;            else
    if ( en )                               loop_counter <= loop_counter_1;

logic   [DATA_WIDTH - 1 : 0]    line_result   [ ARRAY_HEIGHT - 1 : 0 ];

genvar k;
generate
    for ( k = 0; k < ARRAY_HEIGHT; k = k + 1 ) begin : output_sequencer
line_mux #(
    .ARRAY_WIDTH    ( ARRAY_WIDTH ),
    .DATA_WIDTH     ( DATA_WIDTH  )
) i_line_result (
    .clk            ( clk               ),
    .rst_n          ( reset_n           ),
    .en             ( array_reset_n[k]  ),
    .array_results  ( array_results[k]  ),
    .result         ( line_result[k]    )
);

auto_shift_register #(
    .DATA_WIDTH ( DATA_WIDTH        ),
    .STEPS      ( ARRAY_HEIGHT - k  )
) i_result_shifter (
    .clk            ( clk                   ),
    .reset_n        ( reset_n               ),
    .sync_reset_n   ( 1'b1                  ),
    .shift          ( en                    ),
    .data_i         ( line_result[k]        ),
    .data_o         ( data_o[k]             )
);
    end
endgenerate

genvar reduction_i;
wand en_delay_input;

generate
    for ( reduction_i = 0; reduction_i < ARRAY_WIDTH; reduction_i = reduction_i + 1 ) begin : en_reduction
assign en_delay_input = array_reset_n[0][reduction_i];
    end
endgenerate

auto_shift_register #(
    .DATA_WIDTH ( 1                 ),
    .STEPS      ( ARRAY_HEIGHT      )
) i_valid_shifter (
    .clk            ( clk                   ),
    .reset_n        ( reset_n               ),
    .sync_reset_n   ( 1'b1                  ),
    .shift          ( en                    ),
    .data_i         ( ~en_delay_input       ),
    .data_o         ( valid_o               )
);

endmodule