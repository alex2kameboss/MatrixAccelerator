module MUXCY
  (
   output O, 
   input  CI, 
   input  DI, 
   input  S
   );
   
   assign O = S ? CI : DI;

endmodule
