module delay_commutator
  #(
    parameter L = 8,
    parameter DATA_WIDTH=16*2
    )
   (
    input logic			  clk,
    input logic			  enable,
    input logic			  sel,
    input logic [DATA_WIDTH-1:0]  a_in,
    input logic [DATA_WIDTH-1:0]  b_in,
    output logic [DATA_WIDTH-1:0] a_out,
    output logic [DATA_WIDTH-1:0] b_out
    );


   logic [DATA_WIDTH-1:0]	  dla[L];
   logic [DATA_WIDTH-1:0]	  dlb[L];
   
   
   genvar			  i;
   
   always_ff @(posedge clk) begin
      if (enable) begin
	 dlb[0] <= b_in;
      end
   end
   

   always_comb begin
      a_out = dla[L-1];
   end
   
   generate
      for (i = 0; i < L-1; i = i + 1) begin
	 always_ff @(posedge clk) begin
	    if(enable) begin
	       dlb[i+1] <= dlb[i];
	       dla[i+1] <= dla[i];
	    end
	 end
      end
   endgenerate
   
   
   always_ff @(posedge clk) begin
      if (enable) begin
	 if (!sel) begin
	    dla[0] <= a_in;
	 end
	 else begin
	    dla[0] <= dlb[L-1];
	 end
      end
   end

   always_comb begin
      b_out = sel ? a_in : dlb[L-1];
   end


   
endmodule
   
