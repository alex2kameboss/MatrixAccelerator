module shift_complex
  #(
    parameter DATA_WIDTH = 16,
    parameter DEPTH = 6
    )
   (
    input			  clk,
    input logic			  enable,
    input logic [DATA_WIDTH-1:0]  data_in_r,
    input logic [DATA_WIDTH-1:0]  data_in_i,
    output logic [DATA_WIDTH-1:0] data_out_r,
    output logic [DATA_WIDTH-1:0] data_out_i
    );

   
   reg [DATA_WIDTH-1:0]		  holding_register_r [0:DEPTH-1];
   reg [DATA_WIDTH-1:0]		  holding_register_i [0:DEPTH-1];

   genvar			  i;

   always @ (posedge clk) begin
      if(enable) begin
	 holding_register_r[0] <= data_in_r;
	 holding_register_i[0] <= data_in_i;
	 
      end
   end
   generate
      for (i=0; i<DEPTH-1; i=i+1) begin
	always @ (posedge clk) begin
	   if(enable) begin
	      holding_register_r[i+1] <= holding_register_r[i];
	      holding_register_i[i+1] <= holding_register_i[i];
	   end
	end
      end
   endgenerate

   always @ (posedge clk) begin
      if(enable) begin
	 data_out_r <= holding_register_r[DEPTH-1];   
	 data_out_i <= holding_register_i[DEPTH-1];
      end
   end
   
endmodule
