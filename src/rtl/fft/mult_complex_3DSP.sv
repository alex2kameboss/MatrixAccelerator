/*
 
  We are assuming here that norm(zr + zi*j) < = sqrt(zr^2+zi^2) <= 2^(DATA_WIDTH-1).
 
 Then also norm(Zr + Zi*j) < 2^(DATA_WIDTH-1) so that both Zr and Zi
 are signed with DATA_WIDTH bits.
 
 c+js represents a root of unity calculated with:
 c+js = round(exp(-2*j*pi*k/N)*2^(TWIDDLE_WIDTH-1)) for various k,N. 
 
 After multiplication we need to scale back with 2^(TWIDDLE_WIDTH-1)
 
 Compared to complex multiplication with 4DSP, here we need to do the
real multiplications with 1 more bit due to sums c+s, c-s, zr+zi 
 
 */
//TODO: Use Xilinx DSP capabilities for doing an add before or after the multiplication

//Efficient Implementation of Complex Multipliers on FPGAs Using DSP Slices, Pedro Paz · Mario Garrido.


module mult_complex_3DSP
  #(
    parameter DATA_WIDTH = 24,
    parameter TWIDDLE_WIDTH = 17
    )
   (
    input logic				    clk,
    input logic				    enable,
    input logic signed [DATA_WIDTH-1:0]	    zr,
    input logic signed [DATA_WIDTH-1:0]	    zi,
    input logic signed [TWIDDLE_WIDTH -1:0] c,
    input logic signed [TWIDDLE_WIDTH -1:0] s,
    output logic signed [DATA_WIDTH-1:0]    Zr,
    output logic signed [DATA_WIDTH-1:0]    Zi
    );

   
   localparam				    WIDTH_TS = DATA_WIDTH + TWIDDLE_WIDTH - 1;
   
   localparam				    WIDTH_OUT = DATA_WIDTH ;
   
   logic signed [TWIDDLE_WIDTH + 1 - 1:0]   cps, cms;
   logic signed [DATA_WIDTH + 1 - 1:0]	    rpi;
   
   logic signed [DATA_WIDTH - 1:0]	    zr2,zi2;
   
   logic signed [TWIDDLE_WIDTH - 1:0]	    s2;
   
   //Multiplication of signed D'bits with signed T+1'bits gives signed (D+T)'bits
   //Multiplication of signed D+1'bits with signed T'bits gives signed (D+T)'bits
   
   logic signed [DATA_WIDTH + TWIDDLE_WIDTH - 1:0] t1, t2, t3, t1_p, t2_p, t3_p;
   
   //The sum of 2 signed (D+T)'bits gives (D+T+1)'bits. However, our
   //assumption that norm(input) is < D'bits assures a result of only
   //(D+T-1)'bits
   
   logic signed [DATA_WIDTH + TWIDDLE_WIDTH - 1 - 1:0] re, im;
   
   

   logic signed [DATA_WIDTH + TWIDDLE_WIDTH - 1 - 1:0] re_conv, im_conv;
   
   
   always_ff @(posedge clk) begin
      if (enable) begin
	 //TWIDDLE_WIDTH + 1 signed
	 cps <= c + s;
	 cms <= c - s;
	 
	 //DATA_WIDTH + 1 signed
	 rpi <= zr + zi;
	 
	 s2  <= s;
	 
	 zr2 <= zr;
	 
	 zi2 <= zi;
      end // if (enable)
   end

   always_ff @(posedge clk) begin

      if (enable) begin
	 //(signed DATA_WIDTH) * (signed (TWIDDLE_WIDTH + 1))  = signed (DATA_WIDTH + TWIDDLE_WIDTH)
	 //Add a cycle as recommended by xilinx for DSP
	 t1_p <= zr2  * cps;
	 t2_p <= zi2  * cms;
	 t3_p <= s2   * rpi;

	 t1 <= t1_p;
	 t2 <= t2_p;
	 t3 <= t3_p;
      end
   end

   always_ff @(posedge clk) begin
      if (enable) begin
	 //we know that re and im have equivalent expressions zr*c-zi*s, zr*s+zi*c
	 //with maximum bitwidth WIDTH_TS = DATA_WIDTH + TWIDDLE_WIDTH-1
	 re <= WIDTH_TS'(t1 - t3); 
	 im <= WIDTH_TS'(t2 + t3);
      end
   end

   //convergent rounding

   always_ff @(posedge clk) begin
      if (enable) begin
	 re_conv <= (re[(WIDTH_TS-1):0]
		     + { {(WIDTH_OUT){1'b0}},
			 re[(WIDTH_TS-WIDTH_OUT)],
			 {(WIDTH_TS-WIDTH_OUT-1){!re[(WIDTH_TS-WIDTH_OUT)]}}});
	 
	 im_conv <= (im[(WIDTH_TS-1):0]
			+ { {(WIDTH_OUT){1'b0}},
			    im[(WIDTH_TS-WIDTH_OUT)],
			{(WIDTH_TS-WIDTH_OUT-1){!im[(WIDTH_TS-WIDTH_OUT)]}}});
      end // if (enable)
   end // always_ff @ (posedge clk)
   
   always_ff @(posedge clk) begin
      if (enable) begin
	 Zr <= re_conv[(WIDTH_TS-1):(WIDTH_TS-WIDTH_OUT)];
	 Zi <= im_conv[(WIDTH_TS-1):(WIDTH_TS-WIDTH_OUT)];
      end
   end

endmodule
