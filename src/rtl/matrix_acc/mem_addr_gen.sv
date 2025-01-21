module mem_addr_gen #(
    parameter ADDR_WIDTH = 13
) (
// generic signals
    input   logic                           clk     ,
    input   logic                           rst_n   ,
// control signals
    input   logic                           reset   ,
    input   logic                           incr    ,
// output signal
    output  logic   [ADDR_WIDTH - 1 : 0]    addr    
);
    
always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )                           addr <= 'd0;            else
    if ( reset )                            addr <= 'd0;            else
    if ( incr )                             addr <= addr + 1'b1;

endmodule