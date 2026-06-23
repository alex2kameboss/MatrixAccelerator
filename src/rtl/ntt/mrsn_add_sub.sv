
// mode = 0 for addition sum_o = a_i + b_i and 
// mode = 1 for subtraction sum_o = a_i - b_i

module mrsn_add_sub #(
    parameter N = 17
) (
    input logic clk_i,

    input logic rst_ni,

    input logic mode,

    input logic [N-1:0] a_i,

    input logic [N-1:0] b_i,

    output logic [N-1:0] sum_o
);



  localparam N_FAST_CARRY = (N + 1) / 2;

  logic [N_FAST_CARRY-1:0] carry0;

  logic [N_FAST_CARRY-1:0] prop0;

  logic [N_FAST_CARRY-1:0] gen0;

  logic [N:0] carry1;

  logic [N-1:0] prop1;

  logic [N-1:0] gen1;

  logic [N-1:0] sum, sum_q;

  assign sum_o = sum_q;

  assign carry1[0] = carry0[N_FAST_CARRY-1];


  generate
    for (genvar i = 0; i < N_FAST_CARRY; i = i + 1) begin : calculate_carry
      if (i == 0) begin : first_bit
        LUT6_2 #(
            .INIT(64'hF00F0FF00F00F000)
        ) lutC (
            .I0(1'b0),
            .I1(1'b0),
            .I2(mode),
            .I3(a_i[0]),
            .I4(b_i[0]),
            .I5(1'b1),
            .O5(gen0[0]),
            .O6(prop0[0])
        );
        MUXCY muxc00 (
            .DI(gen0[0]),
            .CI(1'b1),
            .S (prop0[0]),
            .O (carry0[0])
        );
      end else begin : subsequent_bit_pairs
        LUT6_2 #(
            .INIT(64'h8124184254D0E0A8)
        ) lutA (
            .I0(mode),
            .I1(a_i[2*i-1]),
            .I2(a_i[2*i]),
            .I3(b_i[2*i-1]),
            .I4(b_i[2*i]),
            .I5(1'b1),
            .O5(gen0[i]),
            .O6(prop0[i])
        );

        MUXCY muxc0 (
            .DI(gen0[i]),
            .CI(carry0[i-1]),
            .S (prop0[i]),
            .O (carry0[i])
        );
      end  // block: subsequent_bit_pairs
    end  // block: calculate_carry
  endgenerate

  generate
    for (genvar i = 0; i < N; i = i + 1) begin : calculate_sum
      LUT6_2 #(
          .INIT(64'hF00F0FF00F00F000)
      ) lutC (
          .I0(1'b0),
          .I1(1'b0),
          .I2(mode),
          .I3(a_i[i]),
          .I4(b_i[i]),
          .I5(1'b1),
          .O5(gen1[i]),
          .O6(prop1[i])
      );

      MUXCY muxc1 (
          .DI(gen1[i]),
          .CI(carry1[i]),
          .S (prop1[i]),
          .O (carry1[i+1])
      );
      XORCY xorc1 (
          .LI(prop1[i]),
          .CI(carry1[i]),
          .O (sum[i])
      );
    end  // block: calculate_sum

  endgenerate


  always_ff @(posedge clk_i or negedge rst_ni) begin : register_output
    if (~rst_ni) begin
      sum_q <= '0;
    end else begin
      sum_q <= sum;
    end
  end


endmodule

