module stage4to3 
  #(
    parameter int DATA_WIDTH = 16
    )
   (
    input logic				   clk,
    input logic				   enable,
    input logic signed [DATA_WIDTH-1:0]	   stage4_r[0:15],
    input logic signed [DATA_WIDTH-1:0]	   stage4_i[0:15],
    output logic signed [DATA_WIDTH+1-1:0] stage3_r[0:15],
    output logic signed [DATA_WIDTH+1-1:0] stage3_i[0:15]
    );
   
   genvar				 i;
   generate
      for (i = 0; i < 8; i = i + 1) begin : stage4_3
	 butterfly_type1 
	       #(
		 .DATA_WIDTH(DATA_WIDTH)
		 ) 
	 bfly (
	       .clk(clk),
	       .enable(enable),
	       .real_in0(stage4_r[i]), 
	       .imag_in0(stage4_i[i]),
	       .real_in1(stage4_r[i+8]), 
	       .imag_in1(stage4_i[i+8]),
	       .real_out0(stage3_r[i]), 
	       .imag_out0(stage3_i[i]),
	       .real_out1(stage3_r[i+8]), 
	       .imag_out1(stage3_i[i+8])
	       );
      end // block: stage4_3
      
   endgenerate
   
endmodule
