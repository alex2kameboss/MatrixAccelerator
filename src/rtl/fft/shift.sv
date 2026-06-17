module shift
  #(
    parameter DATA_WIDTH = 16,
    parameter DEPTH = 6
    )
   (
    input			  clk,
    input logic			  enable,
    input logic [DATA_WIDTH-1:0]  data_in,
 
    output logic [DATA_WIDTH-1:0] data_out
 
    );

   
   reg [DATA_WIDTH-1:0]		  holding_register [DEPTH-1:0];

   always @ (posedge clk) begin
      if(enable) begin
	 holding_register <= {holding_register[DEPTH-2:0], data_in};
      end
   end
   
   assign data_out = holding_register[DEPTH-1];   
  
   
endmodule
