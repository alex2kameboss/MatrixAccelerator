module gray_counter #(
    parameter WIDTH = 3
) (
    input                       clk,        //  counter clk
    input                       reset_n,    //  counter async reset
    input                       inc_i,      //  increment value
    input                       stop_i,     
    output [ WIDTH - 1 : 0 ]    addr_o,     // simple counter output
    output [ WIDTH - 1 : 0 ]    ptr_o,      // gray counter output
    output [ WIDTH - 1 : 0 ]    next_gray_o // next gray counter output
);
    
logic inc;

assign inc = inc_i & stop_i;

logic [WIDTH - 1 : 0] binary_reg, gray_reg;
logic [WIDTH - 1 : 0] gray, binary_next;

assign next_gray_o = gray;
assign addr_o = binary_reg;
assign ptr_o = gray_reg;

assign binary_next = binary_reg + inc;

always_ff @( posedge clk or negedge reset_n ) begin
    if ( ~reset_n )     binary_reg <= 'd0;      else
                        binary_reg <= binary_next;
end

always_ff @( posedge clk or negedge reset_n ) begin
    if ( ~reset_n )     gray_reg <= 'd0;        else
                        gray_reg <= gray;
end

assign gray[WIDTH - 1] = binary_next[WIDTH - 1];
assign gray[WIDTH - 2 : 0] = binary_next[WIDTH - 1 : 1] ^ binary_next[WIDTH - 2 : 0];

endmodule