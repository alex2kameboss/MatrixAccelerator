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

localparam ADDR_WIDTH   = 32'd32;
localparam DATA_WIDTH   = 32'd128;
localparam DATA_BYTES   = DATA_WIDTH / 8;

localparam int unsigned TbAxiIdWidth        = 32'd5;
localparam int unsigned TbAxiDataWidth      = 32'd128;
localparam int unsigned TbAxiAddrWidth      = 32'd32;
localparam int unsigned TbAxiStrbWidth      = TbAxiDataWidth / 8;
localparam int unsigned TbAxiUserWidth      = 5;
localparam              NUMBER_OF_REGISTERS = 32;
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
  int i;
  for (i = 0; i < MEM_SIZE; i = i + 1)
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

matrix_acclerator #(
    .OPCODE            ( 7'h2B      ),
    .ADDR_WIDTH        ( ADDR_WIDTH ),
    .REGISTER_NUMBERS  ( 32         ),
    .DMA_DATA_WIDTH    ( DATA_WIDTH )
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

localparam MEMORY_SIZE      = 1024 * 1024 * 8; // 1MB
localparam MEMORY_DEPTH     = MEMORY_SIZE / DATA_WIDTH;
logic [DATA_WIDTH - 1 : 0] buffers_clone [NUMBER_OF_REGISTERS - 1 : 0] [0 : MEMORY_DEPTH - 1];

genvar i;
generate
  for ( i = 0; i < NUMBER_OF_REGISTERS; i = i + 1 ) begin : buffers_copy
assign buffers_clone[i] = i_dut.i_data_path.memory_bank[i].i_mem_bank.mem;
  end
endgenerate

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

    inst.opcode   = 7'h2B;
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
    assert (i_dut.i_data_path.i_ccu.rft[r].width == w & 
        i_dut.i_data_path.i_ccu.rft[r].height == h &
        i_dut.i_data_path.i_ccu.rft[r].dtype == dt &
        i_dut.i_data_path.i_ccu.rft[r].valid &
        ~i_dut.i_data_path.i_ccu.rft[r].in_mem);
end
endtask

task load_register;
    input register  r   ;
    input int       addr;
begin
    int bytes, i, j;
    bit pass;
    logic [7 : 0] line [DATA_BYTES - 1 : 0];
    riscv_i_t inst;
    int addr_r;

    $display("Load register ( registerId: %d, addr: %h )", r, addr);
    assert(i_dut.i_data_path.i_ccu.rft[r].valid);

    addr_r = reg_id();

    rf[addr_r] = addr;

    inst.opcode   = 7'h2B;
    inst.rd       = r;
    inst.funct3   = LOAD;
    inst.rs1      = addr_r;
    inst.imm      = 'd0;

    do_xif(
        .instr    ( inst ),
        .shallPass( 1'd1 ),
        .commit   ( 1'd1 )
    );

    // check data in regfile
    bytes = i_dut.i_data_path.i_ccu.rft[r].width * i_dut.i_data_path.i_ccu.rft[r].height;

    if ( i_dut.i_data_path.i_ccu.rft[r].dtype == INT16 | i_dut.i_data_path.i_ccu.rft[r].dtype == UINT16 )
        bytes = bytes * 2;
    else if ( i_dut.i_data_path.i_ccu.rft[r].dtype == INT32 | i_dut.i_data_path.i_ccu.rft[r].dtype == UINT32 )
        bytes = bytes * 4;

    pass = 1'b1;
    for ( i = 0; i < bytes; i = i + DATA_BYTES ) begin
        for ( j = 0; j < DATA_BYTES; j = j + 1 ) begin
        line[j] = i_sim_mem.i_sim_mem.mem[addr + i + j];
        end
        pass = pass & (buffers_clone[r][i / DATA_BYTES] == { >> {line}});
    end
    assert(pass);
    assert(i_dut.i_data_path.i_ccu.rft[r].in_mem);
    end
    endtask

task vector_vector_operation;
    input register      rr  ;
    input register      r1  ;
    input register      r2  ;
    input operation_t   o   ;
begin
    int bytes, i, j;
    bit pass;
    riscv_r_t inst;

    $display("Vector-Vector operation ( rd: %d, r1: %d, r2: %d, operation: %s )", rr, r1, r2, o);

    // check registers
    assert(i_dut.i_data_path.i_ccu.rft[rr].valid);
    assert(i_dut.i_data_path.i_ccu.rft[r1].valid);
    assert(i_dut.i_data_path.i_ccu.rft[r2].valid);
    assert(i_dut.i_data_path.i_ccu.rft[r1].in_mem);
    assert(i_dut.i_data_path.i_ccu.rft[r2].in_mem);
    assert(i_dut.i_data_path.i_ccu.rft[r1].width == i_dut.i_data_path.i_ccu.rft[r2].width &
            i_dut.i_data_path.i_ccu.rft[r1].height == i_dut.i_data_path.i_ccu.rft[r2].height &
            i_dut.i_data_path.i_ccu.rft[r1].dtype == i_dut.i_data_path.i_ccu.rft[r2].dtype)
    assert(i_dut.i_data_path.i_ccu.rft[rr].width == i_dut.i_data_path.i_ccu.rft[r2].width &
            i_dut.i_data_path.i_ccu.rft[rr].height == i_dut.i_data_path.i_ccu.rft[r2].height &
            i_dut.i_data_path.i_ccu.rft[rr].dtype == i_dut.i_data_path.i_ccu.rft[r2].dtype)

    inst.opcode   = 7'h2B;
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

    // check result
    bytes = i_dut.i_data_path.i_ccu.rft[rr].width * i_dut.i_data_path.i_ccu.rft[rr].height;

    if ( i_dut.i_data_path.i_ccu.rft[rr].dtype == INT16 | i_dut.i_data_path.i_ccu.rft[rr].dtype == UINT16 )
        bytes = bytes * 2;
    else if ( i_dut.i_data_path.i_ccu.rft[rr].dtype == INT32 | i_dut.i_data_path.i_ccu.rft[rr].dtype == UINT32 )
        bytes = bytes * 4;

    pass = 1'b1;
    for ( i = 0; i < bytes; i = i + DATA_BYTES ) begin
        if ( i_dut.i_data_path.i_ccu.rft[rr].dtype == INT32 | i_dut.i_data_path.i_ccu.rft[rr].dtype == UINT32 ) 
        for ( j = 0; j < DATA_BYTES / 4; j = j + 1 )
            pass = pass & (buffers_clone[rr][i / DATA_BYTES][ (j + 1) * 32  - 1 -: 32 ] == alu(buffers_clone[r1][i / DATA_BYTES][ (j + 1) * 32 - 1 -: 32 ], buffers_clone[r2][i / DATA_BYTES][ (j + 1) * 32 - 1 -: 32 ], o));
        else if ( i_dut.i_data_path.i_ccu.rft[rr].dtype == INT16 | i_dut.i_data_path.i_ccu.rft[rr].dtype == UINT16 ) 
        for ( j = 0; j < DATA_BYTES / 2; j = j + 1 )
            pass = pass & (buffers_clone[rr][i / DATA_BYTES][ (j + 1) * 16 - 1 -: 16 ] == alu(buffers_clone[r1][i / DATA_BYTES][ (j + 1) * 16 - 1 -: 16 ], buffers_clone[r2][i / DATA_BYTES][ (j + 1) * 16 - 1 -: 16 ], o)[15 : 0]);
        else if ( i_dut.i_data_path.i_ccu.rft[rr].dtype == INT8 | i_dut.i_data_path.i_ccu.rft[rr].dtype == UINT8 ) 
        for ( j = 0; j < DATA_BYTES; j = j + 1 )
            pass = pass & (buffers_clone[rr][i / DATA_BYTES][ (j + 1) * 8 - 1 -: 8 ] == alu(buffers_clone[r1][i / DATA_BYTES][ (j + 1) * 8 - 1 -: 8 ], buffers_clone[r2][i / DATA_BYTES][ (j + 1) * 8 - 1 -: 8 ], o)[7 : 0]);
    end
    assert(pass);
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
    int bytes, i, j;
    bit pass;
    logic [7 : 0] line [DATA_BYTES - 1 : 0];
    riscv_i_t inst;
    int addr_r;

    $display("Store register ( registerId: %d, addr: %h )", r, addr);

    assert(i_dut.i_data_path.i_ccu.rft[r].valid);
    assert(i_dut.i_data_path.i_ccu.rft[r].in_mem);

    addr_r = reg_id();
    rf[addr_r] = addr;

    inst.opcode   = 7'h2B;
    inst.rd       = r;
    inst.funct3   = STORE;
    inst.rs1      = addr_r;
    inst.imm      = 'd0;

    do_xif(
        .instr    ( inst ),
        .shallPass( 1'd1 ),
        .commit   ( 1'd1 )
    );

    // check data in regfile
    bytes = i_dut.i_data_path.i_ccu.rft[r].width * i_dut.i_data_path.i_ccu.rft[r].width;

    if ( i_dut.i_data_path.i_ccu.rft[r].dtype == INT16 | i_dut.i_data_path.i_ccu.rft[r].dtype == UINT16 )
        bytes = bytes * 2;
    else if ( i_dut.i_data_path.i_ccu.rft[r].dtype == INT32 | i_dut.i_data_path.i_ccu.rft[r].dtype == UINT32 )
        bytes = bytes * 4;

    pass = 1'b1;
    for ( i = 0; i < bytes; i = i + DATA_BYTES ) begin
        for ( j = 0; j < DATA_BYTES; j = j + 1 ) begin
        line[j] = i_sim_mem.i_sim_mem.mem[addr + i + j];
        end
        pass = pass & (buffers_clone[r][i / DATA_BYTES] == { >> {line}});
    end
    assert(pass);
    end
endtask

task vector_scalar_operation;
    input register    rr  ;
    input register    r1  ;
    input int         r2  ;
    input operation_t o   ;
begin
    int bytes, i, j;
    bit pass;
    riscv_r_t inst;
    int rs2_i;

    $display("Vector-Scalar operation ( rd: %d, r1: %d, r2: %d, operation: %s )", rr, r1, r2, o);

    // check registers
    assert(i_dut.i_data_path.i_ccu.rft[rr].valid);
    assert(i_dut.i_data_path.i_ccu.rft[r1].valid);
    assert(i_dut.i_data_path.i_ccu.rft[r1].in_mem);
    assert(i_dut.i_data_path.i_ccu.rft[rr].width == i_dut.i_data_path.i_ccu.rft[r1].width &
            i_dut.i_data_path.i_ccu.rft[rr].height == i_dut.i_data_path.i_ccu.rft[r1].height &
            i_dut.i_data_path.i_ccu.rft[rr].dtype == i_dut.i_data_path.i_ccu.rft[r1].dtype)

    rs2_i = reg_id();
    rf[rs2_i] = r2;

    inst.opcode   = 7'h2B;
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

    // check result
    bytes = i_dut.i_data_path.i_ccu.rft[rr].width * i_dut.i_data_path.i_ccu.rft[rr].height;

    if ( i_dut.i_data_path.i_ccu.rft[rr].dtype == INT16 | i_dut.i_data_path.i_ccu.rft[rr].dtype == UINT16 )
        bytes = bytes * 2;
    else if ( i_dut.i_data_path.i_ccu.rft[rr].dtype == INT32 | i_dut.i_data_path.i_ccu.rft[rr].dtype == UINT32 )
        bytes = bytes * 4;

    pass = 1'b1;
    for ( i = 0; i < bytes; i = i + DATA_BYTES ) begin
        if ( i_dut.i_data_path.i_ccu.rft[rr].dtype == INT32 | i_dut.i_data_path.i_ccu.rft[rr].dtype == UINT32 ) 
        for ( j = 0; j < DATA_BYTES / 4; j = j + 1 )
            pass = pass & (buffers_clone[rr][i / DATA_BYTES][ (j + 1) * 32  - 1 -: 32 ] == alu(buffers_clone[r1][i / DATA_BYTES][ (j + 1) * 32 - 1 -: 32 ], r2, o));
        else if ( i_dut.i_data_path.i_ccu.rft[rr].dtype == INT16 | i_dut.i_data_path.i_ccu.rft[rr].dtype == UINT16 ) 
        for ( j = 0; j < DATA_BYTES / 2; j = j + 1 )
            pass = pass & (buffers_clone[rr][i / DATA_BYTES][ (j + 1) * 16 - 1 -: 16 ] == alu(buffers_clone[r1][i / DATA_BYTES][ (j + 1) * 16 - 1 -: 16 ], r2[15 : 0], o)[15 : 0]);
        else if ( i_dut.i_data_path.i_ccu.rft[rr].dtype == INT8 | i_dut.i_data_path.i_ccu.rft[rr].dtype == UINT8 ) 
        for ( j = 0; j < DATA_BYTES; j = j + 1 )
            pass = pass & (buffers_clone[rr][i / DATA_BYTES][ (j + 1) * 8 - 1 -: 8 ] == alu(buffers_clone[r1][i / DATA_BYTES][ (j + 1) * 8 - 1 -: 8 ], r2[7 : 0], o)[7 : 0]);
    end
    assert(pass);
    assert(i_dut.i_data_path.i_ccu.rft[rr].in_mem);
end
endtask

task load_register_test;
    input register    r   ;
    input int         w   ;
    input int         h   ;
    input dtype_t     dt  ;
    input int         addr;
begin
    $display("Load register test");
    define_register(
        .r  ( r  ),
        .w  ( w  ),
        .h  ( h  ),
        .dt ( dt )
    );
    load_register(
        .r   ( r    ), 
        .addr( addr )
    );
    $display("------------------------------------------------------");
end
endtask

task vector_vector_operation_test;
    input register      rr      ;
    input register      r1      ;
    input register      r2      ;
    input operation_t   o       ;
    input dtype_t       dt      ;
    input int           w       ;
    input int           h       ;
    input int           rr_addr ;
    input int           r1_addr ;
    input int           r2_addr ;
begin
    $display("Vector-Vector operation test");
    define_register(
        .r  ( rr ),
        .w  ( w  ),
        .h  ( h  ),
        .dt ( dt )
    );
    define_register(
        .r  ( r1 ),
        .w  ( w  ),
        .h  ( h  ),
        .dt ( dt )
    );
    define_register(
        .r  ( r2 ),
        .w  ( w  ),
        .h  ( h  ),
        .dt ( dt )
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
    $display("------------------------------------------------------");
end
endtask

task vector_scalar_operation_test;
    input register      rr      ;
    input register      r1      ;
    input int           r2      ;
    input operation_t   o       ;
    input dtype_t       dt      ;
    input int           w       ;
    input int           h       ;
    input int           rr_addr ;
    input int           r1_addr ;
begin
    $display("Vector-Scalar operation test");
    define_register(
        .r  ( rr ),
        .w  ( w  ),
        .h  ( h  ),
        .dt ( dt )
    );
    define_register(
        .r  ( r1 ),
        .w  ( w  ),
        .h  ( h  ),
        .dt ( dt )
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

    //for ( register = 0; register < 32; register = register + 1 )
    //  define_register(16, 16, 'd0, register);

    load_register_test(
        .r   ( 'd0   ),
        .w   ( 16    ),
        .h   ( 16    ),
        .dt  ( UINT8 ),
        .addr( 'h0   )
    );
    load_register_test(
        .r   ( 'd0   ),
        .w   ( 8     ),
        .h   ( 8     ),
        .dt  ( UINT16),
        .addr( 'h0   )
    );


    vector_vector_operation_test(
        .rr      ( 'd2      ),
        .r1      ( 'd0      ),
        .r2      ( 'd1      ),
        .o       ( SUB      ),
        .dt      ( INT8     ),
        .w       ( 8        ),
        .h       ( 8        ),
        .rr_addr ( MEM_SIZE ),
        .r1_addr ( 'h0      ),
        .r2_addr ( 'h0      )
    );
    vector_vector_operation_test(
        .rr      ( 'd2      ),
        .r1      ( 'd0      ),
        .r2      ( 'd1      ),
        .o       ( ADD      ),
        .dt      ( INT8     ),
        .w       ( 8        ),
        .h       ( 8        ),
        .rr_addr ( MEM_SIZE ),
        .r1_addr ( MEM_SIZE ),
        .r2_addr ( 'h0      )
    );

    vector_vector_operation_test(
        .rr      ( 'd2      ),
        .r1      ( 'd0      ),
        .r2      ( 'd1      ),
        .o       ( SUB      ),
        .dt      ( INT16    ),
        .w       ( 4        ),
        .h       ( 4        ),
        .rr_addr ( MEM_SIZE ),
        .r1_addr ( 'h0      ),
        .r2_addr ( 'h0      )
    );
    vector_vector_operation_test(
        .rr      ( 'd2      ),
        .r1      ( 'd0      ),
        .r2      ( 'd1      ),
        .o       ( ADD      ),
        .dt      ( INT16    ),
        .w       ( 4        ),
        .h       ( 4        ),
        .rr_addr ( MEM_SIZE ),
        .r1_addr ( MEM_SIZE ),
        .r2_addr ( 'h0      )
    );

    vector_vector_operation_test(
        .rr      ( 'd2      ),
        .r1      ( 'd0      ),
        .r2      ( 'd1      ),
        .o       ( SUB      ),
        .dt      ( INT32    ),
        .w       ( 4        ),
        .h       ( 4        ),
        .rr_addr ( MEM_SIZE ),
        .r1_addr ( 'h0      ),
        .r2_addr ( 'h0      )
    );
    vector_vector_operation_test(
        .rr      ( 'd2      ),
        .r1      ( 'd0      ),
        .r2      ( 'd1      ),
        .o       ( ADD      ),
        .dt      ( INT32    ),
        .w       ( 4        ),
        .h       ( 4        ),
        .rr_addr ( MEM_SIZE ),
        .r1_addr ( MEM_SIZE ),
        .r2_addr ( 'h0      )
    );

    vector_scalar_operation_test(
        .rr      ( 'd2      ),
        .r1      ( 'd0      ),
        .r2      ( 'd0      ),
        .o       ( SUB      ),
        .dt      ( INT8     ),
        .w       ( 8        ),
        .h       ( 8        ),
        .rr_addr ( MEM_SIZE ),
        .r1_addr ( 'h0      )
    );
    vector_scalar_operation_test(
        .rr      ( 'd2      ),
        .r1      ( 'd0      ),
        .r2      ( 'd0      ),
        .o       ( SUB      ),
        .dt      ( INT16    ),
        .w       ( 8        ),
        .h       ( 8        ),
        .rr_addr ( MEM_SIZE ),
        .r1_addr ( 'h0      )
    );
    vector_scalar_operation_test(
        .rr      ( 'd2      ),
        .r1      ( 'd0      ),
        .r2      ( 'd0      ),
        .o       ( SUB      ),
        .dt      ( INT32    ),
        .w       ( 8        ),
        .h       ( 8        ),
        .rr_addr ( MEM_SIZE ),
        .r1_addr ( 'h0      )
    );

    @(posedge clk);
    @(posedge clk);

    $stop;
end

endmodule