`include "axi/assign.svh"
`include "axi/typedef.svh"

module tb_ma_ntt();
import ma_pkg::*;
import riscv_pkg::*;

core_v_xif #(
    .X_NUM_RS              ( 2  ),
    .X_ID_WIDTH            ( 4  ),
    .X_RFR_WIDTH           ( 64 ),
    .X_RFW_WIDTH           ( 64 ),
    .X_NUM_HARTS           ( 1  ),
    .X_HARTID_WIDTH        ( 1  ),
    .X_MISA                ( '0 ),
    .X_DUALREAD            ( 0  ),
    .X_DUALWRITE           ( 0  ),
    .X_ISSUE_REGISTER_SPLIT( 0  ),
    .X_MEM_WIDTH           ( 64 ) 
) xif ();

localparam PRF_LOG_P    =   2   ;
localparam PRF_LOG_Q    =   2   ;
localparam PRF_N_LANES  =   2 ** (PRF_LOG_P + PRF_LOG_Q);
localparam PRF_LOG_N    =   10  ;
localparam PRF_LOG_M    =   10  ;
localparam ADDR_WIDTH   =   64  ;
localparam DATA_WIDTH   = 32'd32 * 2 ** (PRF_LOG_P + PRF_LOG_Q);
localparam DATA_BYTES   = DATA_WIDTH / 8;

typedef logic [ADDR_WIDTH - 1 : 0] xif_t;

localparam int unsigned TbAxiIdWidth        = 32'd5;
localparam int unsigned TbAxiDataWidth      = 64;
localparam int unsigned TbAxiAddrWidth      = 64;
localparam int unsigned TbAxiStrbWidth      = TbAxiDataWidth / 8;
localparam int unsigned TbAxiUserWidth      = 5;
localparam              NUMBER_OF_REGISTERS = 32;
localparam              OPCODE              = 7'h2B;
typedef logic [$clog2(NUMBER_OF_REGISTERS) - 1 : 0] register;

logic clk, clk_2x, rst_n;
int hartId, opId;

assign xif.issue_req.hartid = hartId;
assign xif.issue_req.id = opId;
assign xif.register.hartid = hartId;
assign xif.register.id = opId;
assign xif.commit.hartid = hartId;
assign xif.commit.id = opId;

xif_t rf [31 : 0];

localparam MEM_SIZE = 1024 * 1024; // 1 MB

AXI_BUS #(
  .AXI_ADDR_WIDTH ( TbAxiAddrWidth      ),
  .AXI_DATA_WIDTH ( TbAxiDataWidth      ),
  .AXI_ID_WIDTH   ( TbAxiIdWidth        ),
  .AXI_USER_WIDTH ( TbAxiUserWidth      )
) axi ();

axi_sim_mem_intf #(
  .AXI_ADDR_WIDTH      ( TbAxiAddrWidth ),
  .AXI_DATA_WIDTH      ( TbAxiDataWidth ),
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

matrix_accelerator #(
    .OPCODE             ( OPCODE                ),
    .REGISTER_NUMBERS   ( NUMBER_OF_REGISTERS   ),
    .PRF_LOG_P          ( PRF_LOG_P             ),
    .PRF_LOG_Q          ( PRF_LOG_Q             ),
    .PRF_LOG_N          ( PRF_LOG_N             ),
    .PRF_LOG_M          ( PRF_LOG_M             ) 
) i_dut (
    .clk            ( clk   ),
    .clk_2x         ( clk_2x),
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

clk_rstn i_clk_gen (.clk, .clk_2x, .rst_n);

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
        if ( |xif.issue_resp.register_read ) begin
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
        end

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
    input xif_t     w   ;
    input xif_t     h   ;
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
    inst.rs1      = height_r;
    inst.rs2      = width_r;
    inst.func7    = dt;

    do_xif(
        .instr    ( inst ),
        .shallPass( 1'd1 ),
        .commit   ( 1'd1 )
    );

    // check register in RFT
    assert (i_dut.i_control_unit.rft[r].width == w);
    assert (i_dut.i_control_unit.rft[r].height == h);
    assert (i_dut.i_control_unit.rft[r].dtype == dt);
    assert (i_dut.i_control_unit.rft[r].valid);
end
endtask

task define_prf_register;
    input register          r       ;
    input xif_t             prf_x   ;
    input xif_t             prf_y   ;
    input organization_t    org     ;
begin
    riscv_r_t inst;
    int prf_x_r, prf_y_r;
    $display("Define prf register ( prf_x: %d, prf_y: %d, organization: %s, registerId: %d )", prf_x, prf_y, org, r);
    
    assert (i_dut.i_control_unit.rft[r].valid);

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
    assert (i_dut.i_control_unit.rft[r].prf_x == prf_x);
    assert (i_dut.i_control_unit.rft[r].prf_y == prf_y);
    assert (i_dut.i_control_unit.rft[r].prf_org == org);
    assert (i_dut.i_control_unit.rft[r].prf_valid);
end
endtask

task define_register_one_step;
  input register        r       ;
  input xif_t           w       ;
  input xif_t           h       ;
  input dtype_t         dt      ;
  input xif_t           prf_x   ;
  input xif_t           prf_y   ;
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
    input xif_t     addr;
begin
    riscv_i_t inst;
    int addr_r;

    $display("Load register ( registerId: %d, addr: %h )", r, addr);
    assert(i_dut.i_control_unit.rft[r].valid);
    assert(i_dut.i_control_unit.rft[r].prf_valid);

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

    assert(i_dut.i_control_unit.rft[r].in_mem);
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
    assert(i_dut.i_control_unit.rft[rr].valid);
    assert(i_dut.i_control_unit.rft[r1].valid);
    assert(i_dut.i_control_unit.rft[r2].valid);
    assert(i_dut.i_control_unit.rft[rr].prf_valid);
    assert(i_dut.i_control_unit.rft[r1].prf_valid);
    assert(i_dut.i_control_unit.rft[r2].prf_valid);
    assert(i_dut.i_control_unit.rft[r1].in_mem);
    assert(i_dut.i_control_unit.rft[r2].in_mem);
    if ( o == MUL ) begin
        assert(i_dut.i_control_unit.rft[rr].height == i_dut.i_control_unit.rft[r1].height &
                i_dut.i_control_unit.rft[rr].width == i_dut.i_control_unit.rft[r2].width &
                i_dut.i_control_unit.rft[r1].width == i_dut.i_control_unit.rft[r2].height);
    end else if ( o == CNV ) begin 
        assert(i_dut.i_control_unit.rft[rr].width == i_dut.i_control_unit.rft[r1].width - i_dut.i_control_unit.rft[r2].width  + 1);
        assert(i_dut.i_control_unit.rft[rr].height == i_dut.i_control_unit.rft[r1].height - i_dut.i_control_unit.rft[r2].height + 1);
    end else begin
        assert(i_dut.i_control_unit.rft[r1].width == i_dut.i_control_unit.rft[r2].width &
                i_dut.i_control_unit.rft[r1].height == i_dut.i_control_unit.rft[r2].height);
        assert(i_dut.i_control_unit.rft[rr].width == i_dut.i_control_unit.rft[r2].width &
                i_dut.i_control_unit.rft[rr].height == i_dut.i_control_unit.rft[r2].height);
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

    assert(i_dut.i_control_unit.rft[rr].in_mem);
end
endtask

task store_register;
    input register  r   ;
    input xif_t     addr;
begin
    riscv_i_t inst;
    int addr_r;

    $display("Store register ( registerId: %d, addr: %h )", r, addr);

    assert(i_dut.i_control_unit.rft[r].valid);
    assert(i_dut.i_control_unit.rft[r].prf_valid);
    assert(i_dut.i_control_unit.rft[r].in_mem);

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
    input xif_t       r2  ;
    input operation_t o   ;
begin
    riscv_r_t inst;
    int rs2_i;

    $display("Vector-Scalar operation ( rd: %d, r1: %d, r2: %d, operation: %s )", rr, r1, r2, o);

    // check registers
    assert(i_dut.i_control_unit.rft[rr].valid);
    assert(i_dut.i_control_unit.rft[r1].valid);
    assert(i_dut.i_control_unit.rft[rr].prf_valid);
    assert(i_dut.i_control_unit.rft[r1].prf_valid);
    assert(i_dut.i_control_unit.rft[r1].in_mem);
    assert(i_dut.i_control_unit.rft[rr].width == i_dut.i_control_unit.rft[r1].width &
            i_dut.i_control_unit.rft[rr].height == i_dut.i_control_unit.rft[r1].height)

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

    assert(i_dut.i_control_unit.rft[rr].in_mem);
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

task ntt_step_test;
    input register          rr              ;
    input xif_t             rr_prf_x        ;
    input xif_t             rr_prf_y        ;
    input register          r1              ;
    input xif_t             r1_prf_x        ;
    input xif_t             r1_prf_y        ;
    input operation_t       o               ;
    input xif_t             rr_addr         ;
    input xif_t             r1_addr         ;
    input logic [31 : 0]    in      [255:0] ;
    input logic [31 : 0]    out     [255:0] ;
begin
    int i, j;
    $display("NTT step test");

    $display("Init memory");
    for ( i = 0; i < 16; i = i + 1 )
        for ( j = 0; j < 16; j = j + 1 )
            {i_sim_mem.i_sim_mem.mem[r1_addr + (i * 16 + j) * 4 + 3], 
            i_sim_mem.i_sim_mem.mem[r1_addr + (i * 16 + j) * 4 + 2], 
            i_sim_mem.i_sim_mem.mem[r1_addr + (i * 16 + j) * 4 + 1], 
            i_sim_mem.i_sim_mem.mem[r1_addr + (i * 16 + j) * 4]} = in[i * 16 + j];

    define_register_one_step(
        .r    ( rr      ),
        .w    ( 16      ),
        .h    ( 16      ),
        .dt   ( UINT32  ),
        .prf_x( rr_prf_x),
        .prf_y( rr_prf_y),
        .org  ( RECT    )
    );
    define_register_one_step(
        .r    ( r1      ),
        .w    ( 16       ),
        .h    ( 16       ),
        .dt   ( UINT32  ),
        .prf_x( r1_prf_x),
        .prf_y( r1_prf_y),
        .org  ( RECT    )
    );

    load_register(
        .r   ( r1       ), 
        .addr( r1_addr  )
    );

    vector_vector_operation(
        .rr ( rr ), 
        .r1 ( r1 ), 
        .r2 ( 0  ), 
        .o  ( o  )
    );

    store_register(
        .r   ( rr       ), 
        .addr( rr_addr  )
    );

    // check result
    for ( i = 0; i < 16; i = i + 1 )
        for ( j = 0; j < 16; j = j + 1 )
            assert({i_sim_mem.i_sim_mem.mem[rr_addr + (i * 16 + j) * 4 + 3], 
                    i_sim_mem.i_sim_mem.mem[rr_addr + (i * 16 + j) * 4 + 2], 
                    i_sim_mem.i_sim_mem.mem[rr_addr + (i * 16 + j) * 4 + 1], 
                    i_sim_mem.i_sim_mem.mem[rr_addr + (i * 16 + j) * 4]} == out[i * 16 + j]) else
            $error("idx: %d, computed: %d, expected %d", i * j,
                    {i_sim_mem.i_sim_mem.mem[rr_addr + (i * 16 + j) * 4 + 3], i_sim_mem.i_sim_mem.mem[rr_addr + (i * 16 + j) * 4 + 2], i_sim_mem.i_sim_mem.mem[rr_addr + (i * 16 + j) * 4 + 1], i_sim_mem.i_sim_mem.mem[rr_addr + (i * 16 + j) * 4]},
                    out[i * 16 + j]);

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

    ntt_step_test(
        .rr         ( 1 ),
        .rr_prf_x   ( 32 ),
        .rr_prf_y   ( 32 ),
        .r1         ( 0 ),
        .r1_prf_x   ( 0 ),
        .r1_prf_y   ( 0 ),
        .o          ( NTT_R ),
        .rr_addr    ( MEM_SIZE / 2 ),
        .r1_addr    ( 0 ),
        .in         ( '{default:'d1} ),
        .out        ( '{default:'d1} )
    );

    ntt_step_test(
        .rr         ( 1 ),
        .rr_prf_x   ( 32 ),
        .rr_prf_y   ( 32 ),
        .r1         ( 0 ),
        .r1_prf_x   ( 0 ),
        .r1_prf_y   ( 0 ),
        .o          ( NTT_C ),
        .rr_addr    ( MEM_SIZE / 2 ),
        .r1_addr    ( 0 ),
        .in         ( '{default:'d1} ),
        .out        ( '{default:'d1} )
    );

    ntt_step_test(
        .rr         ( 1 ),
        .rr_prf_x   ( 32 ),
        .rr_prf_y   ( 32 ),
        .r1         ( 0 ),
        .r1_prf_x   ( 0 ),
        .r1_prf_y   ( 0 ),
        .o          ( CM ),
        .rr_addr    ( MEM_SIZE / 2 ),
        .r1_addr    ( 0 ),
        .in         ( '{default:'d1} ),
        .out        ( '{default:'d1} )
    );

    ntt_step_test(
        .rr         ( 1 ),
        .rr_prf_x   ( 32 ),
        .rr_prf_y   ( 32 ),
        .r1         ( 0 ),
        .r1_prf_x   ( 0 ),
        .r1_prf_y   ( 0 ),
        .o          ( CMC ),
        .rr_addr    ( MEM_SIZE / 2 ),
        .r1_addr    ( 0 ),
        .in         ( '{default:'d1} ),
        .out        ( '{default:'d1} )
    );

    ntt_step_test(
        .rr         ( 1 ),
        .rr_prf_x   ( 32 ),
        .rr_prf_y   ( 32 ),
        .r1         ( 0 ),
        .r1_prf_x   ( 0 ),
        .r1_prf_y   ( 0 ),
        .o          ( INTT_C ),
        .rr_addr    ( MEM_SIZE / 2 ),
        .r1_addr    ( 0 ),
        .in         ( '{default:'d1} ),
        .out        ( '{default:'d1} )
    );

    ntt_step_test(
        .rr         ( 1 ),
        .rr_prf_x   ( 32 ),
        .rr_prf_y   ( 32 ),
        .r1         ( 0 ),
        .r1_prf_x   ( 0 ),
        .r1_prf_y   ( 0 ),
        .o          ( INTT_R ),
        .rr_addr    ( MEM_SIZE / 2 ),
        .r1_addr    ( 0 ),
        .in         ( '{default:'d1} ),
        .out        ( '{default:'d1} )
    );

    @(posedge clk);
    @(posedge clk);

    $finish();
end

endmodule