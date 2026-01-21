module transpose_16
  #(
    parameter N = 16,
    parameter DATA_WIDTH=16*2,
    parameter [3:0] DELAY=0
    )
   (

    input logic			  clk,
    input logic			  enable, 
    input logic			  rst_n, 
    
    
    input logic [DATA_WIDTH-1:0]  in[0:N-1],
    
    output logic [DATA_WIDTH-1:0] out[0:N-1]
    );
   
    
   logic [0:0]			  c0;
   logic [1:0]			  c1;
   logic [2:0]			  c2;
   logic [3:0]			  c3;

 
   
   logic [DATA_WIDTH-1:0]	  a1[0:N-1];
   logic [DATA_WIDTH-1:0]	  a2[0:N-1];
   logic [DATA_WIDTH-1:0]	  a3[0:N-1];
   
   
   localparam			  NDELAY = 16 - DELAY;
			  
   genvar				 i,j;


   
   always_ff @(posedge clk) begin
      if (!rst_n) begin
	 
	 c0 <= 1'(1'd0 + NDELAY[0]);
	 
	 c1 <= 2'(2'd3 + NDELAY[1:0]);
	 
	 c2 <= 3'(3'd5 + NDELAY[2:0]);
	 
	 c3 <= 4'(4'd9 + NDELAY);
	 
      end
      else begin
	 if (enable) begin
	    c0 <= c0 + 1;	 
	    c1 <= c1 + 1;
	    c2 <= c2 + 1;
	    c3 <= c3 + 1;

	    
	 end
      end // else: !if(!rst_n)
   end
           

   generate
      for (i = 0; i < 8; i = i + 1) begin : stage1
	  delay_commutator
	       #(
		 .L(1),
		 .DATA_WIDTH(DATA_WIDTH)
	       )
	  delay_commutator1 
	       (
     		.clk    (clk),
		.enable(enable),
		.sel    (c0[0]),
		.a_in   (in[2*i]),
		.b_in   (in[2*i+1]),
		.a_out  (a1[2*i]),
		.b_out  (a1[2*i+1])
		);
       end // block: stage1
    endgenerate


   generate
       for (i = 0; i < 4; i = i + 1) begin : stage2
	  for (j = 0; j < 2; j = j + 1) begin 
	     delay_commutator
		   #(
		     .L(2),
		     .DATA_WIDTH(DATA_WIDTH)
		     )
	     delay_commutator2 
		   (
     		    .clk    (clk),
		    .enable(enable),
		    .sel    (c1[1]),
		    .a_in   (a1[4*i+j]),
		    .b_in   (a1[4*i+j+2]),
		    .a_out  (a2[4*i+j]),
		    .b_out  (a2[4*i+j+2])
		    );
	  end
       end // block: stage2
   endgenerate

   generate
      for (i = 0; i < 2; i = i + 1) begin : stage3
	 for (j = 0; j < 4; j = j + 1) begin 
	    delay_commutator
		  #(
		    .L(4),
		    .DATA_WIDTH(DATA_WIDTH)
		    )
	    delay_commutator4 
		  (
     		   .clk    (clk),
		   .enable(enable),
		   .sel    (c2[2]),
		   .a_in   (a2[8*i+j]),
		   .b_in   (a2[8*i+j+4]),
		   .a_out  (a3[8*i+j]),
		   .b_out  (a3[8*i+j+4])
		   );
	 end
      end // block: stage3
   endgenerate



   generate
      for (j = 0; j < 8; j = j + 1) begin : stage4
	 delay_commutator 
	       #(
		 .L(8),
		 .DATA_WIDTH(DATA_WIDTH)
		 )
	 delay_commutator8
	       (
     		.clk    (clk),
		.enable(enable),
		.sel    (c3[3]),
		.a_in   (a3[j]),
		.b_in   (a3[j+8]),
		.a_out  (out[j]),
		.b_out  (out[j+8])
		);
      end // block: stage4
   endgenerate
   


endmodule
   
