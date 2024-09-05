module valid_ready_checker #(
    parameter DATA_WIDTH = 128
) (
    input                           clk         ,
    input                           valid       ,
    input                           ready       ,
    input   [DATA_WIDTH - 1 : 0]    data        
);
    
assert property (@(posedge clk) (valid && !ready |=> $stable(data)));

endmodule