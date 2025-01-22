module matrix_a_addr_gen_tb;

localparam SA_WIDTH            =   2   ;
localparam SA_HEIGHT           =   2   ;
localparam MEM_DATA_WIDTH      =   32  ;
localparam MEM_ADDR_WIDTH      =   16  ;
localparam REGISTER_NUMBERS    =   32  ;
localparam ADDR_WIDTH          =   32  ;

logic                                           clk     ;
logic                                           rst_n   ;
logic               [ADDR_WIDTH - 1 : 0]        m       ;
logic               [ADDR_WIDTH - 1 : 0]        n       ;
logic               [ADDR_WIDTH - 1 : 0]        p       ;
logic               [MEM_ADDR_WIDTH - 1 : 0]    addr_a  ;
logic                                           done    ;
ma_pkg::dtype_t                                 dtype   ;
logic                                           en      ;

matrix_a_addr_gen #(
    .SA_WIDTH           ( SA_WIDTH         )   ,
    .SA_HEIGHT          ( SA_HEIGHT        )   ,
    .MEM_DATA_WIDTH     ( MEM_DATA_WIDTH   )   ,
    .MEM_ADDR_WIDTH     ( MEM_ADDR_WIDTH   )   ,
    .REGISTER_NUMBERS   ( REGISTER_NUMBERS )   ,
    .ADDR_WIDTH         ( ADDR_WIDTH       )
) i_dut (
    .clk     ,
    .rst_n   ,
    .m       ,
    .n       ,
    .p       ,
    .addr_a  ,
    .done    ,
    .dtype   ,
    .en            
);

initial begin
    clk <= 1'b1;
    forever #5 clk <= ~clk;
end

task test(
    input int               x_size  ,
    input int               y_size  ,
    input ma_pkg::dtype_t   dt      
); 
begin
    m      = x_size;
    n      = x_size;
    dtype  = dt;
    en = 1'b1;

    @(posedge done);
    en = 1'b0;

    repeat(5) @(posedge clk);
end
endtask

initial begin
    rst_n = 1'b0;
    m      = 'd0;
    n      = 'd0;
    p      = 'd0;
    dtype  = ma_pkg::NDT;
    en     = 'd0;

    repeat(5) @(posedge clk);
    rst_n = 1'b1;
    repeat(5) @(posedge clk);

    test(
        .x_size( 'd8 ),
        .y_size( 'd8 ),
        .dt    ( ma_pkg::INT8 )
    );

    test(
        .x_size( 'd8 ),
        .y_size( 'd8 ),
        .dt    ( ma_pkg::INT16 )
    );

    test(
        .x_size( 'd8 ),
        .y_size( 'd8 ),
        .dt    ( ma_pkg::INT32 )
    );

    $stop;
end

endmodule