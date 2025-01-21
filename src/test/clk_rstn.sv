module clk_rstn #(
    parameter PERIOD_NS = 10
) (
    output  logic       clk     ,
    output  logic       rst_n   
);
    
initial begin
    clk <= 'd1;
    forever #(PERIOD_NS/2) clk <= ~clk;
end

initial begin
    rst_n <= 'd0;
    repeat(2) @(negedge clk);
    rst_n <= 'd1;
end

endmodule