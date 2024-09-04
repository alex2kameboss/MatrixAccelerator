module syncronizer #(
    parameter DATA_WIDTH = 3
) (
    input                               dest_clk,
    input                               dest_reset_n,
    input   [ DATA_WIDTH - 1 : 0 ]      async_data_i,
    output  [ DATA_WIDTH - 1 : 0 ]      sync_data_o
);

reg [1: 0][DATA_WIDTH - 1 : 0]   sync_reg;

assign sync_data_o = sync_reg[1];

always_ff @ (posedge dest_clk or negedge dest_reset_n)
    if ( ~dest_reset_n ) begin
        sync_reg[0] <= 'd0;
        sync_reg[1] <= 'd0;
    end
    else begin
        sync_reg[0] <= async_data_i;
        sync_reg[1] <= sync_reg[0];
    end

endmodule