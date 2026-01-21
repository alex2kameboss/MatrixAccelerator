module butterfly_type2 
  #(
    parameter DATA_WIDTH = 16
    )(
      input logic			   clk,
      input logic			   enable,
      
      input logic signed [DATA_WIDTH-1:0]  real_in0,
      input logic signed [DATA_WIDTH-1:0]  imag_in0,
      input logic signed [DATA_WIDTH-1:0]  real_in1, 
      input logic signed [DATA_WIDTH-1:0]  imag_in1,

      output logic signed [DATA_WIDTH+1-1:0] real_out0,
      output logic signed [DATA_WIDTH+1-1:0] imag_out0,
      output logic signed [DATA_WIDTH+1-1:0] real_out1,
      output logic signed [DATA_WIDTH+1-1:0] imag_out1
);

   always_ff @(posedge clk) begin
      if (enable) begin
         real_out0 <=  real_in0 + imag_in1;
         imag_out0 <=  imag_in0 - real_in1;
         real_out1 <=  real_in0 - imag_in1;
         imag_out1 <=  imag_in0 + real_in1;
      end
   end
   
endmodule
