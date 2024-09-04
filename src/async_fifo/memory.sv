module memory #(
    parameter DATA_SIZE = 8,
    parameter DEPTH = 8
) (
    // write interface
    input                               w_clk   ,   // write clock
    input   [ $clog2(DEPTH) - 1 : 0 ]   w_addr_i,   // write address
    input   [ DATA_SIZE - 1 : 0 ]       w_data_i,   // write data
    input                               w_en_i  ,   // write enable
    // read interface
    input   [ $clog2(DEPTH) - 1 : 0 ]   r_addr_i,   // readd address
    output  [ DATA_SIZE - 1: 0 ]        r_data_o    // write data
);
    
reg [ DATA_SIZE - 1 : 0 ] mem [ 0 : DEPTH - 1 ];

assign r_data_o = mem[r_addr_i];

always_ff @ (posedge w_clk)
    if ( w_en_i )   mem[w_addr_i] <= w_data_i;

endmodule