module butterfly_type4

  #(
    parameter DATA_WIDTH = 32,
    parameter TWIDDLE_WIDTH = 32,
    parameter [1:0] TWIDDLE_SEL = 2'b11
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
    
    For TWIDDLE_SEL = 2'b00: omega
    
    out0 = in0 + in1*(c-s*j)
    out1 = in0 - in1*(c-s*j) 
    
    For TWIDDLE_SEL = 2'b10: omega^3
    
    out0 = in0 + in1*(s-c*j)
    out1 = in0 - in1*(s-c*j) 
    
    For TWIDDLE_SEL = 2'b01: omega^5
    
    out0 = in0 + in1*(-s-c*j)
    out1 = in0 - in1*(-s-c*j) 
    
    For TWIDDLE_SEL = 2'b11: omega^7
    
    out0 = in0 + in1*(-c-s*j)
    out1 = in0 - in1*(-c-s*j) 
    
    
    The multiplication with omega = c-s*j = exp(-2*pi*j/8) is done
    with 16/24/32 bits of precision.
 
  
    c = 237*2^24 -125*2^16 +94 * 2^8 + 122 = 3968032378 =
    cos(2*pi/16)*2^32 rounded to closest 32 bit number
    
    s = 98*2^24 -8*2^16 -117*2^8 -101 = 1643612827 = cos(2*pi/16)*2^32
    rounded to closest 32 bit number
  
    Largest multiplier 237 - need 8 supplementary bits

    Fully pipelined with 7 stages (16 bits precision) or 8 stages
    (24/32 bits precision)

    Using convergent rounding, or "Rounding half to even", see
    https://zipcpu.com/dsp/2017/07/22/rounding.html

    No need for a reset signal, we only need to neglect initial junk
    output.
 
    NOTE: For FFT radix 2, we need to multiply a complex number z=a+bi
       by omega=exp(-2*pi*j/8), omega^3, omega^5 and omega^7. For this
       we change the input/output as follows:
 
    to multiply by omega   = (c-sj)   - multiply (a+bj)  by (c-sj)
    to multiply by omega^3 = (s-cj)   - multiply (b+aj)  by (c-sj) and take conjugate
    to multiply by omega^5 = (-s-cj)  - multiply (b-aj)  by (c-sj) 
    to multiply by omega^7 = (-c-sj)  - multiply (-a+bj) by (c-sj) and take conjugate
    */

   localparam				     WIDTH_16 = DATA_WIDTH + 16;
   localparam				     WIDTH_24 = DATA_WIDTH + 24;
   localparam				     WIDTH_32 = DATA_WIDTH + 32;
   
   localparam				     DEPTH = 9;

   logic signed [DATA_WIDTH-1:0]	   x_re,x_im;
   reg signed [DATA_WIDTH-1:0]		   z_re, z_im;
   
   
   logic signed [DATA_WIDTH-1+8:0]	   re_c0, re_c1, re_c2, re_c3;
   logic signed [DATA_WIDTH-1+8:0]	   re_s0, re_s1, re_s2, re_s3;
   logic signed [DATA_WIDTH-1+8:0]	   im_c0, im_c1, im_c2, im_c3;
   logic signed [DATA_WIDTH-1+8:0]	   im_s0, im_s1, im_s2, im_s3;
   
   
   logic signed [DATA_WIDTH-1+8:0]	   v1;
   reg signed [DATA_WIDTH-1+8:0]	   v1b, v1bb, v3, v3b, v47, v49, v61, v125, mv117, v237, mv101, v94, v98, v122, mv125, mv8;
   
   
	 
   logic signed [DATA_WIDTH-1+8:0]	   w1;
   reg signed [DATA_WIDTH-1+8:0]	   w1b, w1bb, w3, w3b, w47, w49, w61, w125, mw117, w237, mw101, w94, w98, w122, mw125, mw8;
   
   reg signed [DATA_WIDTH-1+16:0]	   z_re_c0_16, z_re_c1_16, z_re_c2_16, z_re_c3_16;
   reg signed [DATA_WIDTH-1+16:0]	   z_im_c0_16, z_im_c1_16, z_im_c2_16, z_im_c3_16;
   
   reg signed [DATA_WIDTH-1+16:0]	   z_re_16,z_im_16;
   
   logic signed [DATA_WIDTH-1+16:0]	   z_re_16_conv, z_im_16_conv;
   
   reg signed [DATA_WIDTH-1+24:0]	   z_re_c0_24, z_re_c1_24, z_re_c2_24, z_re_c3_24;
   reg signed [DATA_WIDTH-1+24:0]	   z_im_c0_24, z_im_c1_24, z_im_c2_24, z_im_c3_24;
   
   reg signed [DATA_WIDTH-1+24:0]	   z1_re_24, z1_im_24, z_re_24,z_im_24;
   
   logic signed [DATA_WIDTH-1+24:0]	   z_re_24_conv, z_im_24_conv;
   
   reg signed [DATA_WIDTH-1+16:0]	   z_re_c0_32, z_re_c1_32, z_re_c2_32, z_re_c3_32;
   reg signed [DATA_WIDTH-1+16:0]	   z_im_c0_32, z_im_c1_32, z_im_c2_32, z_im_c3_32;
   
   reg signed [DATA_WIDTH-1+32:0]	   z1_re_32, z1_im_32, z2_re_32, z2_im_32, z_re_32,  z_im_32;
   logic signed [DATA_WIDTH-1+32:0]	   z_re_32_conv,  z_im_32_conv;
   
   logic signed [DATA_WIDTH-1:0]	   add_re[0:DEPTH-1];
   logic signed [DATA_WIDTH-1:0]	   add_im[0:DEPTH-1];
   
 
   
   genvar				     i;

   always_ff @(posedge clk) begin
      if (enable) begin
  	 if (TWIDDLE_SEL == 2'b00) begin
	     x_re      <=  real_in1;
	     x_im      <=  imag_in1;
	 end
	 if (TWIDDLE_SEL == 2'b10) begin
	     x_re      <=  imag_in1;
	     x_im      <=  real_in1;
	 end
	 if (TWIDDLE_SEL == 2'b01) begin
	     x_re      <=  imag_in1;
	     x_im      <=  -real_in1;
	 end
	 if (TWIDDLE_SEL == 2'b11) begin
	     x_re      <= -real_in1;
	     x_im      <=  imag_in1;
	 end
      end // if (enable)
   end // always_ff @ (posedge clk)
   
   
   
   always_ff @(posedge clk) begin
      if(enable) begin
	 add_re[0] <= real_in0;
	 add_im[0] <= imag_in0;
      end
   end
   
    
   generate
      for (i = 0; i < DEPTH-1; i = i + 1) begin  
	 always_ff @(posedge clk) begin 
	    if(enable) begin
	       add_re[i+1] <= add_re[i];
	       add_im[i+1] <= add_im[i];
	    end
	 end
      end
   endgenerate

   //copy re to v1 with sign extension	  

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
      if(enable) begin
	 v1b <= v1;
	 v3  <= (v1 <<< 2) - v1;
      end
   end
   
   always_ff @(posedge clk) begin 
      if(enable) begin
	 v47  <= (v3 <<< 4) - v1b;
	 v49  <= (v3 <<< 4) + v1b;
	 v61  <= (v1b <<< 6) - v3;
	 v125 <= (v1b <<< 7) - v3;
	 v1bb <= v1b;
	 v3b  <= v3;
      end
   end
   
   always_ff @(posedge clk) begin 
      if(enable) begin
	 mv117 <= (v1bb << 3) - v125;
	 v237 <= (v47 <<< 2) + v49;
	 mv101 <= -((v49 <<< 1) + v3b);
	 v94  <= v47 <<< 1;
	 v98  <= v49 <<< 1;
	 v122 <= v61 <<< 1;
	 mv125 <= -v125;
	 mv8   <= -(v1bb <<< 3);
      end
   end
   
   
   assign re_c0 = v237;
   assign re_c1 = mv125;
   assign re_s0 = v98;
   assign re_s1 = mv8;
   
   
   if (TWIDDLE_WIDTH > 16) begin : v_multipliers_for_24bits
      assign re_c2 = v94;
      assign re_s2 = mv117;
   end
   
   if (TWIDDLE_WIDTH > 24) begin : v_multipliers_for_32bits
      assign re_c3 = v122;
      assign re_s3 = mv101;
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
	 w3  <= (w1 <<< 2) - w1;
      end
   end
   
   always_ff @(posedge clk) begin 
      if(enable) begin
	 w47  <= (w3 <<< 4) - w1b;
	 w49  <= (w3 <<< 4) + w1b;
	 w61  <= (w1b <<< 6) - w3;
	 w125 <= (w1b <<< 7) - w3;
	 w1bb <= w1b;
	 w3b  <= w3;
      end
   end
   

   always_ff @(posedge clk) begin 
      if(enable) begin
	 mw117 <= (w1bb << 3) - w125;
	 w237  <= (w47 <<< 2) + w49;
	 mw101 <= -((w49 <<< 1) + w3b);
	 w94   <= w47 <<< 1;
	 w98   <= w49 <<< 1;
	 w122  <= w61 <<< 1;
	 mw125 <= -w125;
	 mw8   <= -(w1bb <<< 3);
      end
   end
   
   
   assign im_c0 = w237;
   assign im_c1 = mw125;
   assign im_s0 = w98;
   assign im_s1 = mw8;
   
 
   if (TWIDDLE_WIDTH > 16) begin : w_multipliers_for_24bits
      assign im_c2 = w94;
      assign im_s2 = mw117;
   end
   if (TWIDDLE_WIDTH > 24) begin : w_multipliers_for_32bits
      assign im_c3 = w122;
      assign im_s3 = mw101;
   end
   
   
   
 
   if (TWIDDLE_WIDTH <= 16) begin  : twiddle_16bits
      always_ff @(posedge clk) begin 
	 if(enable) begin
	    z_re_c0_16 <= (WIDTH_16)'(re_c0 + im_s0) <<< 8;
	    z_re_c1_16 <= (WIDTH_16)'(re_c1 + im_s1);
	    z_im_c0_16 <= (WIDTH_16)'(im_c0 - re_s0) <<< 8;
	    z_im_c1_16 <= (WIDTH_16)'(im_c1 - re_s1);
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
	 end // if (enable)
   end // always_ff @ (posedge clk)
      
    always_ff @(posedge clk) begin 
	   if(enable) begin
	    z_re  <=  z_re_16_conv[(WIDTH_16-1):(WIDTH_16-DATA_WIDTH)];
	    z_im  <=  z_im_16_conv[(WIDTH_16-1):(WIDTH_16-DATA_WIDTH)];  
	  end
    end
      
    always_ff @(posedge clk) begin 
	 if(enable) begin
	    real_out0  <=  add_re[DEPTH-2] + z_re;
	    real_out1  <=  add_re[DEPTH-2] - z_re ;
	    
	    if (TWIDDLE_SEL == 2'b00 || TWIDDLE_SEL == 2'b01  ) begin
	       imag_out0  <=  add_im[DEPTH-2] + z_im;
	       imag_out1  <=  add_im[DEPTH-2] - z_im ;
	    end else begin
	       imag_out0  <= add_im[DEPTH-2] - z_im;
	       imag_out1  <= add_im[DEPTH-2] + z_im;
	    end
	 end
      end
   end // block: twiddle_16bits
   
   

   
   if (TWIDDLE_WIDTH > 16 && TWIDDLE_WIDTH <= 24) begin : twiddle_24bits
      always_ff @(posedge clk) begin 
	 if(enable) begin
	    z_re_c0_24 <= ((WIDTH_24)'(re_c0 + im_s0)) <<< 16;
	    z_re_c1_24 <= ((WIDTH_24)'(re_c1 + im_s1)) <<< 8;
	    z_re_c2_24 <= (WIDTH_24)'(re_c2 + im_s2);
	    
	    z_im_c0_24 <= ((WIDTH_24)'(im_c0 - re_s0)) <<< 16;
	    z_im_c1_24 <= ((WIDTH_24)'(im_c1 - re_s1)) <<< 8;
	    z_im_c2_24 <= (WIDTH_24)'(im_c2 - re_s2);
	 end
      end // always_ff @ (posedge clk)
      
      
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
	   end // if (enable)
	end // always_ff @ (posedge clk)
      

      always_ff @(posedge clk) begin
        if(enable) begin
	       z_re <= z_re_24_conv[(WIDTH_24-1):(WIDTH_24-DATA_WIDTH)];
	       z_im <= z_im_24_conv[(WIDTH_24-1):(WIDTH_24-DATA_WIDTH)];
        end
      end   

      always  @(posedge clk) begin
//	 $display("[%0t] Time  butterfly4 = (%0d, %0d), (%0d, %0d), (%0d, %0d)", $time,  real_in0, imag_in0, z_re_c0_24, z_im_c0_24, z_re_24_conv ,  z_im_24_conv );
      end
          
      always_ff @(posedge clk) begin 
	 if(enable) begin
	    real_out0  <=  add_re[DEPTH-1] + z_re;
	    real_out1  <=  add_re[DEPTH-1] - z_re;
	    
	    if (TWIDDLE_SEL == 2'b00 || TWIDDLE_SEL == 2'b01  ) begin
	       imag_out0  <=  add_im[DEPTH-1] + z_im;
	       imag_out1  <=  add_im[DEPTH-1] - z_im;
	    end else begin
	       imag_out0  <= add_im[DEPTH-1] - z_im;
	       imag_out1  <= add_im[DEPTH-1] + z_im;
	    end
	 end
      end // always_ff @ (posedge clk)
   end // block: twiddle_24bits
   

   
   if (TWIDDLE_WIDTH > 24) begin : twiddle_32bits
      always_ff @(posedge clk) begin 
	 if(enable) begin
	    z_re_c0_32 <= (WIDTH_16)'(re_c0 + im_s0) <<< 8;
	    z_re_c1_32 <= (WIDTH_16)'(re_c1 + im_s1);
	    
	    z_re_c2_32 <= (WIDTH_16)'(re_c2 + im_s2) <<< 8;
	    z_re_c3_32 <= (WIDTH_16)'(re_c3 + im_s3);
	    
	    z_im_c0_32 <= (WIDTH_16)'(im_c0 - re_s0) <<< 8;
	    z_im_c1_32 <= (WIDTH_16)'(im_c1 - re_s1);
	    
	    z_im_c2_32 <= (WIDTH_16)'(im_c2 - re_s2) <<< 8;
	    z_im_c3_32 <= (WIDTH_16)'(im_c3 - re_s3);
	 end // if (enable)
      end // always_ff @ (posedge clk)
      
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
	 end // if (enable)
    end // always_ff @ (posedge clk)
      

    always_ff @(posedge clk) begin
	  if (enable) begin
	    z_re  <=  z_re_32_conv[(WIDTH_32-1):(WIDTH_32-DATA_WIDTH)];
	    z_im  <=  z_im_32_conv[(WIDTH_32-1):(WIDTH_32-DATA_WIDTH)];
      end
    end
      
      always_ff @(posedge clk) begin 
	 if(enable) begin
	    real_out0  <=  add_re[DEPTH-1] + z_re;
	    real_out1  <=  add_re[DEPTH-1] - z_re ;
	    
	    if (TWIDDLE_SEL == 2'b00 || TWIDDLE_SEL == 2'b01  ) begin
	       imag_out0  <=  add_im[DEPTH-1] + z_im;
	       imag_out1  <=  add_im[DEPTH-1] - z_im;
	    end else begin
	       imag_out0  <= add_im[DEPTH-1] - z_im;
	       imag_out1  <= add_im[DEPTH-1] + z_im;
	    end
	 end // if (enable)
      end // always_ff @ (posedge clk)
   end // block: twiddle_32bits
   
endmodule 




 
 
