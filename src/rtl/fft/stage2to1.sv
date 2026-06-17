module stage2to1
  #(
    parameter DATA_WIDTH = 19,
    parameter TWIDDLE_WIDTH = 24
    )
   (
    input logic				      clk,
    input logic				      enable,
    input logic signed [DATA_WIDTH-1:0]	      stage2_r[0:15],
    input logic signed [DATA_WIDTH-1:0]	      stage2_i[0:15],
    output logic signed [DATA_WIDTH + 1 -1:0] stage1_r[0:15],
    output logic signed [DATA_WIDTH + 1 -1:0] stage1_i[0:15]
    );
   
   reg signed [DATA_WIDTH + 1 -1:0]	      out_bf1_r[0:3];
   reg signed [DATA_WIDTH + 1 -1:0]	      out_bf1_i[0:3];

   
   (* keep *)  reg signed [DATA_WIDTH + 1 -1:0]	      out_bf2_r[0:3];
   (* keep *)  reg signed [DATA_WIDTH + 1 -1:0]	      out_bf2_i[0:3];
   
   parameter				      DEPTH = TWIDDLE_WIDTH <= 16? 7:8;
   
   genvar				      i;
  // 2 x butterfly type 1
   generate
      for (i = 0; i < 2; i = i + 1) begin : stage2_1_type1
	 butterfly_type1 
	       #(
		 .DATA_WIDTH(DATA_WIDTH)
		 ) 
	 bfly (
               .clk(clk),
               .enable(enable),
               .real_in0(stage2_r[i]),
               .imag_in0(stage2_i[i]),
               .real_in1(stage2_r[i+2]),
               .imag_in1(stage2_i[i+2]),
               .real_out0(out_bf1_r[i]),
               .imag_out0(out_bf1_i[i]),
               .real_out1(out_bf1_r[i+2]),
               .imag_out1(out_bf1_i[i+2])
	       );
      end // block: stage2_1_type1
   endgenerate

   // delay 4 complex values
   generate
      for (i = 0; i < 4; i = i + 1) begin : shift_1
	 shift_complex
	       #(
		 .DATA_WIDTH(DATA_WIDTH + 1),
		 .DEPTH(DEPTH)
		 )
	 shif1
	       (
		.clk(clk),
		.enable(enable),
		.data_in_r(out_bf1_r[i]),
		.data_in_i(out_bf1_i[i]),
		.data_out_r(stage1_r[i]),
		.data_out_i(stage1_i[i])
		);
      end // block: shift_1
   endgenerate
   

   
   // 2 x butterfly type 2
   generate
      for (i = 0; i < 2; i = i + 1) begin : stage2_1_type2
	 (* keep *)	 butterfly_type2 
	       #(
		 .DATA_WIDTH(DATA_WIDTH)
		 )
	 bfly 
	       (
               .clk(clk),
               .enable(enable),
	       .real_in0(stage2_r[i+4]),
               .imag_in0(stage2_i[i+4]),
               .real_in1(stage2_r[i+6]),
               .imag_in1(stage2_i[i+6]),
               .real_out0(out_bf2_r[i]),
               .imag_out0(out_bf2_i[i]),
               .real_out1(out_bf2_r[i+2]),
               .imag_out1(out_bf2_i[i+2])
	       );
      end // block: stage2_1_type2
   endgenerate

   //delay 4 complex values
   generate
      for (i = 0; i < 4; i = i + 1) begin : shift_2
	 shift_complex
	       #(
		 .DATA_WIDTH(DATA_WIDTH + 1),
		 .DEPTH(DEPTH)
		 )
	 shif2
	       (
		.clk(clk),
		.enable(enable),
		.data_in_r(out_bf2_r[i]),
		.data_in_i(out_bf2_i[i]),
		.data_out_r(stage1_r[i+4]),
		.data_out_i(stage1_i[i+4])
		);
      end // block: shift_2
   endgenerate



   
   
   // 2 x butterfly type 3 
   generate
      for (i = 0; i < 2; i = i + 1) begin : stage2_1_type3_0
	 butterfly_type3 
	       #(
		 .DATA_WIDTH(DATA_WIDTH),
		 .TWIDDLE_WIDTH(TWIDDLE_WIDTH),
		 .TWIDDLE_SEL(1'b0)
		 )
	 bfly 
	       (
		.clk(clk),
		.enable(enable),
		.real_in0(stage2_r[i+8]),
		.imag_in0(stage2_i[i+8]),
		.real_in1(stage2_r[i+10]),
		.imag_in1(stage2_i[i+10]),
		.real_out0(stage1_r[i+8]),
		.imag_out0(stage1_i[i+8]),
		.real_out1(stage1_r[i+10]),
		.imag_out1(stage1_i[i+10])
		);
      end // block: stage2_1_type3_0
   endgenerate
   
   // 2 x butterfly type 3 
   generate
      for (i = 0; i < 2; i = i + 1) begin : stage2_1_type3_1
	 butterfly_type3 
	       #(
		 .DATA_WIDTH(DATA_WIDTH),
		 .TWIDDLE_WIDTH(TWIDDLE_WIDTH),
		 .TWIDDLE_SEL(1'b1)
		 ) 
	 bfly 
	       (
		.clk(clk),
		.enable(enable),
		.real_in0(stage2_r[i+12]),
		.imag_in0(stage2_i[i+12]),
		.real_in1(stage2_r[i+14]),
		.imag_in1(stage2_i[i+14]),
		.real_out0(stage1_r[i+12]),
		.imag_out0(stage1_i[i+12]),
		.real_out1(stage1_r[i+14]),
		.imag_out1(stage1_i[i+14])
		);
      end // block: stage2_1_type3_1
      
   endgenerate
   
endmodule // stage2to1

