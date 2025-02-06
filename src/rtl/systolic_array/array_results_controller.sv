module array_results_controller #(
    parameter   ARRAY_HEIGHT        =   4   ,
    parameter   ARRAY_WIDTH         =   32  ,
    parameter   DATA_WIDTH          =   32  
) (
    input   logic                                                   clk                                                         ,
    input   logic                                                   reset_n                                                     ,
    input   logic                                                   en                                                          ,
    input   logic                                                   start                                                       ,
    input   ma_pkg::register_file_line_t                            rd                                                          ,
    input   ma_pkg::register_file_line_t                            rs1                                                         ,
    input   ma_pkg::register_file_line_t                            rs2                                                         ,
    input   logic                           [DATA_WIDTH - 1 : 0]    array_results   [ARRAY_HEIGHT - 1 : 0][ARRAY_WIDTH - 1 : 0] ,
    output  logic                                                   array_reset_n   [ARRAY_HEIGHT - 1 : 0][ARRAY_WIDTH - 1 : 0] ,
    output  logic                           [DATA_WIDTH - 1 : 0]    data_o          [ARRAY_HEIGHT - 1 : 0]                      ,
    output  logic                                                   valid_o                                                     ,
    output  logic                                                   done                                                         
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
    end else if ( done ) begin
        m <= 'd0;
        n <= 'd0;
        p <= 'd0;
    end

logic                                       loop_done;

always_ff @( posedge clk or negedge reset_n )
    if ( ~reset_n ) begin
        for ( int ii = 0; ii < ARRAY_HEIGHT; ii = ii + 1 )
            for ( int jj = 0; jj < ARRAY_WIDTH; jj = jj + 1 )
                array_reset_n[ii][jj] <= 1'b1;
    end else begin
        for ( int ii = 0; ii < ARRAY_HEIGHT; ii = ii + 1 )
            for ( int jj = 0; jj < ARRAY_WIDTH; jj = jj + 1 )
                if ( ii == 0 & jj == 0 )
                    array_reset_n[ii][jj] <= ~loop_done;
                else if ( ii >= jj )
                    array_reset_n[ii][jj] <= array_reset_n[ii - 1][jj];
                else
                    array_reset_n[ii][jj] <= array_reset_n[ii][jj - 1];
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
    .en             (~&{<<{array_reset_n[k]}}),
    .array_results  ( array_results[k]  ),
    .result         ( line_result[k]    )
);

auto_shift_register #(
    .DATA_WIDTH ( DATA_WIDTH        ),
    .STEPS      ( ARRAY_WIDTH - k   )
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

auto_shift_register #(
    .DATA_WIDTH ( 1                 ),
    .STEPS      ( ARRAY_WIDTH       )
) i_valid_shifter (
    .clk            ( clk                   ),
    .reset_n        ( reset_n               ),
    .sync_reset_n   ( 1'b1                  ),
    .shift          ( en                    ),
    .data_i         ( ~&{<<{array_reset_n[0]}}),
    .data_o         ( valid_o               )
);

endmodule