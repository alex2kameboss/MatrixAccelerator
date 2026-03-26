module column_multipliers_16 
  #(
    parameter DATA_WIDTH = 16+1+4,
    parameter TWIDDLE_WIDTH = 17
    )
   (
    input logic				   clk,
    input logic				   enable,
    input logic [15:0]			   mult_one, 
    
    input logic signed [DATA_WIDTH-1:0]	   zr[0:15],
    input logic signed [DATA_WIDTH-1:0]	   zi[0:15],

    input logic signed [TWIDDLE_WIDTH-1:0] c[0:15],
    input logic signed [TWIDDLE_WIDTH-1:0] s[0:15],
    
    output logic signed [DATA_WIDTH -1:0]  Zr[0:15],
    output logic signed [DATA_WIDTH -1:0]  Zi[0:15]

    );

   parameter				  DEPTH = 5;
 
   genvar				  i;

   logic signed [DATA_WIDTH -1:0]	  Z1r[0:15];
   logic signed [DATA_WIDTH -1:0]	  Z1i[0:15];
   
   logic signed [DATA_WIDTH -1:0]	  Z2r[0:15];
   logic signed [DATA_WIDTH -1:0]	  Z2i[0:15];

   logic [15:0]				  mult_one_save;
   
					 
   shift
     #(
       .DATA_WIDTH(16),
       .DEPTH(DEPTH+1)
       )
   one
     (
      .clk(clk),
      .enable(enable),
      .data_in(mult_one),
      .data_out(mult_one_save)
      );

	 
   //First multiplier is always 1 so for the input zr and zi at index 0 we only need to delay as needed for other multiplications
   shift_complex
     #(
       .DATA_WIDTH(DATA_WIDTH),
       .DEPTH(DEPTH+1)
       )
   shif0
     (
      .clk(clk),
      .enable(enable),
      .data_in_r(zr[0]),
      .data_in_i(zi[0]),
      .data_out_r(Zr[0]),
      .data_out_i(Zi[0])
      );

   //shift all other inputs
    
   generate
      for (i = 1; i < 16; i = i + 1) begin : shift1
	 shift_complex
	       #(
		 .DATA_WIDTH(DATA_WIDTH),
		 .DEPTH(DEPTH)
		 )
	 shif
	       (
		.clk(clk),
		.enable(enable),
		.data_in_r(zr[i]),
		.data_in_i(zi[i]),
		.data_out_r(Z1r[i]),
		.data_out_i(Z1i[i])
		);
      end // block: shift1
   endgenerate

   //in parallel multiply with twiddle factors

   generate
      for (i = 1; i < 16; i = i + 1) begin : row_mult
	 mult_complex_3DSP
	       #(
		 .DATA_WIDTH(DATA_WIDTH),
		 .TWIDDLE_WIDTH(TWIDDLE_WIDTH)
		 )
	 multiplier
	       (
		.clk(clk),
		.enable(enable),
		.zr(zr[i]),
		.zi(zi[i]),
		.c(c[i]),
		.s(s[i]),
		.Zr(Z2r[i]),
		.Zi(Z2i[i])
		);
	 
      end // block: row_mult
   endgenerate

   //select correct output - either original input if multiplication by 1 or the result of mult with twiddle factor if not
   
   generate
      for (i = 1; i < 16; i = i + 1) begin : choice
	 always @(posedge clk) begin
	    Zr[i] <= mult_one_save[i] ? Z1r[i] : Z2r[i];
	    Zi[i] <= mult_one_save[i] ? Z1i[i] : Z2i[i];
	 end
      end
   endgenerate
   
     
endmodule // row_multipliers_16

