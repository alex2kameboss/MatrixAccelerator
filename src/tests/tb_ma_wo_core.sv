`include "axi/assign.svh"
`include "axi/typedef.svh"

module tb_ma_wo_core();
import ma_pkg::*;
import riscv_pkg::*;

core_v_xif #(
    .X_NUM_RS              ( 2  ),
    .X_ID_WIDTH            ( 4  ),
    .X_RFR_WIDTH           ( 32 ),
    .X_RFW_WIDTH           ( 32 ),
    .X_NUM_HARTS           ( 1  ),
    .X_HARTID_WIDTH        ( 1  ),
    .X_MISA                ( '0 ),
    .X_DUALREAD            ( 0  ),
    .X_DUALWRITE           ( 0  ),
    .X_ISSUE_REGISTER_SPLIT( 0  ),
    .X_MEM_WIDTH           ( 32 ) 
) xif ();

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
localparam              OPCODE              = 7'h2B;
typedef logic [$clog2(NUMBER_OF_REGISTERS) - 1 : 0] register;

logic clk, rst_n;
int hartId, opId;

assign xif.issue_req.hartid = hartId;
assign xif.issue_req.id = opId;
assign xif.register.hartid = hartId;
assign xif.register.id = opId;
assign xif.commit.hartid = hartId;
assign xif.commit.id = opId;

logic [31 : 0] rf [31 : 0];

localparam MEM_SIZE = 1024 * 1024; // 1 MB

function void init_mem();
  int i, j;
  const int len = 64;
  for ( i = 0; i < len; i = i + 1 )
    for ( j = 0; j < len; j = j + 1 )
        {i_sim_mem.i_sim_mem.mem[(i * len + j) * 4 + 3], i_sim_mem.i_sim_mem.mem[(i * len + j) * 4 + 2], i_sim_mem.i_sim_mem.mem[(i * len + j) * 4 + 1], i_sim_mem.i_sim_mem.mem[(i * len + j) * 4]} = j;
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

matrix_acclerator #(
    .OPCODE             ( OPCODE                ),
    .ADDR_WIDTH         ( ADDR_WIDTH            ),
    .REGISTER_NUMBERS   ( NUMBER_OF_REGISTERS   ),
    .PRF_LOG_P          ( PRF_LOG_P             ),
    .PRF_LOG_Q          ( PRF_LOG_Q             ),
    .PRF_LOG_N          ( PRF_LOG_N             ),
    .PRF_LOG_M          ( PRF_LOG_M             ) 
) i_dut (
    .clk            ( clk   ),
    .rst_n          ( rst_n ),
    .instr_if       ( xif   ),
    .registers_if   ( xif   ),
    .commit_if      ( xif   ),
    .result_if      ( xif   ),
    .aclk           ( clk   ),
    .arst_n         ( rst_n ),
    .axi            ( axi   )
);

int regId = 0;
function int reg_id;
    regId = regId + 1;
    reg_id = regId % 32;
endfunction

clk_rstn i_clk_gen (.clk, .rst_n);

task automatic do_xif;
    input logic [31 : 0]    instr       ;
    input logic             shallPass   ;
    input logic             commit      ;
begin
    riscv_r_t ins = riscv_r_t'(instr);
    int i;
    int rs[1 : 0] = {ins.rs2, ins.rs1};
    // issue interface
    xif.issue_req.instr <= instr;
    @(posedge clk);
    xif.issue_valid <= 1'b1;
    while (xif.issue_ready != 1'b1) @(posedge clk);
    xif.issue_valid <= 1'b0;
    xif.issue_req.instr <= 'd0;

    // check if accepted
    assert(xif.issue_resp.accept == shallPass);

    if ( shallPass ) begin
        // register interface
        xif.register.rs_valid = 'd0;
        for ( i = 0; i < 2; i = i + 1 ) begin
            if ( xif.issue_resp.register_read[i] ) begin
                xif.register.rs[i] = rf[rs[i]];
                xif.register.rs_valid[i] = 1'b1;
            end
        end

        xif.register_valid <= 1'b1;
        @(posedge clk);
        while (xif.register_ready != 1'b1) @(posedge clk);
        xif.register_valid <= 1'b0;

        // commit interface
        xif.commit.commit_kill <= ~commit;
        @(posedge clk);
        xif.commit_valid <= 1'b1;
        @(posedge clk);
        xif.commit_valid <= 1'b0;

        if ( commit ) begin
            wait( xif.result_ready & xif.result_valid );
            @(posedge clk);

            // check response valid ids
            assert(xif.issue_req.hartid == xif.result.hartid);
            assert(xif.issue_req.id == xif.result.id);
        end
    end
end
endtask //automatic

task define_register;
    input register  r   ;
    input int       w   ;
    input int       h   ;
    input dtype_t   dt  ;
begin
    riscv_r_t inst;
    int width_r, height_r;
    $display("Define new register ( width: %d, height: %d, dtype: %s, registerId: %d )", w, h, dt, r);
    
    width_r = reg_id();
    height_r = reg_id();

    rf[width_r] = w;
    rf[height_r] = h;

    inst.opcode   = OPCODE;
    inst.rd       = r;
    inst.funct3   = DEFINE;
    inst.rs1      = width_r;
    inst.rs2      = height_r;
    inst.func7    = dt;

    do_xif(
        .instr    ( inst ),
        .shallPass( 1'd1 ),
        .commit   ( 1'd1 )
    );

    // check register in RFT
    assert (i_dut.i_data_path.i_ccu.rft[r].width == w);
    assert (i_dut.i_data_path.i_ccu.rft[r].height == h);
    assert (i_dut.i_data_path.i_ccu.rft[r].dtype == dt);
    assert (i_dut.i_data_path.i_ccu.rft[r].valid);
    assert (~i_dut.i_data_path.i_ccu.rft[r].prf_valid);
    assert (~i_dut.i_data_path.i_ccu.rft[r].in_mem);
end
endtask

task define_prf_register;
    input register          r       ;
    input int               prf_x   ;
    input int               prf_y   ;
    input organization_t    org     ;
begin
    riscv_r_t inst;
    int prf_x_r, prf_y_r;
    $display("Define prf register ( prf_x: %d, prf_y: %d, organization: %s, registerId: %d )", prf_x, prf_y, org, r);
    
    assert (i_dut.i_data_path.i_ccu.rft[r].valid);

    prf_x_r = reg_id();
    prf_y_r = reg_id();

    rf[prf_x_r] = prf_x;
    rf[prf_y_r] = prf_y;

    inst.opcode   = OPCODE;
    inst.rd       = r;
    inst.funct3   = DEFINE_POLY;
    inst.rs1      = prf_x_r;
    inst.rs2      = prf_y_r;
    inst.func7    = org;

    do_xif(
        .instr    ( inst ),
        .shallPass( 1'd1 ),
        .commit   ( 1'd1 )
    );

    // check register in RFT
    assert (i_dut.i_data_path.i_ccu.rft[r].prf_x == prf_x);
    assert (i_dut.i_data_path.i_ccu.rft[r].prf_y == prf_y);
    assert (i_dut.i_data_path.i_ccu.rft[r].prf_org == org);
    assert (i_dut.i_data_path.i_ccu.rft[r].prf_valid);
    assert (~i_dut.i_data_path.i_ccu.rft[r].in_mem);
end
endtask

task define_register_one_step;
  input register        r       ;
  input int             w       ;
  input int             h       ;
  input dtype_t         dt      ;
  input int             prf_x   ;
  input int             prf_y   ;
  input organization_t  org     ;
begin

  define_register(
    .r  ( r ),
    .w  ( w ),
    .h  ( h ),
    .dt ( dt)
  );
  define_prf_register(
    .r      ( r     ),
    .prf_x  ( prf_x ),
    .prf_y  ( prf_y ),
    .org    ( org   )
  );

end
endtask

task load_register;
    input register  r   ;
    input int       addr;
begin
    riscv_i_t inst;
    int addr_r;

    $display("Load register ( registerId: %d, addr: %h )", r, addr);
    assert(i_dut.i_data_path.i_ccu.rft[r].valid);
    assert(i_dut.i_data_path.i_ccu.rft[r].prf_valid);

    addr_r = reg_id();

    rf[addr_r] = addr;

    inst.opcode   = OPCODE;
    inst.rd       = r;
    inst.funct3   = LOAD;
    inst.rs1      = addr_r;
    inst.imm      = 'd0;

    do_xif(
        .instr    ( inst ),
        .shallPass( 1'd1 ),
        .commit   ( 1'd1 )
    );

    assert(i_dut.i_data_path.i_ccu.rft[r].in_mem);
    end
    endtask

task vector_vector_operation;
    input register      rr  ;
    input register      r1  ;
    input register      r2  ;
    input operation_t   o   ;
begin
    riscv_r_t inst;

    $display("Vector-Vector operation ( rd: %d, r1: %d, r2: %d, operation: %s )", rr, r1, r2, o);

    // check registers
    assert(i_dut.i_data_path.i_ccu.rft[rr].valid);
    assert(i_dut.i_data_path.i_ccu.rft[r1].valid);
    assert(i_dut.i_data_path.i_ccu.rft[r2].valid);
    assert(i_dut.i_data_path.i_ccu.rft[rr].prf_valid);
    assert(i_dut.i_data_path.i_ccu.rft[r1].prf_valid);
    assert(i_dut.i_data_path.i_ccu.rft[r2].prf_valid);
    assert(i_dut.i_data_path.i_ccu.rft[r1].in_mem);
    assert(i_dut.i_data_path.i_ccu.rft[r2].in_mem);
    if ( o == MUL ) begin
        assert(i_dut.i_data_path.i_ccu.rft[rr].height == i_dut.i_data_path.i_ccu.rft[r1].height &
                i_dut.i_data_path.i_ccu.rft[rr].width == i_dut.i_data_path.i_ccu.rft[r2].width &
                i_dut.i_data_path.i_ccu.rft[r1].width == i_dut.i_data_path.i_ccu.rft[r2].height);
    end else begin 
        assert(i_dut.i_data_path.i_ccu.rft[r1].width == i_dut.i_data_path.i_ccu.rft[r2].width &
                i_dut.i_data_path.i_ccu.rft[r1].height == i_dut.i_data_path.i_ccu.rft[r2].height);
        assert(i_dut.i_data_path.i_ccu.rft[rr].width == i_dut.i_data_path.i_ccu.rft[r2].width &
                i_dut.i_data_path.i_ccu.rft[rr].height == i_dut.i_data_path.i_ccu.rft[r2].height);
    end

    inst.opcode   = OPCODE;
    inst.rd       = rr;
    inst.funct3   = VV;
    inst.rs1      = r1;
    inst.rs2      = r2;
    inst.func7    = o;

    do_xif(
        .instr    ( inst ),
        .shallPass( 1'd1 ),
        .commit   ( 1'd1 )
    );

    assert(i_dut.i_data_path.i_ccu.rft[rr].in_mem);
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
    input register  r   ;
    input int       addr;
begin
    riscv_i_t inst;
    int addr_r;

    $display("Store register ( registerId: %d, addr: %h )", r, addr);

    assert(i_dut.i_data_path.i_ccu.rft[r].valid);
    assert(i_dut.i_data_path.i_ccu.rft[r].prf_valid);
    assert(i_dut.i_data_path.i_ccu.rft[r].in_mem);

    addr_r = reg_id();
    rf[addr_r] = addr;

    inst.opcode   = OPCODE;
    inst.rd       = r;
    inst.funct3   = STORE;
    inst.rs1      = addr_r;
    inst.imm      = 'd0;

    do_xif(
        .instr    ( inst ),
        .shallPass( 1'd1 ),
        .commit   ( 1'd1 )
    );

    end
endtask

task vector_scalar_operation;
    input register    rr  ;
    input register    r1  ;
    input int         r2  ;
    input operation_t o   ;
begin
    riscv_r_t inst;
    int rs2_i;

    $display("Vector-Scalar operation ( rd: %d, r1: %d, r2: %d, operation: %s )", rr, r1, r2, o);

    // check registers
    assert(i_dut.i_data_path.i_ccu.rft[rr].valid);
    assert(i_dut.i_data_path.i_ccu.rft[r1].valid);
    assert(i_dut.i_data_path.i_ccu.rft[rr].prf_valid);
    assert(i_dut.i_data_path.i_ccu.rft[r1].prf_valid);
    assert(i_dut.i_data_path.i_ccu.rft[r1].in_mem);
    assert(i_dut.i_data_path.i_ccu.rft[rr].width == i_dut.i_data_path.i_ccu.rft[r1].width &
            i_dut.i_data_path.i_ccu.rft[rr].height == i_dut.i_data_path.i_ccu.rft[r1].height)

    rs2_i = reg_id();
    rf[rs2_i] = r2;

    inst.opcode   = OPCODE;
    inst.rd       = rr;
    inst.funct3   = VS;
    inst.rs1      = r1;
    inst.rs2      = rs2_i;
    inst.func7    = o;

    do_xif(
        .instr    ( inst ),
        .shallPass( 1'd1 ),
        .commit   ( 1'd1 )
    );

    assert(i_dut.i_data_path.i_ccu.rft[rr].in_mem);
end
endtask

task load_store_test;
    input register  r       ;
    input int       w       ;
    input int       h       ;
    input int       prf_x   ;
    input int       prf_y   ;
    input dtype_t   dt      ;
    input int       addr    ;
begin
    int bytes;
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
    load_register(
        .r   ( r    ), 
        .addr( addr )
    );
    store_register(
        .r   ( r                    ), 
        .addr( MEM_SIZE / 2 + addr  )
    );

    // check
    bytes = 1;

    if ( dt == INT16 | dt == UINT16 )
        bytes = 2;
    else if ( dt == INT32 | dt == UINT32 )
        bytes = 4;
    
    for ( i = 0; i < w * h * bytes; i = i + 1) begin
        assert(i_sim_mem.i_sim_mem.mem[addr + i] == i_sim_mem.i_sim_mem.mem[MEM_SIZE / 2 + addr + i]);
        i_sim_mem.i_sim_mem.mem[MEM_SIZE / 2 + addr + i] = 'dx;
    end
    $display("------------------------------------------------------");
end
endtask

function int data_concat (int ad, dtype_t dt);
    case(dt)
        INT32   : data_concat = {i_sim_mem.i_sim_mem.mem[ad + 3], i_sim_mem.i_sim_mem.mem[ad + 2], i_sim_mem.i_sim_mem.mem[ad + 1], i_sim_mem.i_sim_mem.mem[ad + 0]};
        UINT32  : data_concat = {i_sim_mem.i_sim_mem.mem[ad + 3], i_sim_mem.i_sim_mem.mem[ad + 2], i_sim_mem.i_sim_mem.mem[ad + 1], i_sim_mem.i_sim_mem.mem[ad + 0]};
        INT16   : data_concat = {{16{i_sim_mem.i_sim_mem.mem[ad + 1][7]}}, {i_sim_mem.i_sim_mem.mem[ad + 1], i_sim_mem.i_sim_mem.mem[ad + 0]}};
        UINT16  : data_concat = {16'd0, {i_sim_mem.i_sim_mem.mem[ad + 1], i_sim_mem.i_sim_mem.mem[ad + 0]}};
        INT8    : data_concat = {{24{i_sim_mem.i_sim_mem.mem[ad][7]}}, i_sim_mem.i_sim_mem.mem[ad]};
        UINT8   : data_concat = {24'd0, {i_sim_mem.i_sim_mem.mem[ad + 1], i_sim_mem.i_sim_mem.mem[ad + 0]}};
    endcase
endfunction

task vector_vector_operation_test;
    input register      rr      ;
    input int           rr_prf_x;
    input int           rr_prf_y;
    input register      r1      ;
    input int           r1_prf_x;
    input int           r1_prf_y;
    input register      r2      ;
    input int           r2_prf_x;
    input int           r2_prf_y;
    input operation_t   o       ;
    input dtype_t       dt      ;
    input int           w       ;
    input int           h       ;
    input int           rr_addr ;
    input int           r1_addr ;
    input int           r2_addr ;
begin
    int bytes;
    int i;
    $display("Vector-Vector operation test");
    define_register_one_step(
        .r    ( rr      ),
        .w    ( w       ),
        .h    ( h       ),
        .dt   ( dt      ),
        .prf_x( rr_prf_x),
        .prf_y( rr_prf_y),
        .org  ( RECT    )
    );
    define_register_one_step(
        .r    ( r1      ),
        .w    ( w       ),
        .h    ( h       ),
        .dt   ( dt      ),
        .prf_x( r1_prf_x),
        .prf_y( r1_prf_y),
        .org  ( RECT    )
    );
    define_register_one_step(
        .r    ( r2      ),
        .w    ( w       ),
        .h    ( h       ),
        .dt   ( dt      ),
        .prf_x( r2_prf_x),
        .prf_y( r2_prf_y),
        .org  ( RECT    )
    );

    load_register(
        .r   ( r1       ), 
        .addr( r1_addr  )
    );
    load_register(
        .r   ( r2       ), 
        .addr( r2_addr  )
    );

    vector_vector_operation(
        .rr ( rr ), 
        .r1 ( r1 ), 
        .r2 ( r2 ), 
        .o  ( o  )
    );

    store_register(
        .r   ( rr       ), 
        .addr( rr_addr  )
    );

    // check result
    bytes = 1;

    if ( dt == INT16 | dt == UINT16 )
        bytes = 2;
    else if ( dt == INT32 | dt == UINT32 )
        bytes = 4;

    for ( i = 0; i < w * h * bytes; i = i + bytes ) begin
        if ( dt == INT32 | dt == UINT32 ) begin
        assert({i_sim_mem.i_sim_mem.mem[rr_addr + i + 3], i_sim_mem.i_sim_mem.mem[rr_addr + i + 2], i_sim_mem.i_sim_mem.mem[rr_addr + i + 1], i_sim_mem.i_sim_mem.mem[rr_addr + i + 0]} == 
            alu({i_sim_mem.i_sim_mem.mem[r1_addr + i + 3], i_sim_mem.i_sim_mem.mem[r1_addr + i + 2], i_sim_mem.i_sim_mem.mem[r1_addr + i + 1], i_sim_mem.i_sim_mem.mem[r1_addr + i + 0]}, 
                {i_sim_mem.i_sim_mem.mem[r2_addr + i + 3], i_sim_mem.i_sim_mem.mem[r2_addr + i + 2], i_sim_mem.i_sim_mem.mem[r2_addr + i + 1], i_sim_mem.i_sim_mem.mem[r2_addr + i + 0]}, o)[31:0]) else
        $error("byte: %d, rd: %d, rs1: %d, rs2: %d", i,
        {i_sim_mem.i_sim_mem.mem[rr_addr + i + 3], i_sim_mem.i_sim_mem.mem[rr_addr + i + 2], i_sim_mem.i_sim_mem.mem[rr_addr + i + 1], i_sim_mem.i_sim_mem.mem[rr_addr + i + 0]},
        {i_sim_mem.i_sim_mem.mem[r1_addr + i + 3], i_sim_mem.i_sim_mem.mem[r1_addr + i + 2], i_sim_mem.i_sim_mem.mem[r1_addr + i + 1], i_sim_mem.i_sim_mem.mem[r1_addr + i + 0]},
        {i_sim_mem.i_sim_mem.mem[r2_addr + i + 3], i_sim_mem.i_sim_mem.mem[r2_addr + i + 2], i_sim_mem.i_sim_mem.mem[r2_addr + i + 1], i_sim_mem.i_sim_mem.mem[r2_addr + i + 0]});
        end
        else if ( dt == INT16 | dt == UINT16 ) begin
        assert({i_sim_mem.i_sim_mem.mem[rr_addr + i + 1], i_sim_mem.i_sim_mem.mem[rr_addr + i + 0]} == 
            alu({i_sim_mem.i_sim_mem.mem[r1_addr + i + 1], i_sim_mem.i_sim_mem.mem[r1_addr + i + 0]}, 
                {i_sim_mem.i_sim_mem.mem[r2_addr + i + 1], i_sim_mem.i_sim_mem.mem[r2_addr + i + 0]}, o)[15:0]) else
        $error("byte: %d, rd: %d, rs1: %d, rs2: %d", i,
        {i_sim_mem.i_sim_mem.mem[rr_addr + i + 1], i_sim_mem.i_sim_mem.mem[rr_addr + i + 0]},
        {i_sim_mem.i_sim_mem.mem[r1_addr + i + 1], i_sim_mem.i_sim_mem.mem[r1_addr + i + 0]},
        {i_sim_mem.i_sim_mem.mem[r2_addr + i + 1], i_sim_mem.i_sim_mem.mem[r2_addr + i + 0]});
        end
        else if ( dt == INT8 | dt == UINT8 ) begin
        assert(i_sim_mem.i_sim_mem.mem[rr_addr + i] == alu(i_sim_mem.i_sim_mem.mem[r1_addr + i], i_sim_mem.i_sim_mem.mem[r2_addr + i], o)[7:0]) else 
        $error("byte: %d, rd: %d, rs1: %d, rs2: %d", i, {i_sim_mem.i_sim_mem.mem[rr_addr + i]}, {i_sim_mem.i_sim_mem.mem[r1_addr + i]}, {i_sim_mem.i_sim_mem.mem[r2_addr + i]});    
        end
    end

    $display("------------------------------------------------------");
end
endtask

task gemm_test;
    input register      rr      ;
    input int           rr_prf_x;
    input int           rr_prf_y;
    input dtype_t       rr_dt   ;
    input register      r1      ;
    input int           r1_prf_x;
    input int           r1_prf_y;
    input dtype_t       r1_dt   ;
    input register      r2      ;
    input int           r2_prf_x;
    input int           r2_prf_y;
    input dtype_t       r2_dt   ;
    input int           m       ;
    input int           n       ;
    input int           p       ;
    input int           rr_addr ;
    input int           r1_addr ;
    input int           r2_addr ;
begin
    int bytes_rr, bytes_r1, bytes_r2, el;
    int i, j, k;
    $display("Vector-Vector operation test");
    define_register_one_step(
        .r    ( rr      ),
        .w    ( p       ),
        .h    ( m       ),
        .dt   ( rr_dt   ),
        .prf_x( rr_prf_x),
        .prf_y( rr_prf_y),
        .org  ( RECT    )
    );
    define_register_one_step(
        .r    ( r1      ),
        .w    ( n       ),
        .h    ( m       ),
        .dt   ( r1_dt   ),
        .prf_x( r1_prf_x),
        .prf_y( r1_prf_y),
        .org  ( RECT    )
    );
    define_register_one_step(
        .r    ( r2      ),
        .w    ( p       ),
        .h    ( n       ),
        .dt   ( r2_dt   ),
        .prf_x( r2_prf_x),
        .prf_y( r2_prf_y),
        .org  ( RECT    )
    );

    load_register(
        .r   ( r1       ), 
        .addr( r1_addr  )
    );
    load_register(
        .r   ( r2       ), 
        .addr( r2_addr  )
    );

    vector_vector_operation(
        .rr ( rr ), 
        .r1 ( r1 ), 
        .r2 ( r2 ), 
        .o  ( MUL)
    );

    store_register(
        .r   ( rr       ), 
        .addr( rr_addr  )
    );

    // check result
    bytes_rr = 1;
    if ( rr_dt == INT16 | rr_dt == UINT16 )
        bytes_rr = 2;
    else if ( rr_dt == INT32 | rr_dt == UINT32 )
        bytes_rr = 4;

    bytes_r1 = 1;
    if ( r1_dt == INT16 | r1_dt == UINT16 )
        bytes_r1 = 2;
    else if ( r1_dt == INT32 | r1_dt == UINT32 )
        bytes_r1 = 4;
    
    bytes_r2 = 1;
    if ( r2_dt == INT16 | r2_dt == UINT16 )
        bytes_r2 = 2;
    else if ( r2_dt == INT32 | r2_dt == UINT32 )
        bytes_r2 = 4;

    for ( i = 0; i < m; i = i + 1 )
        for ( j = 0; j < p; j = j +1 ) begin
            el = 0;
            for ( k = 0; k < m; k = k + 1 ) begin
                el = el + data_concat(r1_addr + ( i * n + k ) * bytes_r1, r1_dt) * data_concat(r2_addr + ( k * p + j ) * bytes_r2, r2_dt);
            end
                if ( rr_dt == INT32 | rr_dt == UINT32 ) begin
                    assert(el == data_concat(rr_addr + ( i * p + j ) * bytes_rr, rr_dt)) else
                    $error("i: %d, j: %d, rd_expected: %d, rd_computed: %d", i, j, el, data_concat(rr_addr + ( i * p + j ) * bytes_rr, rr_dt));
                end
                else if ( rr_dt == INT16 | rr_dt == UINT16 ) begin
                    assert(el[15 : 0] == data_concat(rr_addr + ( i * p + j ) * bytes_rr, rr_dt)[15 : 0]) else
                    $error("i: %d, j: %d, rd_expected: %d, rd_computed: %d", i, j, el, data_concat(rr_addr + ( i * p + j ) * bytes_rr, rr_dt));
                end
                else if ( rr_dt == INT8 | rr_dt == UINT8 ) begin
                    assert(el[7 : 0] == data_concat(rr_addr + ( i * p + j ) * bytes_rr, rr_dt)[7 : 0]) else
                    $error("i: %d, j: %d, rd_expected: %d, rd_computed: %d", i, j, el, data_concat(rr_addr + ( i * p + j ) * bytes_rr, rr_dt));
                end
        end

    $display("------------------------------------------------------");
end
endtask

task vector_scalar_operation_test;
    input register      rr      ;
    input int           rr_prf_x;
    input int           rr_prf_y;
    input register      r1      ;
    input int           r1_prf_x;
    input int           r1_prf_y;
    input int           r2      ;
    input operation_t   o       ;
    input dtype_t       dt      ;
    input int           w       ;
    input int           h       ;
    input int           rr_addr ;
    input int           r1_addr ;
begin
    int bytes;
    int i;
    $display("Vector-Scalar operation test");
    define_register_one_step(
        .r    ( rr      ),
        .w    ( w       ),
        .h    ( h       ),
        .dt   ( dt      ),
        .prf_x( rr_prf_x),
        .prf_y( rr_prf_y),
        .org  ( RECT    )
    );
    define_register_one_step(
        .r    ( r1      ),
        .w    ( w       ),
        .h    ( h       ),
        .dt   ( dt      ),
        .prf_x( r1_prf_x),
        .prf_y( r1_prf_y),
        .org  ( RECT    )
    );

    load_register(
        .r   ( r1       ), 
        .addr( r1_addr  )
    );  

    vector_scalar_operation(
        .rr ( rr ), 
        .r1 ( r1 ), 
        .r2 ( r2 ), 
        .o  ( o  )
    );

    store_register(
        .r   ( rr       ), 
        .addr( rr_addr  )
    );

    // check result
    bytes = 1;

    if ( dt == INT16 | dt == UINT16 )
        bytes = 2;
    else if ( dt == INT32 | dt == UINT32 )
        bytes = 4;

    for ( i = 0; i < w * h * bytes; i = i + bytes ) begin
        if ( dt == INT32 | dt == UINT32 ) begin
        assert({i_sim_mem.i_sim_mem.mem[rr_addr + i + 3], i_sim_mem.i_sim_mem.mem[rr_addr + i + 2], i_sim_mem.i_sim_mem.mem[rr_addr + i + 1], i_sim_mem.i_sim_mem.mem[rr_addr + i + 0]} == 
            alu({i_sim_mem.i_sim_mem.mem[r1_addr + i + 3], i_sim_mem.i_sim_mem.mem[r1_addr + i + 2], i_sim_mem.i_sim_mem.mem[r1_addr + i + 1], i_sim_mem.i_sim_mem.mem[r1_addr + i + 0]}, 
                r2, o)[31:0]) else
        $error("byte: %d, rd: %d, rs1: %d, rs2: %d", i,
        {i_sim_mem.i_sim_mem.mem[rr_addr + i + 3], i_sim_mem.i_sim_mem.mem[rr_addr + i + 2], i_sim_mem.i_sim_mem.mem[rr_addr + i + 1], i_sim_mem.i_sim_mem.mem[rr_addr + i + 0]},
        {i_sim_mem.i_sim_mem.mem[r1_addr + i + 3], i_sim_mem.i_sim_mem.mem[r1_addr + i + 2], i_sim_mem.i_sim_mem.mem[r1_addr + i + 1], i_sim_mem.i_sim_mem.mem[r1_addr + i + 0]},
        r2);
        end
        else if ( dt == INT16 | dt == UINT16 ) begin
        assert({i_sim_mem.i_sim_mem.mem[rr_addr + i + 1], i_sim_mem.i_sim_mem.mem[rr_addr + i + 0]} == 
            alu({i_sim_mem.i_sim_mem.mem[r1_addr + i + 1], i_sim_mem.i_sim_mem.mem[r1_addr + i + 0]}, 
                r2[15: 0], o)[15:0]) else
        $error("byte: %d, rd: %d, rs1: %d, rs2: %d", i,
        {i_sim_mem.i_sim_mem.mem[rr_addr + i + 1], i_sim_mem.i_sim_mem.mem[rr_addr + i + 0]},
        {i_sim_mem.i_sim_mem.mem[r1_addr + i + 1], i_sim_mem.i_sim_mem.mem[r1_addr + i + 0]},
        r2[15 : 0]);
        end
        else if ( dt == INT8 | dt == UINT8 ) begin
        assert(i_sim_mem.i_sim_mem.mem[rr_addr + i] == alu(i_sim_mem.i_sim_mem.mem[r1_addr + i], r2[7 : 0], o)[7:0]) else 
        $error("byte: %d, rd: %d, rs1: %d, rs2: %d", i, {i_sim_mem.i_sim_mem.mem[rr_addr + i]}, {i_sim_mem.i_sim_mem.mem[r1_addr + i]}, r2[7 : 0]);    
        end
    end

    $display("------------------------------------------------------");
end
endtask

initial begin
    hartId <= 'd0; 
    opId <= 'd0;
    xif.compressed_valid <= 'd0;
    xif.issue_valid <= 'd0;
    xif.register_valid <= 'd0;
    xif.commit_valid <= 'd0;
    xif.result_ready <= 'd1;
    xif.issue_req.instr <= 'd0;

    @(negedge rst_n);

    wait(axi.aw_ready);
    @(posedge clk);
    @(posedge clk);

    init_mem();

    
    // ------- test register definition -------
    $display("Define register test");
    for ( int ridx = 0; ridx < NUMBER_OF_REGISTERS; ridx = ridx + 1 ) begin
        define_register_one_step(
        .r    ( ridx  ),
        .w    ( 'd1024),
        .h    ( 'd1024),
        .dt   ( INT32 ),
        .prf_x( 'd0   ),
        .prf_y( 'd0   ),
        .org  ( RECT  )
        );
        $display("------------------------------------------------------");
    end

    // ------- test memory operaions -------
    load_store_test(
        .r     ( 'd0    ), 
        .w     ( 32     ), 
        .h     ( 32     ), 
        .prf_x ( 0      ), 
        .prf_y ( 0      ), 
        .dt    ( UINT8  ), 
        .addr  ( 'h0    )
    );
    load_store_test(
        .r     ( 'd0    ), 
        .w     ( 32     ), 
        .h     ( 32     ), 
        .prf_x ( 0      ), 
        .prf_y ( 0      ), 
        .dt    ( UINT16 ), 
        .addr  ( 'h0    )
    );
    load_store_test(
        .r     ( 'd0    ), 
        .w     ( 32     ), 
        .h     ( 32     ), 
        .prf_x ( 0      ), 
        .prf_y ( 0      ), 
        .dt    ( UINT32 ), 
        .addr  ( 'h0    )
    );
        
    // ------- test vector vector operations -------
    vector_vector_operation_test(
        .rr      ( 'd2      ),
        .rr_prf_x( 'd0      ),
        .rr_prf_y( 'd64     ),
        .r1      ( 'd0      ),
        .r1_prf_x( 'd0      ),
        .r1_prf_y( 'd0      ),
        .r2      ( 'd1      ),
        .r2_prf_x( 'd0      ),
        .r2_prf_y( 'd32     ),
        .o       ( SUB      ),
        .dt      ( INT8     ),
        .w       ( 'd32     ),
        .h       ( 'd32     ),
        .rr_addr ( MEM_SIZE ),
        .r1_addr ( 'd0      ),
        .r2_addr ( 'd0      )
    );
    vector_vector_operation_test(
        .rr      ( 'd2      ),
        .rr_prf_x( 'd0      ),
        .rr_prf_y( 'd64     ),
        .r1      ( 'd0      ),
        .r1_prf_x( 'd0      ),
        .r1_prf_y( 'd0      ),
        .r2      ( 'd1      ),
        .r2_prf_x( 'd0      ),
        .r2_prf_y( 'd32     ),
        .o       ( ADD      ),
        .dt      ( INT8     ),
        .w       ( 'd32     ),
        .h       ( 'd32     ),
        .rr_addr ( MEM_SIZE + MEM_SIZE / 4 ),
        .r1_addr ( MEM_SIZE ),
        .r2_addr ( 'd0      )
    );
    

    vector_vector_operation_test(
        .rr      ( 'd2      ),
        .rr_prf_x( 'd0      ),
        .rr_prf_y( 'd64     ),
        .r1      ( 'd0      ),
        .r1_prf_x( 'd0      ),
        .r1_prf_y( 'd0      ),
        .r2      ( 'd1      ),
        .r2_prf_x( 'd0      ),
        .r2_prf_y( 'd32     ),
        .o       ( SUB      ),
        .dt      ( INT16    ),
        .w       ( 'd32     ),
        .h       ( 'd32     ),
        .rr_addr ( MEM_SIZE ),
        .r1_addr ( 'd0      ),
        .r2_addr ( 'd0      )
    );
    vector_vector_operation_test(
        .rr      ( 'd2      ),
        .rr_prf_x( 'd0      ),
        .rr_prf_y( 'd64     ),
        .r1      ( 'd0      ),
        .r1_prf_x( 'd0      ),
        .r1_prf_y( 'd0      ),
        .r2      ( 'd1      ),
        .r2_prf_x( 'd0      ),
        .r2_prf_y( 'd32     ),
        .o       ( ADD      ),
        .dt      ( INT16    ),
        .w       ( 'd32     ),
        .h       ( 'd32     ),
        .rr_addr ( MEM_SIZE + MEM_SIZE / 4 ),
        .r1_addr ( MEM_SIZE ),
        .r2_addr ( 'd0      )
    );

    vector_vector_operation_test(
        .rr      ( 'd2      ),
        .rr_prf_x( 'd0      ),
        .rr_prf_y( 'd64     ),
        .r1      ( 'd0      ),
        .r1_prf_x( 'd0      ),
        .r1_prf_y( 'd0      ),
        .r2      ( 'd1      ),
        .r2_prf_x( 'd0      ),
        .r2_prf_y( 'd32     ),
        .o       ( SUB      ),
        .dt      ( INT32    ),
        .w       ( 'd32     ),
        .h       ( 'd32     ),
        .rr_addr ( MEM_SIZE ),
        .r1_addr ( 'd0      ),
        .r2_addr ( 'd0      )
    );
    vector_vector_operation_test(
        .rr      ( 'd2      ),
        .rr_prf_x( 'd0      ),
        .rr_prf_y( 'd64     ),
        .r1      ( 'd0      ),
        .r1_prf_x( 'd0      ),
        .r1_prf_y( 'd0      ),
        .r2      ( 'd1      ),
        .r2_prf_x( 'd0      ),
        .r2_prf_y( 'd32     ),
        .o       ( ADD      ),
        .dt      ( INT32    ),
        .w       ( 'd32     ),
        .h       ( 'd32     ),
        .rr_addr ( MEM_SIZE + MEM_SIZE / 4 ),
        .r1_addr ( MEM_SIZE ),
        .r2_addr ( 'd0      )
    );


    // ------- test vector scalar operations -------
    vector_scalar_operation_test(
        .rr      ( 'd2      ),
        .rr_prf_x( 'd0      ),
        .rr_prf_y( 'd64     ),
        .r1      ( 'd0      ),
        .r1_prf_x( 'd0      ),
        .r1_prf_y( 'd0      ),
        .r2      ( 'd1      ),
        .o       ( ADD      ),
        .dt      ( INT8     ),
        .w       ( 'd32     ),
        .h       ( 'd32     ),
        .rr_addr ( MEM_SIZE + MEM_SIZE / 4 ),
        .r1_addr ( MEM_SIZE )
    );
    vector_scalar_operation_test(
        .rr      ( 'd2      ),
        .rr_prf_x( 'd0      ),
        .rr_prf_y( 'd64     ),
        .r1      ( 'd0      ),
        .r1_prf_x( 'd0      ),
        .r1_prf_y( 'd0      ),
        .r2      ( 'd1      ),
        .o       ( ADD      ),
        .dt      ( INT16    ),
        .w       ( 'd32     ),
        .h       ( 'd32     ),
        .rr_addr ( MEM_SIZE + MEM_SIZE / 4 ),
        .r1_addr ( MEM_SIZE )
    );
    vector_scalar_operation_test(
        .rr      ( 'd2      ),
        .rr_prf_x( 'd0      ),
        .rr_prf_y( 'd64     ),
        .r1      ( 'd0      ),
        .r1_prf_x( 'd0      ),
        .r1_prf_y( 'd0      ),
        .r2      ( 'd1      ),
        .o       ( ADD      ),
        .dt      ( INT32    ),
        .w       ( 'd32     ),
        .h       ( 'd32     ),
        .rr_addr ( MEM_SIZE + MEM_SIZE / 4 ),
        .r1_addr ( MEM_SIZE )
    );
    

    // gemm tests
    gemm_test(
        .rr      ( 'd2      ),
        .rr_prf_x( 'd64     ),
        .rr_prf_y( 'd0      ),
        .rr_dt   ( INT16    ),
        .r1      ( 'd0      ),
        .r1_prf_x( 'd0      ),
        .r1_prf_y( 'd0      ),
        .r1_dt   ( INT8     ),
        .r2      ( 'd1      ),
        .r2_prf_x( 'd0      ),
        .r2_prf_y( 'd64     ),
        .r2_dt   ( INT8     ),
        .m       ( 'd64     ),
        .n       ( 'd64     ),
        .p       ( 'd64     ),
        .rr_addr ( MEM_SIZE ),
        .r1_addr ( 'd0      ),
        .r2_addr ( 'd0      )
    );
    gemm_test(
        .rr      ( 'd2      ),
        .rr_prf_x( 'd64     ),
        .rr_prf_y( 'd0      ),
        .rr_dt   ( INT32    ),
        .r1      ( 'd0      ),
        .r1_prf_x( 'd0      ),
        .r1_prf_y( 'd0      ),
        .r1_dt   ( INT16    ),
        .r2      ( 'd1      ),
        .r2_prf_x( 'd0      ),
        .r2_prf_y( 'd64     ),
        .r2_dt   ( INT16    ),
        .m       ( 'd64     ),
        .n       ( 'd64     ),
        .p       ( 'd64     ),
        .rr_addr ( MEM_SIZE ),
        .r1_addr ( 'd0      ),
        .r2_addr ( 'd0      )
    );
    gemm_test(
        .rr      ( 'd2      ),
        .rr_prf_x( 'd64     ),
        .rr_prf_y( 'd0      ),
        .rr_dt   ( INT32    ),
        .r1      ( 'd0      ),
        .r1_prf_x( 'd0      ),
        .r1_prf_y( 'd0      ),
        .r1_dt   ( INT32    ),
        .r2      ( 'd1      ),
        .r2_prf_x( 'd0      ),
        .r2_prf_y( 'd64     ),
        .r2_dt   ( INT32    ),
        .m       ( 'd64     ),
        .n       ( 'd64     ),
        .p       ( 'd64     ),
        .rr_addr ( MEM_SIZE ),
        .r1_addr ( 'd0      ),
        .r2_addr ( 'd0      )
    );

    @(posedge clk);
    @(posedge clk);

    $stop;
end

endmodule