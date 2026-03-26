module stage1to0 
  #(
    parameter DATA_WIDTH = 20,
    parameter TWIDDLE_WIDTH = 24
    )
   (
    input logic				      clk,
    
    input logic				      enable,
    input logic signed [DATA_WIDTH-1:0]	      stage1_r[0:15],
    input logic signed [DATA_WIDTH-1:0]	      stage1_i[0:15],
    output logic signed [DATA_WIDTH + 1 -1:0] stage0_r[0:15],
    output logic signed [DATA_WIDTH + 1 -1:0] stage0_i[0:15]
);

   logic signed [DATA_WIDTH + 1 -1:0]	      out_bf1_r[0:1];
   logic signed [DATA_WIDTH + 1 -1:0]	      out_bf1_i[0:1];
   logic signed [DATA_WIDTH + 1 -1:0]	      out_bf2_r[0:1];
   logic signed [DATA_WIDTH + 1 -1:0]	      out_bf2_i[0:1];
   
   parameter				      DEPTH =  TWIDDLE_WIDTH <= 16? 7:8;
   
   
   genvar				      i;

   // Index 0 Butterfly Type 1
   butterfly_type1 
     #(
       .DATA_WIDTH(DATA_WIDTH)
       ) 
   bfly_stage1_0 
     (
      .clk(clk),
      .enable(enable),
      .real_in0(stage1_r[0]), 
      .imag_in0(stage1_i[0]),
      .real_in1(stage1_r[1]), 
      .imag_in1(stage1_i[1]),
      .real_out0(out_bf1_r[0]), 
      .imag_out0(out_bf1_i[0]),
      .real_out1(out_bf1_r[1]), 
      .imag_out1(out_bf1_i[1])
      );

   generate
      for (i = 0; i < 2; i = i + 1) begin : shift_1
	 shift_complex
	       #(
		 .DATA_WIDTH(DATA_WIDTH + 1),
		 .DEPTH(DEPTH)
		 )
	 shif
	       (
		.clk(clk),
		.enable(enable),
		.data_in_r(out_bf1_r[i]),
		.data_in_i(out_bf1_i[i]),
		.data_out_r(stage0_r[i]),
		.data_out_i(stage0_i[i])
		);
      end // block: shift_1
   endgenerate

   // Index 1 Butterfly Type 2
   butterfly_type2 
     #(
       .DATA_WIDTH(DATA_WIDTH)
       ) 
   bfly_stage1_1 
     (
      .clk(clk),
      .enable(enable),
      .real_in0(stage1_r[2]), 
      .imag_in0(stage1_i[2]),
      .real_in1(stage1_r[3]), 
      .imag_in1(stage1_i[3]),
      .real_out0(out_bf2_r[0]), 
      .imag_out0(out_bf2_i[0]),
      .real_out1(out_bf2_r[1]), 
      .imag_out1(out_bf2_i[1])
      );

   
   generate
      for (i = 0; i < 2; i = i + 1) begin : shift_2
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
		.data_out_r(stage0_r[i+2]),
		.data_out_i(stage0_i[i+2])
		);
      end // block: shift_2
   endgenerate

   
   // Index 2  Butterfly Type 3 
   butterfly_type3 
     #(
       .DATA_WIDTH(DATA_WIDTH),
       .TWIDDLE_WIDTH(TWIDDLE_WIDTH),
       .TWIDDLE_SEL(1'b0)
       ) 
   bfly_stage1_2 
     (
      .clk(clk),
      .enable(enable),
      .real_in0(stage1_r[4]), 
      .imag_in0(stage1_i[4]),
      .real_in1(stage1_r[5]), 
      .imag_in1(stage1_i[5]),
      .real_out0(stage0_r[4]), 
      .imag_out0(stage0_i[4]),
      .real_out1(stage0_r[5]), 
      .imag_out1(stage0_i[5])
      );

  // Index 4 Butterfly Type 3 
  butterfly_type3 
    #(
      .DATA_WIDTH(DATA_WIDTH),
      .TWIDDLE_WIDTH(TWIDDLE_WIDTH),
      .TWIDDLE_SEL(1'b1)
      ) 
   bfly_stage1_4 
     (
      .clk(clk),
      .enable(enable),
      .real_in0(stage1_r[6]), 
      .imag_in0(stage1_i[6]),
      .real_in1(stage1_r[7]), 
      .imag_in1(stage1_i[7]),
      .real_out0(stage0_r[6]), 
      .imag_out0(stage0_i[6]),
      .real_out1(stage0_r[7]), 
      .imag_out1(stage0_i[7])
      );

   //Order of the four butterflies of type 4:
   //             omega^[1,  5,  3,  7]
   // TWIDDLE_SEL:       00, 01, 10, 11

  butterfly_type4 
    #(
      .DATA_WIDTH(DATA_WIDTH),
      .TWIDDLE_WIDTH(TWIDDLE_WIDTH),
      .TWIDDLE_SEL(2'b00)
      ) 
   bfly_8_9 
     (
      .clk(clk),
      .enable(enable),
      .real_in0(stage1_r[8]), 
      .imag_in0(stage1_i[8]),
      .real_in1(stage1_r[9]), 
      .imag_in1(stage1_i[9]),
      .real_out0(stage0_r[8]), 
      .imag_out0(stage0_i[8]),
      .real_out1(stage0_r[9]), 
      .imag_out1(stage0_i[9])
      );
   

  butterfly_type4 
    #(
      .DATA_WIDTH(DATA_WIDTH),
      .TWIDDLE_WIDTH(TWIDDLE_WIDTH),
      .TWIDDLE_SEL(2'b01)
      ) 
   bfly_10_11 
     (
      .clk(clk),
      .enable(enable),
      .real_in0(stage1_r[10]), 
      .imag_in0(stage1_i[10]),
      .real_in1(stage1_r[11]), 
      .imag_in1(stage1_i[11]),
      .real_out0(stage0_r[10]), 
      .imag_out0(stage0_i[10]),
      .real_out1(stage0_r[11]), 
      .imag_out1(stage0_i[11])
      );

  butterfly_type4 
    #(
    .DATA_WIDTH(DATA_WIDTH),
      .TWIDDLE_WIDTH(TWIDDLE_WIDTH),
      .TWIDDLE_SEL(2'b10)
      ) 
   bfly_12_13 
     (
      .clk(clk),
      .enable(enable),
      .real_in0(stage1_r[12]), 
      .imag_in0(stage1_i[12]),
      .real_in1(stage1_r[13]), 
      .imag_in1(stage1_i[13]),
      .real_out0(stage0_r[12]), 
      .imag_out0(stage0_i[12]),
      .real_out1(stage0_r[13]), 
      .imag_out1(stage0_i[13])
      );

  butterfly_type4 
    #(
      .DATA_WIDTH(DATA_WIDTH),
      .TWIDDLE_WIDTH(TWIDDLE_WIDTH),
      .TWIDDLE_SEL(2'b11)
      ) 
   bfly_14_15 
     (
      .clk(clk),
      .enable(enable),
      .real_in0(stage1_r[14]), 
      .imag_in0(stage1_i[14]),
      .real_in1(stage1_r[15]), 
      .imag_in1(stage1_i[15]),
      .real_out0(stage0_r[14]), 
      .imag_out0(stage0_i[14]),
      .real_out1(stage0_r[15]), 
      .imag_out1(stage0_i[15])
      );
   
endmodule // stage1to0

