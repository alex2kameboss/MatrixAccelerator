module stage3to2 
  #(
    parameter int DATA_WIDTH = 16
    )
   (
    input logic				 clk,
    input logic				 enable,
    input logic signed [DATA_WIDTH-1:0]	 stage3_r[0:15],
    input logic signed [DATA_WIDTH-1:0]	 stage3_i[0:15],
    output logic signed [DATA_WIDTH+1-1:0] stage2_r[0:15],
    output logic signed [DATA_WIDTH+1-1:0] stage2_i[0:15]
    );
   
   genvar				 i;
   // 4 x butterfly type 1
   generate
      for (i = 0; i < 4; i = i + 1) begin : stage3_2_type1
	 butterfly_type1 
	       #(
		 .DATA_WIDTH(DATA_WIDTH)
		 ) 
	 bfly1 (
	       .clk(clk),
               .enable(enable),
	       .real_in0(stage3_r[i]), 
               .imag_in0(stage3_i[i]),
               .real_in1(stage3_r[i+4]), 
               .imag_in1(stage3_i[i+4]),
               .real_out0(stage2_r[i]),
               .imag_out0(stage2_i[i]),
               .real_out1(stage2_r[i+4]),
               .imag_out1(stage2_i[i+4])
	       );
      end // block: stage3_2_type1
      
   endgenerate

   // 4 x butterfly type 2
   generate
      for (i = 0; i < 4; i = i + 1) begin : stage3_2_type2
	 butterfly_type2 
	       #(
		 .DATA_WIDTH(DATA_WIDTH)
		 ) 
	 bfly2 (
               .clk(clk),
               .enable(enable),
	       .real_in0(stage3_r[i+8]), 
               .imag_in0(stage3_i[i+8]),
               .real_in1(stage3_r[i+12]), 
               .imag_in1(stage3_i[i+12]),
               .real_out0(stage2_r[i+8]),
               .imag_out0(stage2_i[i+8]),
               .real_out1(stage2_r[i+12]),
               .imag_out1(stage2_i[i+12])
	       );
      end // block: stage3_2_type2
      
   endgenerate
   
endmodule
