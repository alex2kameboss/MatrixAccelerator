`timescale 1ns/1ns

module tb_splitter_new();

localparam IN_DATA_WIDTH  = 128;
localparam OUT_DATA_WIDTH = 32;

logic clk, rst_n;

logic en, reset;
ma_pkg::dtype_t dtype;

initial begin
    clk = 1'b1;
    forever
        #5 clk = ~clk;
end

initial begin
    rst_n = 1'b0;
    en = 1'b0;
    reset = 1'b0;
    
    repeat(2) @(negedge clk);
    rst_n = 1'b1;

    dtype = ma_pkg::INT8;
    @(posedge clk);
    en = 1'b1;
    repeat(2) @(posedge clk);
    reset = 1'b1;
    @(posedge clk);
    reset = 1'b0;
    repeat(20) @(posedge clk);
    en = 1'b0;

    dtype = ma_pkg::INT16;
    @(posedge clk);
    en = 1'b1;
    repeat(2) @(posedge clk);
    reset = 1'b1;
    @(posedge clk);
    reset = 1'b0;
    repeat(20) @(posedge clk);
    en = 1'b0;

    dtype = ma_pkg::INT32;
    @(posedge clk);
    en = 1'b1;
    repeat(2) @(posedge clk);
    reset = 1'b1;
    @(posedge clk);
    reset = 1'b0;
    repeat(20) @(posedge clk);
    en = 1'b0;

    repeat(2) @(posedge clk);
    $finish();
end

vectorial_splitter #(
    .IN_DATA_WIDTH  ( IN_DATA_WIDTH  ),
    .OUT_DATA_WIDTH ( OUT_DATA_WIDTH )
) i_dut (
    .clk    ( clk   ),
    .rst_n  ( rst_n ),
    .reset  ( reset ),
    .en     ( en    ),
    .dtype  ( dtype ),
    .op_in  (       ),
    .op_out (       ),
    .next   (       )
);

always_comb
    assert( i_dut.next_old == i_dut.next );

endmodule