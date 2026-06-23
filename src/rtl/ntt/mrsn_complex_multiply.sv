// Multiplication of two complex numbers modulo Mersenne primes 2^13-1 and 2^17-1 (or 2^13-1 and 2^19-1) 
// so that they can be packed in 32bits 

module mrsn_complex_multiply #(
    parameter WIDTH = 32,
    parameter W0 = 13,
    parameter W1 = 17
) (
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             en_i,
    input  logic             reset_i,
    input  logic [WIDTH-1:0] a_re_i,
    input  logic [WIDTH-1:0] a_im_i,
    input  logic [WIDTH-1:0] b_re_i,
    input  logic [WIDTH-1:0] b_im_i,
    output logic [WIDTH-1:0] z_re_o,
    output logic [WIDTH-1:0] z_im_o

);

  localparam W_NOTUSED = WIDTH - W0 - W1;

  logic [WIDTH-1:0] a_re_q, a_im_q, b_re_q, b_im_q;

  logic [W0-1:0] c0, s0, x0, y0;
  logic [W1-1:0] c1, s1, x1, y1;

  logic [2*W0-1:0] prod0_xc, prod0_xs, prod0_yc, prod0_ys, notprod0_ys;

  logic [W0+3-1:0] prod0_x, prod0_y;

  logic [W0-1:0] prod0_mod_x, prod0_mod_y;

  logic [2*W1-1:0] prod1_xc, prod1_xs, prod1_yc, prod1_ys, notprod1_ys;

  logic [W1+3-1:0] prod1_x, prod1_y;

  logic [W1-1:0] prod1_mod_x, prod1_mod_y;

  logic [WIDTH-1:0] z_re;
  logic [WIDTH-1:0] z_im;


  assign z_re_o = z_re;
  assign z_im_o = z_im;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      a_re_q <= '0;
      a_im_q <= '0;
      b_re_q <= '0;
      b_im_q <= '0;
    end else if ( en_i ) begin
      if ( reset_i ) begin
        a_re_q <= '0;
        a_im_q <= '0;
        b_re_q <= '0;
        b_im_q <= '0;
      end else begin
        a_re_q <= a_re_i;
        a_im_q <= a_im_i;
        b_re_q <= b_re_i;
        b_im_q <= b_im_i;
      end
    end
  end


  assign x0 = a_re_q[W0-1 : 0];
  assign x1 = a_re_q[W0+W1-1 : W0];

  assign y0 = a_im_q[W0-1 : 0];
  assign y1 = a_im_q[W0+W1-1 : W0];

  assign c0 = b_re_q[W0-1 : 0];
  assign c1 = b_re_q[W0+W1-1 : W0];

  assign s0 = b_im_q[W0-1 : 0];
  assign s1 = b_im_q[W0+W1-1 : W0];

  always_ff @(posedge clk_i) 
    if ( en_i ) begin
      prod0_xc <= x0 * c0;
      prod0_xs <= x0 * s0;
      prod0_yc <= y0 * c0;
      prod0_ys <= y0 * s0;
      prod1_xc <= x1 * c1;
      prod1_xs <= x1 * s1;
      prod1_yc <= y1 * c1;
      prod1_ys <= y1 * s1;
    end

  assign notprod0_ys = ~prod0_ys;

  assign notprod1_ys = ~prod1_ys;


  always_ff @(posedge clk_i) 
    if ( en_i ) begin
      prod0_x <= prod0_xc[W0-1:0] + prod0_xc[2*W0-1:W0] + notprod0_ys[W0-1:0] + notprod0_ys[2*W0-1:W0] ;
      prod0_y <= prod0_xs[W0-1:0] + prod0_xs[2*W0-1:W0] + prod0_yc[W0-1:0] + prod0_yc[2*W0-1:W0];
      prod1_x <= prod1_xc[W1-1:0] + prod1_xc[2*W1-1:W1] + notprod1_ys[W1-1:0] + notprod1_ys[2*W1-1:W1] ;
      prod1_y <= prod1_xs[W1-1:0] + prod1_xs[2*W1-1:W1] + prod1_yc[W1-1:0] + prod1_yc[2*W1-1:W1];
    end


  mrsn_add_sub #(
      .N(W0)
  ) adder0_x (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .mode(1'b0),
      .a_i(prod0_x[W0-1:0]),
      .b_i({{W0 - 3{1'b0}}, prod0_x[W0+3-1:W0]}),
      .sum_o(prod0_mod_x)
  );

  mrsn_add_sub #(
      .N(W0)
  ) adder0_y (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .mode(1'b0),
      .a_i(prod0_y[W0-1:0]),
      .b_i({{W0 - 3{1'b0}}, prod0_y[W0+3-1:W0]}),
      .sum_o(prod0_mod_y)
  );

  mrsn_add_sub #(
      .N(W1)
  ) adder1_x (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .mode(1'b0),
      .a_i(prod1_x[W1-1:0]),
      .b_i({{W1 - 3{1'b0}}, prod1_x[W1+3-1:W1]}),
      .sum_o(prod1_mod_x)
  );

  mrsn_add_sub #(
      .N(W1)
  ) adder1_y (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .mode(1'b0),
      .a_i(prod1_y[W1-1:0]),
      .b_i({{W1 - 3{1'b0}}, prod1_y[W1+3-1:W1]}),
      .sum_o(prod1_mod_y)
  );

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      z_re <= '0;
      z_im <= '0;
    end else if ( en_i ) begin
      if ( reset_i ) begin
        z_re <= '0;
        z_im <= '0;
      end else begin
        z_re <= {{W_NOTUSED{1'b0}}, prod1_mod_x, prod0_mod_x};
        z_im <= {{W_NOTUSED{1'b0}}, prod1_mod_y, prod0_mod_y};
      end
    end
  end

endmodule



