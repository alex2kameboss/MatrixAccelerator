module clk_rstn #(
    parameter PERIOD_NS = 8
) (
    output  logic       clk     ,
    output  logic       clk_2x  ,
    output  logic       rst_n   
);
    
initial begin
    clk <= 'd1;
    forever #(PERIOD_NS/2) clk <= ~clk;
end

initial begin
    clk_2x <= 'd1;
    forever #(PERIOD_NS/4) clk_2x <= ~clk_2x;
end

initial begin
    rst_n <= 'd0;
    repeat(2) @(negedge clk);
    rst_n <= 'd1;
end

endmodule