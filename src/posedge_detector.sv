module posedge_detector (
    input               clk     ,
    input               rst_n   ,
    input               signal  ,
    output              flag    
);
    
logic delay;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )           delay <= 1'b1;  else
                            delay <= signal;

assign flag = ~delay & signal;

endmodule