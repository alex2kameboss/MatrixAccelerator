
module butterfly_type3
  #(
    parameter	    DATA_WIDTH = 32,
    parameter	    TWIDDLE_WIDTH = 32,
    parameter [0:0] TWIDDLE_SEL = 1'b1
    )
   (
    input logic				     clk,
    input logic				     enable, 
    input logic signed [DATA_WIDTH-1:0]	     real_in0,
    input logic signed [DATA_WIDTH-1:0]	     imag_in0,
    input logic signed [DATA_WIDTH-1:0]	     real_in1,
    input logic signed [DATA_WIDTH-1:0]	     imag_in1,

    output logic signed [DATA_WIDTH + 1-1:0] real_out0,
    output logic signed [DATA_WIDTH + 1-1:0] imag_out0,
    output logic signed [DATA_WIDTH + 1-1:0] real_out1,
    output logic signed [DATA_WIDTH + 1-1:0] imag_out1
    );


   /*
    Calculates:
    
    For TWIDDLE_SEL = 0:
    
    out0 = in0 + in1*1/sqrt(2)*(1-j)
    out1 = in0 - in1*1/sqrt(2)*(1-j)
    
    For TWIDDLE_SEL = 1:
    
    out0 = in0 + in1*1/sqrt(2)*(-1-j)
    out1 = in0 - in1*1/sqrt(2)*(-1-j)
    
    
    The multiplication with c = 1/sqrt(2)*(1-j) = exp(-2*pi*j/8) is
    done with 16/24/32 bits of precision.
    
    c = 181*2^24 + 5*2^16 -13 * 2^8 + 52 = 3037000500 = 1/sqrt(2)*2^32 as 32 bit number
    
    Largest multiplier 181 - need 8 supplementary bits
    
    Fully pipelined with 7 stages (16 bits precision for twiddle
    factors) or 8 stages (24/32 bits precision for twiddle factors).
    
    Using convergent rounding, or "Rounding half to even", see
    https://zipcpu.com/dsp/2017/07/22/rounding.html
    
    No need for a reset signal, we only need to neglect initial junk
    output.
    
    NOTE: To multiply with c^3 = 1/sqrt(2)*(-1-j), we transform x =
    re+im*j to im-re*j
 
 */

   localparam				     WIDTH_16 = DATA_WIDTH + 16;
   localparam				     WIDTH_24 = DATA_WIDTH + 24;
   localparam				     WIDTH_32 = DATA_WIDTH + 32;

   localparam				     DEPTH = 9;
   
   
   reg signed [DATA_WIDTH-1:0]		     x_re, x_im;
   reg signed [DATA_WIDTH-1:0]		     z_re, z_im;
   
   logic signed [DATA_WIDTH-1+8:0]	     re_c0, re_c1, re_c2, re_c3;
   logic signed [DATA_WIDTH-1+8:0]	     im_c0, im_c1, im_c2, im_c3;
   
   
   logic signed [DATA_WIDTH-1+8:0]	     v1;
   reg signed [DATA_WIDTH-1+8:0]	     v1b, v5, v5b, v11,v13, v181, v5c, mv13, v52;
   
   
   logic signed [DATA_WIDTH-1+8:0]	     w1;
   reg signed [DATA_WIDTH-1+8:0]	     w1b, w5, w5b, w11,w13, w181, w5c, mw13, w52;
   
   reg signed [DATA_WIDTH-1+16:0]	     z_re_c0_16, z_re_c1_16, z_re_c2_16, z_re_c3_16;
   reg signed [DATA_WIDTH-1+16:0]	     z_im_c0_16, z_im_c1_16, z_im_c2_16, z_im_c3_16;
   
   reg signed [DATA_WIDTH-1+16:0]	     z_re_16,z_im_16;
   
   logic signed [DATA_WIDTH-1+16:0]	     z_re_16_conv, z_im_16_conv;

   
   reg signed [DATA_WIDTH-1+24:0]	     z_re_c0_24, z_re_c1_24, z_re_c2_24, z_re_c3_24;
   reg signed [DATA_WIDTH-1+24:0]	     z_im_c0_24, z_im_c1_24, z_im_c2_24, z_im_c3_24;
   
   reg signed [DATA_WIDTH-1+24:0]	     z1_re_24, z1_im_24, z_re_24,z_im_24;
   
   logic signed [DATA_WIDTH-1+24:0]	     z_re_24_conv, z_im_24_conv;
   
   reg signed [DATA_WIDTH-1+16:0]	     z_re_c0_32, z_re_c1_32, z_re_c2_32, z_re_c3_32;
   reg signed [DATA_WIDTH-1+16:0]	     z_im_c0_32, z_im_c1_32, z_im_c2_32, z_im_c3_32;
   
   reg signed [DATA_WIDTH-1+32:0]	     z1_re_32, z1_im_32, z2_re_32, z2_im_32, z_re_32,  z_im_32;
   logic signed [DATA_WIDTH-1+32:0]	     z_re_32_conv,  z_im_32_conv;
   
   logic signed [DATA_WIDTH-1:0]	     add_re[0:DEPTH-1];
   logic signed [DATA_WIDTH-1:0]	     add_im[0:DEPTH-1];
   
   
 
   genvar				     i;
   
   
   always_ff @(posedge clk) begin
      if (enable) begin
	 if (TWIDDLE_SEL == 0) begin
	    x_re      <=  real_in1;
	    x_im      <=  imag_in1;
	 end else begin
	    x_re      <=  imag_in1;
	    x_im      <=  -real_in1;
	 end
      end
   end
   
   always_ff @(posedge clk) begin
      if(enable) begin
	 add_re[0] <= real_in0;
	 add_im[0] <= imag_in0;
      end
   end
   
   
   generate
      for (i = 0; i < DEPTH-1; i = i + 1) begin  
	 always_ff @(posedge clk) begin
	    if (enable) begin
	       add_re[i+1] <= add_re[i];
	       add_im[i+1] <= add_im[i];
	    end
	 end
      end
   endgenerate
   
   //copy x_re to v1 with sign extension	  


   assign v1[DATA_WIDTH+7] =  x_re[DATA_WIDTH-1];
   assign v1[DATA_WIDTH+6] =  x_re[DATA_WIDTH-1];
   assign v1[DATA_WIDTH+5] =  x_re[DATA_WIDTH-1];
   assign v1[DATA_WIDTH+4] =  x_re[DATA_WIDTH-1];
   assign v1[DATA_WIDTH+3] =  x_re[DATA_WIDTH-1];
   assign v1[DATA_WIDTH+2] =  x_re[DATA_WIDTH-1];
   assign v1[DATA_WIDTH+1] =  x_re[DATA_WIDTH-1];
   assign v1[DATA_WIDTH+0] =  x_re[DATA_WIDTH-1];

   assign v1[DATA_WIDTH-1:0] = x_re[DATA_WIDTH-1:0];

   
   
   always_ff @(posedge clk) begin 
      if (enable) begin
	 v1b <= v1;
	 v5  <= (v1 <<< 2) + v1;
      end
   end

   always_ff @(posedge clk) begin 
      if(enable) begin
	 v11  <= (v1b <<< 4) - v5;
	 v13  <= (v1b <<< 3) + v5;
	 v5b  <= v5;
      end
   end

   always_ff @(posedge clk) begin 
      if(enable) begin
	 v181 <= (v11 <<< 4) + v5b;
	 v5c  <= v5b;
	 mv13 <= -v13;
	 v52  <= v13 <<< 2;
      end
   end
   
   
   assign re_c0 = v181;
   assign re_c1 = v5c;
   
   if (TWIDDLE_WIDTH > 16) begin : v_multipliers_for_24bits
      assign re_c2 = mv13;
   end
   
   
   if (TWIDDLE_WIDTH > 24) begin : v_multipliers_for_32bits
      assign re_c3 = v52;
   end

  
   assign w1[DATA_WIDTH+7] =  x_im[DATA_WIDTH-1];
   assign w1[DATA_WIDTH+6] =  x_im[DATA_WIDTH-1];
   assign w1[DATA_WIDTH+5] =  x_im[DATA_WIDTH-1];
   assign w1[DATA_WIDTH+4] =  x_im[DATA_WIDTH-1];
   assign w1[DATA_WIDTH+3] =  x_im[DATA_WIDTH-1];
   assign w1[DATA_WIDTH+2] =  x_im[DATA_WIDTH-1];
   assign w1[DATA_WIDTH+1] =  x_im[DATA_WIDTH-1];
   assign w1[DATA_WIDTH+0] =  x_im[DATA_WIDTH-1];

   assign w1[DATA_WIDTH-1:0] = x_im[DATA_WIDTH-1:0];


   always_ff @(posedge clk) begin 
      if(enable) begin
	 w1b <= w1;
	 w5  <= (w1 <<< 2) + w1;
      end
   end

   always_ff @(posedge clk) begin 
      if(enable) begin
	 w11  <= (w1b <<< 4) - w5;
	 w13  <= (w1b <<< 3) + w5;
	 w5b  <= w5;
      end
   end

   always_ff @(posedge clk) 
     begin if(enable) begin
	w181 <= (w11 <<< 4) + w5b;
	w5c  <= w5b;
	mw13 <= -w13;
	w52  <= w13 <<< 2;
     end
   end
   
   
   assign im_c0 = w181;
   assign im_c1 = w5c;
   
   if (TWIDDLE_WIDTH > 16) begin :  w_multipliers_for_24bits
      assign im_c2 = mw13;
   end
   if (TWIDDLE_WIDTH > 24) begin :  w_multipliers_for_32bits
      assign im_c3 = w52;
   end

 
   if (TWIDDLE_WIDTH <= 16) begin : twiddle_16bits
      always_ff @(posedge clk) begin 
	 if(enable) begin
	    z_re_c0_16 <= (WIDTH_16)'(re_c0 + im_c0) <<< 8;
	    z_re_c1_16 <= (WIDTH_16)'(re_c1 + im_c1);
	    z_im_c0_16 <= (WIDTH_16)'(im_c0 - re_c0) <<< 8;
	    z_im_c1_16 <= (WIDTH_16)'(im_c1 - re_c1);
	 end
      end

      always_ff @(posedge clk) begin 
	 if(enable) begin
	    z_re_16 <= z_re_c0_16 + z_re_c1_16;
	    z_im_16 <= z_im_c0_16 + z_im_c1_16;
	 end
      end

      always_ff @(posedge clk) begin
	 if (enable) begin
	    z_re_16_conv <= z_re_16[(WIDTH_16-1):0]
			    + { {(DATA_WIDTH){1'b0}},
				z_re_16[(WIDTH_16-DATA_WIDTH)],
				{(WIDTH_16-DATA_WIDTH-1){!z_re_16[(WIDTH_16-DATA_WIDTH)]}}};
	    
	    z_im_16_conv <= z_im_16[(WIDTH_16-1):0]
			    + { {(DATA_WIDTH){1'b0}},
				z_im_16[(WIDTH_16-DATA_WIDTH)],
				{(WIDTH_16-DATA_WIDTH-1){!z_im_16[(WIDTH_16-DATA_WIDTH)]}}};
	 end
      end
      
      always_ff @(posedge clk) begin 
	 if(enable) begin
	    z_re  <=  z_re_16_conv[(WIDTH_16-1):(WIDTH_16-DATA_WIDTH)];
	    z_im  <=  z_im_16_conv[(WIDTH_16-1):(WIDTH_16-DATA_WIDTH)];
	 end
      end
      
      always_ff @(posedge clk) begin 
	 if(enable) begin
	    real_out0  <=  add_re[DEPTH-2] + z_re;
	    imag_out0  <=  add_im[DEPTH-2] + z_im;
	    
	    real_out1  <= add_re[DEPTH-2] - z_re;
  	    imag_out1  <= add_im[DEPTH-2] - z_im;
	 end
      end
   end // block: twiddle_16bits
   

   


   
   if (TWIDDLE_WIDTH > 16 && TWIDDLE_WIDTH <= 24) begin : twiddle_24bits
      always_ff @(posedge clk) begin 
	 if(enable) begin
	    z_re_c0_24 <= (WIDTH_24)'(re_c0 + im_c0) <<< 16;
	    z_re_c1_24 <= (WIDTH_24)'(re_c1 + im_c1) <<< 8;
	    z_re_c2_24 <= (WIDTH_24)'(re_c2 + im_c2);
	    
	    z_im_c0_24 <= (WIDTH_24)'(im_c0 - re_c0) <<< 16;
	    z_im_c1_24 <= (WIDTH_24)'(im_c1 - re_c1) <<< 8;
	    z_im_c2_24 <= (WIDTH_24)'(im_c2 - re_c2);
	 end
      end

      always_ff @(posedge clk) begin 
	 if(enable) begin
	    z1_re_24 <= z_re_c0_24 + z_re_c1_24;
	    z1_im_24 <= z_im_c0_24 + z_im_c1_24;
	 end
      end
      always_ff @(posedge clk) begin 
	 if(enable) begin
	    z_re_24 <= z1_re_24 +  z_re_c2_24;
	    z_im_24 <= z1_im_24 +  z_im_c2_24;
	 end
      end
      
      always_ff @(posedge clk) begin
	 if (enable) begin
            z_re_24_conv <= z_re_24[(WIDTH_24-1):0]
			    + { {(DATA_WIDTH){1'b0}},
				z_re_24[(WIDTH_24-DATA_WIDTH)],
				{(WIDTH_24-DATA_WIDTH-1){!z_re_24[(WIDTH_24-DATA_WIDTH)]}}};
	    
            z_im_24_conv <= z_im_24[(WIDTH_24-1):0]
			    + { {(DATA_WIDTH){1'b0}},
				z_im_24[(WIDTH_24-DATA_WIDTH)],
				{(WIDTH_24-DATA_WIDTH-1){!z_im_24[(WIDTH_24-DATA_WIDTH)]}}};
	 end
      end
      
      
      always_ff @(posedge clk) begin 
	 if(enable) begin
	    z_re <= z_re_24_conv[(WIDTH_24-1):(WIDTH_24-DATA_WIDTH)];
	    z_im <= z_im_24_conv[(WIDTH_24-1):(WIDTH_24-DATA_WIDTH)];
	 end
      end
      
      always_ff @(posedge clk) begin 
	 if(enable) begin
	    real_out0  <= add_re[DEPTH-1]  + z_re;
	    imag_out0  <= add_im[DEPTH-1]  + z_im;
	    
	    real_out1  <=  add_re[DEPTH-1] - z_re;
  	    imag_out1  <=  add_im[DEPTH-1] - z_im;
	 end
      end
   end // block: twiddle_24bits
   
   

   
   if (TWIDDLE_WIDTH > 24) begin : twiddle_32bits
      always_ff @(posedge clk) begin 
	 if(enable) begin
	    z_re_c0_32 <= (WIDTH_16)'(re_c0 + im_c0) <<< 8;
	    z_re_c1_32 <= (WIDTH_16)'(re_c1 + im_c1);
	    
	    z_re_c2_32 <= (WIDTH_16)'(re_c2 + im_c2) <<< 8;
	    z_re_c3_32 <= (WIDTH_16)'(re_c3 + im_c3);
	    
	    z_im_c0_32 <= (WIDTH_16)'(im_c0 - re_c0) <<< 8;
	    z_im_c1_32 <= (WIDTH_16)'(im_c1 - re_c1);
	    
	    z_im_c2_32 <= (WIDTH_16)'(im_c2 - re_c2) <<< 8;
	    z_im_c3_32 <= (WIDTH_16)'(im_c3 - re_c3);
	 end // if (enable)
      end
      
      always_ff @(posedge clk) begin 
	 if(enable) begin
	    z1_re_32 <= (WIDTH_32)'(z_re_c0_32  + z_re_c1_32) <<< 16;
	    z1_im_32 <= (WIDTH_32)'(z_im_c0_32 +  z_im_c1_32) <<< 16;
	    
	    z2_re_32 <= (WIDTH_32)'(z_re_c2_32  + z_re_c3_32);
	    z2_im_32 <= (WIDTH_32)'(z_im_c2_32  + z_im_c3_32);
	 end
      end

      always_ff @(posedge clk) begin 
	 if(enable) begin
	    z_re_32 <= z1_re_32 + z2_re_32;
	    z_im_32 <= z1_im_32 + z2_im_32;
	 end
      end

      always_ff @(posedge clk) begin
	 if (enable) begin
	    z_re_32_conv <= z_re_32[(WIDTH_32-1):0]
			    + { {(DATA_WIDTH){1'b0}},
				z_re_32[(WIDTH_32-DATA_WIDTH)],
				{(WIDTH_32-DATA_WIDTH-1){!z_re_32[(WIDTH_32-DATA_WIDTH)]}}};
	    
	    z_im_32_conv <= z_im_32[(WIDTH_32-1):0]
			    + { {(DATA_WIDTH){1'b0}},
				z_im_32[(WIDTH_32-DATA_WIDTH)],
				{(WIDTH_32-DATA_WIDTH-1){!z_im_32[(WIDTH_32-DATA_WIDTH)]}}};
	 end
      end
      
      always_ff @(posedge clk) begin 
	 if(enable) begin
	    z_re  <=  z_re_32_conv[(WIDTH_32-1):(WIDTH_32-DATA_WIDTH)];
	    z_im  <=  z_im_32_conv[(WIDTH_32-1):(WIDTH_32-DATA_WIDTH)];
	 end
      end
      
      always_ff @(posedge clk) begin 
	 if(enable) begin
	    real_out0  <=  add_re[DEPTH-1] + z_re;
	    imag_out0  <=  add_im[DEPTH-1] + z_im;
	    
	    real_out1  <=  add_re[DEPTH-1] - z_re ;
  	    imag_out1  <=  add_im[DEPTH-1] - z_im ;
	 end
      end
   end // block: twiddle_32bits
   
   

   
   
   
endmodule 




 
 
