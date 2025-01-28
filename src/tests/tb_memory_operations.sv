`include "axi/assign.svh"
`include "axi/typedef.svh"
import ma_pkg::*;

module tb_memory_operations();

localparam PRF_LOG_P    =   1   ;
localparam PRF_LOG_Q    =   2   ;
localparam PRF_LOG_N    =   10  ;
localparam PRF_LOG_M    =   10  ;

localparam ADDR_WIDTH   = 32'd32;
localparam DATA_WIDTH   = 32'd32 * 2 ** (PRF_LOG_P + PRF_LOG_Q);
localparam DATA_BYTES   = DATA_WIDTH / 8;

localparam int unsigned TbAxiIdWidth        = 32'd5;
localparam int unsigned TbAxiDataWidth      = DATA_WIDTH;
localparam int unsigned TbAxiAddrWidth      = 32'd32;
localparam int unsigned TbAxiStrbWidth      = TbAxiDataWidth / 8;
localparam int unsigned TbAxiUserWidth      = 5;
localparam              NUMBER_OF_REGISTERS = 32;
typedef logic [$clog2(NUMBER_OF_REGISTERS) - 1 : 0] register;

logic clk, rst_n;

// dut controll signals
logic                                       valid     ;
logic                                       ready     ;
logic                                       arth_data ;
logic                                       define    ;
logic                                       define_prf;
logic                                       ld_st     ;
logic               [ADDR_WIDTH - 1 : 0]    dut_addr  ;
operation_t                                 op        ;
logic                                       scalar_op ;
logic               [ADDR_WIDTH - 1 : 0]    scalar    ;
logic               [4 : 0]                 rd        ;
logic               [4 : 0]                 rs1       ;
logic               [4 : 0]                 rs2       ;
logic               [ADDR_WIDTH - 1 : 0]    width     ;
logic               [ADDR_WIDTH - 1 : 0]    height    ;
logic               [6 : 0]                 dType     ;
logic                                       error     ;
logic [2 : 0]                               funct3    ;

localparam MEM_SIZE = 1024 * 1024; // 1 MB

function void init_mem();
  int i;
  for (i = 0; i < MEM_SIZE / 2; i = i + 1)
    i_sim_mem.i_sim_mem.mem[i] = i[7:0];
endfunction

AXI_BUS #(
  .AXI_ADDR_WIDTH ( TbAxiAddrWidth      ),
  .AXI_DATA_WIDTH ( TbAxiDataWidth      ),
  .AXI_ID_WIDTH   ( TbAxiIdWidth        ),
  .AXI_USER_WIDTH ( TbAxiUserWidth      )
) axi ();

axi_sim_mem_intf #(
  .AXI_ADDR_WIDTH      ( ADDR_WIDTH     ),
  .AXI_DATA_WIDTH      ( DATA_WIDTH     ),
  .AXI_ID_WIDTH        ( TbAxiIdWidth   ),
  .AXI_USER_WIDTH      ( TbAxiUserWidth ),
  .WARN_UNINITIALIZED  ( 1'b0           ),
  .APPL_DELAY          ( 2ns            ),
  .ACQ_DELAY           ( 8ns            )
) i_sim_mem (
  .clk_i             (clk     ),
  .rst_ni            (rst_n   ),
  .axi_slv           (axi     ),
  .mon_w_valid_o     (        ),
  .mon_w_addr_o      (        ),
  .mon_w_data_o      (        ),
  .mon_w_id_o        (        ),
  .mon_w_user_o      (        ),
  .mon_w_beat_count_o(        ),
  .mon_w_last_o      (        ),
  .mon_r_valid_o     (        ),
  .mon_r_addr_o      (        ),
  .mon_r_data_o      (        ),
  .mon_r_id_o        (        ),
  .mon_r_user_o      (        ),
  .mon_r_beat_count_o(        ),
  .mon_r_last_o      (        )
);

instr_decoder i_op_decoder (
  .funct3     ( funct3    ),
  .arth_data  ( arth_data ),
  .define     ( define    ),
  .define_prf ( define_prf),
  .ld_st      ( ld_st     ),
  .scalar_op  ( scalar_op ),
  .error      ( error     ) 
);

ma_data_path #(
  .ADDR_WIDTH         ( ADDR_WIDTH          ),
  .REGISTER_NUMBERS   ( NUMBER_OF_REGISTERS ),
  .PRF_LOG_P          ( PRF_LOG_P           ),
  .PRF_LOG_Q          ( PRF_LOG_Q           ),
  .PRF_LOG_N          ( PRF_LOG_N           ),
  .PRF_LOG_M          ( PRF_LOG_M           ) 
) i_dut (
  .aclk       ( clk       ),
  .arst_n     ( rst_n     ),
  .axi        ( axi       ),
  .clk        ( clk       ),
  .rst_n      ( rst_n     ),
  .valid      ( valid     ),
  .ready      ( ready     ),
  .arth_data  ( arth_data ),
  .define     ( define    ),
  .prf_define ( define_prf),
  .ld_st      ( ld_st     ),
  .addr       ( dut_addr  ),
  .op         ( op        ),
  .scalar_op  ( scalar_op ),
  .scalar     ( scalar    ),
  .rd         ( rd        ),
  .rs1        ( rs1       ),
  .rs2        ( rs2       ),
  .width      ( width     ),
  .height     ( height    ),
  .dtype      ( dType     )               
);

localparam MEMORY_SIZE      = 1024 * 1024 * 8; // 1MB
localparam MEMORY_DEPTH     = MEMORY_SIZE / DATA_WIDTH;

clk_rstn i_clk_gen (.clk, .rst_n);

task define_register;
  input register r;
  input int w;
  input int h;
  input dtype_t dt;
begin
  $display("Define new register ( registerId: %d, width: %d, height: %d, dtype: %s )", r, w, h, dt);
  rd <= r;
  width <= w;
  height <= h;
  dType <= dt;
  funct3 <= DEFINE;

  @(posedge clk)
  valid <= 1'b1;
  @(posedge clk)
  while (ready != 1'b1) @(posedge clk);
  valid <= 1'b0;

  // wait the controller to be available again
  @(posedge clk)
  while (ready != 1'b1) @(posedge clk);

  // check register in RFT
  assert(i_dut.i_ccu.rft[r].width == w);
  assert(i_dut.i_ccu.rft[r].height == h);
  assert(i_dut.i_ccu.rft[r].dtype == dt);
  assert(i_dut.i_ccu.rft[r].valid);
  assert(~i_dut.i_ccu.rft[r].prf_valid);
  assert(~i_dut.i_ccu.rft[r].in_mem);
end
endtask

task define_prf_register;
  input register r;
  input int prf_x;
  input int prf_y;
  input organization_t dt;
begin
  $display("Define prf register ( registerId: %d, prf_x: %d, prf_y: %d, organization: %s )", r, prf_x, prf_y, dt);
  assert(i_dut.i_ccu.rft[r].valid);

  rd <= r;
  width <= prf_x;
  height <= prf_y;
  dType <= dt;
  funct3 <= DEFINE_POLY;

  @(posedge clk)
  valid <= 1'b1;
  @(posedge clk)
  while (ready != 1'b1) @(posedge clk);
  valid <= 1'b0;

  // wait the controller to be available again
  @(posedge clk)
  while (ready != 1'b1) @(posedge clk);

  // check register in RFT
  assert(i_dut.i_ccu.rft[r].prf_x == prf_x);
  assert(i_dut.i_ccu.rft[r].prf_y == prf_y);
  assert(i_dut.i_ccu.rft[r].prf_org == dt);
  assert(i_dut.i_ccu.rft[r].prf_valid);
  assert(~i_dut.i_ccu.rft[r].in_mem);
end
endtask

task define_register_one_step;
  input register r;
  input int w;
  input int h;
  input dtype_t dt;
  input int prf_x;
  input int prf_y;
  input organization_t org;
begin

  define_register(r, w, h, dt);
  define_prf_register(r, prf_x, prf_y, org);

end
endtask

task load_register;
  input register r;
  input int addr;
begin
  $display("Load register ( registerId: %d, addr: %h )", r, addr);
  assert(i_dut.i_ccu.rft[r].valid);
  assert(i_dut.i_ccu.rft[r].prf_valid);

  //int bytes, i, j;
  //bit pass;
  //logic [7 : 0] line [DATA_BYTES - 1 : 0];


  // load data
  rd <= r;
  funct3 <= LOAD;
  dut_addr <= addr;

  @(posedge clk)
  valid <= 1'b1;
  @(posedge clk)
  while (ready != 1'b1) @(posedge clk);
  valid <= 1'b0;

  // wait the controller to be available again
  @(posedge clk)
  while (ready != 1'b1) @(posedge clk);

  /*
  // check data in regfile
  bytes = i_dut.i_ccu.rft[r].width * i_dut.i_ccu.rft[r].height;

  if ( i_dut.i_ccu.rft[r].dtype == INT16 | i_dut.i_ccu.rft[r].dtype == UINT16 )
    bytes = bytes * 2;
  else if ( i_dut.i_ccu.rft[r].dtype == INT32 | i_dut.i_ccu.rft[r].dtype == UINT32 )
    bytes = bytes * 4;

  pass = 1'b1;
  for ( i = 0; i < bytes; i = i + DATA_BYTES ) begin
    for ( j = 0; j < DATA_BYTES; j = j + 1 ) begin
      line[j] = i_sim_mem.i_sim_mem.mem[addr + i + j];
    end
    //pass = pass & (buffers_clone[r][i / DATA_BYTES] == { >> {line}});
  end
  assert(pass);
  */
  assert(i_dut.i_ccu.rft[r].in_mem);
end
endtask

task vector_vector_operation;
  input register    rr;
  input register    r1;
  input register    r2;
  input operation_t o ;
begin
  int bytes, i, j;
  bit pass;

  $display("Vector-Vector operation ( rd: %d, r1: %d, r2: %d, operation: %s )", rr, r1, r2, o);

  // check registers
  assert(i_dut.i_ccu.rft[rr].valid);
  assert(i_dut.i_ccu.rft[r1].valid);
  assert(i_dut.i_ccu.rft[r2].valid);
  assert(i_dut.i_ccu.rft[r1].in_mem);
  assert(i_dut.i_ccu.rft[r2].in_mem);
  assert(i_dut.i_ccu.rft[r1].width == i_dut.i_ccu.rft[r2].width &
          i_dut.i_ccu.rft[r1].height == i_dut.i_ccu.rft[r2].height &
          i_dut.i_ccu.rft[r1].dtype == i_dut.i_ccu.rft[r2].dtype)
  assert(i_dut.i_ccu.rft[rr].width == i_dut.i_ccu.rft[r2].width &
          i_dut.i_ccu.rft[rr].height == i_dut.i_ccu.rft[r2].height &
          i_dut.i_ccu.rft[rr].dtype == i_dut.i_ccu.rft[r2].dtype)

  // configure operation
  funct3 <= VV;
  rs1 <= r1;
  rs2 <= r2;
  rd <= rr;
  op <= o;

  // send operation
  @(posedge clk)
  valid <= 1'b1;
  @(posedge clk)
  while (ready != 1'b1) @(posedge clk);
  valid <= 1'b0;

  // wait the controller to be available again
  @(posedge clk)
  while (ready != 1'b1) @(posedge clk);

  // check result
  bytes = i_dut.i_ccu.rft[rr].width * i_dut.i_ccu.rft[rr].height;

  if ( i_dut.i_ccu.rft[rr].dtype == INT16 | i_dut.i_ccu.rft[rr].dtype == UINT16 )
    bytes = bytes * 2;
  else if ( i_dut.i_ccu.rft[rr].dtype == INT32 | i_dut.i_ccu.rft[rr].dtype == UINT32 )
    bytes = bytes * 4;

  /*
  pass = 1'b1;
  for ( i = 0; i < bytes; i = i + DATA_BYTES ) begin
    if ( i_dut.i_ccu.rft[rr].dtype == INT32 | i_dut.i_ccu.rft[rr].dtype == UINT32 ) 
      for ( j = 0; j < DATA_BYTES / 4; j = j + 1 )
        //pass = pass & (buffers_clone[rr][i / DATA_BYTES][ (j + 1) * 32  - 1 -: 32 ] == alu(buffers_clone[r1][i / DATA_BYTES][ (j + 1) * 32 - 1 -: 32 ], buffers_clone[r2][i / DATA_BYTES][ (j + 1) * 32 - 1 -: 32 ], o));
    else if ( i_dut.i_ccu.rft[rr].dtype == INT16 | i_dut.i_ccu.rft[rr].dtype == UINT16 ) 
      for ( j = 0; j < DATA_BYTES / 2; j = j + 1 )
        //pass = pass & (buffers_clone[rr][i / DATA_BYTES][ (j + 1) * 16 - 1 -: 16 ] == alu(buffers_clone[r1][i / DATA_BYTES][ (j + 1) * 16 - 1 -: 16 ], buffers_clone[r2][i / DATA_BYTES][ (j + 1) * 16 - 1 -: 16 ], o)[15 : 0]);
    else if ( i_dut.i_ccu.rft[rr].dtype == INT8 | i_dut.i_ccu.rft[rr].dtype == UINT8 ) 
      for ( j = 0; j < DATA_BYTES; j = j + 1 )
        //pass = pass & (buffers_clone[rr][i / DATA_BYTES][ (j + 1) * 8 - 1 -: 8 ] == alu(buffers_clone[r1][i / DATA_BYTES][ (j + 1) * 8 - 1 -: 8 ], buffers_clone[r2][i / DATA_BYTES][ (j + 1) * 8 - 1 -: 8 ], o)[7 : 0]);
  end
  assert(pass);
  */
  assert(i_dut.i_ccu.rft[rr].in_mem);
end
endtask

function int alu (int x, y, operation_t o);
  case (o)
    ADD     : alu = x + y;
    SUB     : alu = x - y;
    DIV     : alu = x / y;
    default : alu = x * y;
  endcase
endfunction

task store_register;
  input register r;
  input int addr;
begin
  //int bytes, i, j;
  //bit pass;
  //logic [7 : 0] line [DATA_BYTES - 1 : 0];

  $display("Store register ( registerId: %d, addr: %h )", r, addr);

  assert(i_dut.i_ccu.rft[r].valid);
  assert(i_dut.i_ccu.rft[r].in_mem);

  // load data
  rd <= r;
  funct3 <= STORE;
  dut_addr <= addr;

  @(posedge clk)
  valid <= 1'b1;
  @(posedge clk)
  while (ready != 1'b1) @(posedge clk);
  valid <= 1'b0;

  // wait the controller to be available again
  @(posedge clk)
  while (ready != 1'b1) @(posedge clk);

  /*
  // check data in regfile
  bytes = i_dut.i_ccu.rft[r].width * i_dut.i_ccu.rft[r].width;

  if ( i_dut.i_ccu.rft[r].dtype == INT16 | i_dut.i_ccu.rft[r].dtype == UINT16 )
    bytes = bytes * 2;
  else if ( i_dut.i_ccu.rft[r].dtype == INT32 | i_dut.i_ccu.rft[r].dtype == UINT32 )
    bytes = bytes * 4;

  pass = 1'b1;
  for ( i = 0; i < bytes; i = i + DATA_BYTES ) begin
    for ( j = 0; j < DATA_BYTES; j = j + 1 ) begin
      line[j] = i_sim_mem.i_sim_mem.mem[addr + i + j];
    end
    //pass = pass & (buffers_clone[r][i / DATA_BYTES] == { >> {line}});
  end
  assert(pass);
  */
end
endtask

task vector_scalar_operation;
  input register rr;
  input register r1;
  input int r2;
  input operation_t o;
begin
  int bytes, i, j;
  bit pass;

  $display("Vector-Scalar operation ( rd: %d, r1: %d, r2: %d, operation: %s )", rr, r1, r2, o);

  // check registers
  assert(i_dut.i_ccu.rft[rr].valid);
  assert(i_dut.i_ccu.rft[r1].valid);
  assert(i_dut.i_ccu.rft[r1].in_mem);
  assert(i_dut.i_ccu.rft[rr].width == i_dut.i_ccu.rft[r1].width &
          i_dut.i_ccu.rft[rr].height == i_dut.i_ccu.rft[r1].height &
          i_dut.i_ccu.rft[rr].dtype == i_dut.i_ccu.rft[r1].dtype)

  // configure operation
  funct3 <= VS;
  rs1 <= r1;
  rs2 <= r2;
  rd <= rr;
  op <= o;
  scalar <= r2;

  // send operation
  @(posedge clk)
  valid <= 1'b1;
  @(posedge clk)
  while (ready != 1'b1) @(posedge clk);
  valid <= 1'b0;

  // wait the controller to be available again
  @(posedge clk)
  while (ready != 1'b1) @(posedge clk);

  // check result
  bytes = i_dut.i_ccu.rft[rr].width * i_dut.i_ccu.rft[rr].height;

  if ( i_dut.i_ccu.rft[rr].dtype == INT16 | i_dut.i_ccu.rft[rr].dtype == UINT16 )
    bytes = bytes * 2;
  else if ( i_dut.i_ccu.rft[rr].dtype == INT32 | i_dut.i_ccu.rft[rr].dtype == UINT32 )
    bytes = bytes * 4;

  /*
  pass = 1'b1;
  for ( i = 0; i < bytes; i = i + DATA_BYTES ) begin
    if ( i_dut.i_ccu.rft[rr].dtype == INT32 | i_dut.i_ccu.rft[rr].dtype == UINT32 ) 
      for ( j = 0; j < DATA_BYTES / 4; j = j + 1 )
        //pass = pass & (buffers_clone[rr][i / DATA_BYTES][ (j + 1) * 32  - 1 -: 32 ] == alu(buffers_clone[r1][i / DATA_BYTES][ (j + 1) * 32 - 1 -: 32 ], r2, o));
    else if ( i_dut.i_ccu.rft[rr].dtype == INT16 | i_dut.i_ccu.rft[rr].dtype == UINT16 ) 
      for ( j = 0; j < DATA_BYTES / 2; j = j + 1 )
        //pass = pass & (buffers_clone[rr][i / DATA_BYTES][ (j + 1) * 16 - 1 -: 16 ] == alu(buffers_clone[r1][i / DATA_BYTES][ (j + 1) * 16 - 1 -: 16 ], r2[15 : 0], o)[15 : 0]);
    else if ( i_dut.i_ccu.rft[rr].dtype == INT8 | i_dut.i_ccu.rft[rr].dtype == UINT8 ) 
      for ( j = 0; j < DATA_BYTES; j = j + 1 )
        //pass = pass & (buffers_clone[rr][i / DATA_BYTES][ (j + 1) * 8 - 1 -: 8 ] == alu(buffers_clone[r1][i / DATA_BYTES][ (j + 1) * 8 - 1 -: 8 ], r2[7 : 0], o)[7 : 0]);
  end
  assert(pass);
  */
  assert(i_dut.i_ccu.rft[rr].in_mem);
end
endtask

task load_store_test;
  input register r;
  input int w;
  input int h;
  input int prf_x;
  input int prf_y;
  input dtype_t dt;
  input int addr;
begin
  int i;
  $display("Load store test");
  define_register_one_step(
    .r    ( r     ),
    .w    ( w     ),
    .h    ( h     ),
    .dt   ( dt    ),
    .prf_x( prf_x ),
    .prf_y( prf_y ),
    .org  ( RECT  )
  );
  load_register(r, addr);
  store_register(r, MEM_SIZE / 2 + addr);

  for ( i = 0; i < w * h; i = i + 1) begin
    assert(i_sim_mem.i_sim_mem.mem[addr + i] == i_sim_mem.i_sim_mem.mem[MEM_SIZE / 2 + addr + i]);
    i_sim_mem.i_sim_mem.mem[MEM_SIZE / 2 + addr + i] = 'dx;
  end
  $display("------------------------------------------------------");
end
endtask

/*
task vector_vector_operation_test;
  input register rr;
  input register r1;
  input register r2;
  input operation_t o;
  input dtype_t dt;
  input int w;
  input int h;
  input int rr_addr;
  input int r1_addr;
  input int r2_addr;
begin
  $display("Vector-Vector operation test");
  define_register(rr, w, h, dt);
  define_register(r1, w, h, dt);
  define_register(r2, w, h, dt);
  load_register(r1, r1_addr);
  load_register(r2, r2_addr);
  vector_vector_operation(rr, r1, r2, o);
  store_register(rr, rr_addr);
  $display("------------------------------------------------------");
end
endtask

task vector_scalar_operation_test;
  input register rr;
  input register r1;
  input int r2;
  input operation_t o;
  input dtype_t dt;
  input int w;
  input int h;
  input int rr_addr;
  input int r1_addr;
begin
  $display("Vector-Scalar operation test");
  define_register(rr, w, h, dt);
  define_register(r1, w, h, dt);
  load_register(r1, r1_addr);
  vector_scalar_operation(rr, r1, r2, o);
  store_register(rr, rr_addr);
  $display("------------------------------------------------------");
end
endtask
*/

initial begin
  // ccu
  valid       <= 'd0;
  dut_addr    <= 'd0;
  op          <= NOP;
  scalar      <= 'd0;
  rd          <= 'd0;
  rs1         <= 'd0;
  rs2         <= 'd0;
  width       <= 'd0;
  height      <= 'd0;
  dType       <= NDT;
  funct3      <= NF3;

  @(negedge rst_n);

  wait(axi.aw_ready);
  @(posedge clk);
  @(posedge clk);

  init_mem();

  //for ( register = 0; register < 32; register = register + 1 )
  //  define_register(16, 16, 'd0, register);

  load_store_test('d0, 32, 32, 0, 0, UINT8, 'h0);
  load_store_test('d0, 16, 16, 0, 0, UINT16, 'h0);
  load_store_test('d0, 8, 8, 0, 0, UINT32, 'h0);

  /*
  vector_vector_operation_test('d2, 'd0, 'd1, SUB, INT8, 8, 8, MEM_SIZE, 'h0, 'h0);
  vector_vector_operation_test('d2, 'd0, 'd1, ADD, INT8, 8, 8, MEM_SIZE, MEM_SIZE, 'h0);

  vector_vector_operation_test('d2, 'd0, 'd1, SUB, INT16, 4, 4, MEM_SIZE, 'h0, 'h0);
  vector_vector_operation_test('d2, 'd0, 'd1, ADD, INT16, 4, 4, MEM_SIZE, MEM_SIZE, 'h0);

  vector_vector_operation_test('d2, 'd0, 'd1, SUB, INT32, 4, 4, MEM_SIZE, 'h0, 'h0);
  vector_vector_operation_test('d2, 'd0, 'd1, ADD, INT32, 4, 4, MEM_SIZE, MEM_SIZE, 'h0);

  vector_scalar_operation_test('d2, 'd0, 'd0, SUB, INT8, 8, 8, MEM_SIZE, 'h0);
  vector_scalar_operation_test('d2, 'd0, 'd0, SUB, INT16, 8, 8, MEM_SIZE, 'h0);
  vector_scalar_operation_test('d2, 'd0, 'd0, SUB, INT32, 8, 8, MEM_SIZE, 'h0);
  */

  @(posedge clk);
  @(posedge clk);

  $stop;
end

endmodule;