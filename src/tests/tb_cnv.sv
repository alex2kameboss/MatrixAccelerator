`timescale 1ns/1ns

module tb_cnv();

localparam PRF_LOG_N = 10;
localparam PRF_LOG_M = 10;

logic                                               clk  ;
logic                                               rst_n;
logic                                               en   ;
logic                                               start;
logic                                               incr ;
ma_pkg::register_file_line_t                        r    ;
ma_pkg::register_file_line_t                        r_k  ;
logic                        [PRF_LOG_N - 1 : 0]    i_out;
logic                        [PRF_LOG_M - 1 : 0]    j_out;
logic                                               done ;

matrix_addr_gen #(
    .PRF_LOG_P  ( 1         ),
    .PRF_LOG_Q  ( 1         ),
    .PRF_LOG_N  ( PRF_LOG_N ),
    .PRF_LOG_M  ( PRF_LOG_M ),
    .SRAM_WIDTH ( 32        )
) i_dut (
    .clk     ,
    .rst_n   ,
    .en      ,
    .start   ,
    .incr    ,
    .r       ,
    .r_k     ,
    .i_out   ,
    .j_out   ,
    .done    
);

initial begin
    clk = 1'b1;
    forever #5 clk = ~clk;
end

initial begin
    rst_n = 1'b0;
    repeat(3) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
end

initial begin
    incr = 1'b1;
    en = 1'b0;
    start = 1'b0;

    // 32b
    r.width = 8;
    r.height = 4;
    r.dtype = ma_pkg::INT32;
    r.prf_x = 0;
    r.prf_y = 0;

    r_k.width = 2;
    r_k.height = 2;
    r_k.dtype = ma_pkg::INT32;

    repeat(5) @(posedge clk);
    en = 1'b1;
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;

    @(posedge clk)
    wait(done);
    @(posedge clk);
    en = 1'b0;

    r_k.width = 3;
    r_k.height = 3;
    r_k.dtype = ma_pkg::INT32;

    repeat(5) @(posedge clk);
    en = 1'b1;
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;

    @(posedge clk);
    wait(done);
    @(posedge clk);
    en = 1'b0;

    // 16b
    r.width = 8;
    r.height = 4;
    r.dtype = ma_pkg::INT16;
    r.prf_x = 0;
    r.prf_y = 0;

    r_k.width = 2;
    r_k.height = 2;
    r_k.dtype = ma_pkg::INT32;

    repeat(5) @(posedge clk);
    en = 1'b1;
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;

    @(posedge clk)
    wait(done);
    @(posedge clk);
    en = 1'b0;

    r_k.width = 3;
    r_k.height = 3;
    r_k.dtype = ma_pkg::INT32;

    repeat(5) @(posedge clk);
    en = 1'b1;
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;

    @(posedge clk);
    wait(done);
    @(posedge clk);
    en = 1'b0;

    // 8b
    r.width = 8;
    r.height = 4;
    r.dtype = ma_pkg::INT8;
    r.prf_x = 0;
    r.prf_y = 0;

    r_k.width = 2;
    r_k.height = 2;
    r_k.dtype = ma_pkg::INT16;

    repeat(5) @(posedge clk);
    en = 1'b1;
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;

    @(posedge clk)
    wait(done);
    @(posedge clk);
    en = 1'b0;

    r_k.width = 3;
    r_k.height = 3;
    r.dtype = ma_pkg::INT32;

    repeat(5) @(posedge clk);
    en = 1'b1;
    start = 1'b1;
    @(posedge clk);
    start = 1'b0;

    @(posedge clk);
    wait(done);
    @(posedge clk);
    en = 1'b0;

    @(posedge clk);
    $stop();

end

endmodule