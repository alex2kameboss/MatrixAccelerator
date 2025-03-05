module ma_extension_driver #(
    parameter OPCODE            =   7'h2B   ,
    parameter ADDR_WIDTH        =   32      ,
    parameter REGISTER_NUMBERS  =   32      
) (
    // generic signals
    input   logic                                                   clk             ,
    input   logic                                                   rst_n           ,
    // CV-X-IF
    core_v_xif.core_v_xif_coprocessor_issue                         instr_if        ,
    core_v_xif.core_v_xif_coprocessor_register                      registers_if    ,
    core_v_xif.core_v_xif_coprocessor_commit                        commit_if       ,
    core_v_xif.core_v_xif_coprocessor_result                        result_if       ,
    // control signals
// communication signals                            
    output  logic                                                   valid           ,
    input   logic                                                   ready           ,
// control signal       
    output  ma_pkg::funct3_op_t                                     funct3          ,                    
    output  ma_pkg::operation_t                                     op              ,
    output  logic               [ADDR_WIDTH - 1 : 0]                addr            ,
    output  logic               [ADDR_WIDTH - 1 : 0]                scalar          ,
    output  logic               [$clog2(REGISTER_NUMBERS) - 1 : 0]  rd              ,
    output  logic               [$clog2(REGISTER_NUMBERS) - 1 : 0]  rs1             ,
    output  logic               [$clog2(REGISTER_NUMBERS) - 1 : 0]  rs2             ,
    output  logic               [ADDR_WIDTH - 1 : 0]                reg1            ,
    output  logic               [ADDR_WIDTH - 1 : 0]                reg2            ,
    output  logic               [6 : 0]                             funct7            
);
    
// Local Parameters Definition  ------------------------------------------------------------------------------



// Wires Definition ------------------------------------------------------------------------------------------
riscv_pkg::ma_riscv_inst_t instr;
logic accept_issue, valid_instr, taken_instr, response_issuer;
logic load_data;
logic ready_posedge;
logic committed, rs1_valid, rs2_valid;
logic accept_registers;


// Combinatorial Logic ---------------------------------------------------------------------------------------
assign instr.bits = instr_if.issue_req.instr;
assign taken_instr = valid & ready;
assign accept_issue = instr_if.issue_ready & instr_if.issue_valid;
assign response_issuer = instr_if.issue_valid & ready;
assign load_data = response_issuer & valid_instr;

always_comb begin : validate_instr // TODO: when add new instruction, update here
    valid_instr = instr.decode.opcode == OPCODE;
    valid_instr = valid_instr & (
        instr.decode.funct3 == ma_pkg::DEFINE       | 
        instr.decode.funct3 == ma_pkg::DEFINE_POLY  | 
        instr.decode.funct3 == ma_pkg::LOAD         |
        instr.decode.funct3 == ma_pkg::STORE        |
        instr.decode.funct3 == ma_pkg::VV           |
        instr.decode.funct3 == ma_pkg::VS           );
    if ( instr.decode.funct3 == ma_pkg::DEFINE )
        valid_instr = valid_instr & (
            'd0 <= instr.r_type.func7 &
            instr.r_type.func7 <= 'd5 );
    if ( instr.decode.funct3 == ma_pkg::VV | instr.decode.funct3 == ma_pkg::VS )
        valid_instr = valid_instr & ( 
            instr.r_type.func7 == ma_pkg::ADD    |
            instr.r_type.func7 == ma_pkg::SUB    |
            instr.r_type.func7 == ma_pkg::CNV    |
            instr.r_type.func7 == ma_pkg::DIV    |
            instr.r_type.func7 == ma_pkg::MUL    |
            instr.r_type.func7 == ma_pkg::SMUL   );
end

assign registers_if.register_ready = ~rs1_valid | ~rs2_valid | registers_if.register_valid;
assign scalar = reg1;
assign accept_registers = ready & registers_if.register_valid & registers_if.register_ready;


// Sequential Logic ------------------------------------------------------------------------------------------
always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )               instr_if.issue_ready <= 'd0;        else
    if ( accept_issue )         instr_if.issue_ready <= 'd0;        else
    if ( response_issuer )      instr_if.issue_ready <= 'd1;        

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        instr_if.issue_resp.accept          <= 'd0;
        instr_if.issue_resp.writeback       <= 'd0;
        instr_if.issue_resp.register_read   <= 'd0;
        instr_if.issue_resp.loadstore       <= 'd0;
    end else if ( response_issuer ) begin
        instr_if.issue_resp.accept          <= valid_instr;
        instr_if.issue_resp.writeback       <= 'd0;
        instr_if.issue_resp.register_read[0]<= instr.decode.funct3 == ma_pkg::DEFINE   | 
                                        instr.decode.funct3 == ma_pkg::DEFINE_POLY  |
                                        instr.decode.funct3 == ma_pkg::LOAD         |
                                        instr.decode.funct3 == ma_pkg::STORE        ;
        instr_if.issue_resp.register_read[1]<= instr.decode.funct3 == ma_pkg::DEFINE    | 
                                        instr.decode.funct3 == ma_pkg::DEFINE_POLY      |
                                        instr.decode.funct3 == ma_pkg::VS               ;
        instr_if.issue_resp.loadstore       <= 'd0;
    end else if ( taken_instr ) begin
        instr_if.issue_resp.accept          <= 'd0;
        instr_if.issue_resp.writeback       <= 'd0;
        instr_if.issue_resp.register_read   <= 'd0;
        instr_if.issue_resp.loadstore       <= 'd0;
    end

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )           funct7 <= ma_pkg::NDT;                       else
    if ( load_data )        funct7 <= instr.r_type.func7;                else
    if ( valid & ready )    funct7 <= ma_pkg::NDT;

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )           op <= ma_pkg::NOP;                          else
    if ( load_data )        op <= ma_pkg::operation_t'(instr.r_type.func7);else
    if ( valid & ready )    op <= ma_pkg::NOP;

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        rd  <= 'd0;
        rs1 <= 'd0;
        rs2 <= 'd0;
    end else if ( load_data) begin
        rd  <= instr.r_type.rd ;
        rs1 <= instr.r_type.rs1;
        rs2 <= instr.r_type.rs2;
    end else if ( valid & ready ) begin
        rd  <= 'd0;
        rs1 <= 'd0;
        rs2 <= 'd0;
    end

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )           addr <= 'd0;                              else
    if ( load_data )        addr <= {{20{instr.i_type.imm[11]}}, instr.i_type.imm}; else
    if ( accept_registers &  
    registers_if.register.rs_valid[0] ) addr <= addr + registers_if.register.rs[0]; else
    if ( valid & ready )    addr <= 'd0;

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )           reg1 <= 'd0;                               else
    if ( accept_registers &  
    registers_if.register.rs_valid[0])  reg1 <= registers_if.register.rs[0];   else
    if ( valid & ready )    reg1 <= 'd0;

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )           reg2 <= 'd0;                              else
    if ( accept_registers &  
    registers_if.register.rs_valid[1])  reg2 <= registers_if.register.rs[1];   else
    if ( valid & ready )    reg2 <= 'd0;

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )           valid <= 'd0;                               else
    if ( valid & ready )    valid <= 'd0;                               else
                            valid <= committed & rs1_valid & rs2_valid & ready;

always_ff @ ( posedge clk, negedge rst_n )                              
    if ( ~rst_n )           committed <= 'd0;                            else
    if ( commit_if.commit_valid & ~commit_if.commit.commit_kill) committed <= 'd1;        else
    if ( valid & ready )    committed <= 'd0;

always_ff @ ( posedge clk, negedge rst_n )                              
    if ( ~rst_n )           rs1_valid <= 'd0;                           else
    if ( commit_if.commit_valid & commit_if.commit.commit_kill )rs1_valid <= 'd0;        else
    if ( valid & ready )    rs1_valid <= 'd0;                           else
    if ( (instr.decode.funct3 == ma_pkg::VV 
    | instr.decode.funct3 == ma_pkg::VS) & accept_issue ) rs1_valid <= 'd1;             else
    if ( accept_registers &  
    registers_if.register.rs_valid[0] ) rs1_valid <= 'd1;

always_ff @ ( posedge clk, negedge rst_n )                              
    if ( ~rst_n )           rs2_valid <= 'd0;                           else
    if ( commit_if.commit_valid & commit_if.commit.commit_kill )rs2_valid <= 'd0;        else
    if ( valid & ready )    rs2_valid <= 'd0;                           else
    if ( instr.decode.funct3 != ma_pkg::DEFINE & accept_issue ) rs2_valid <= 'd1;     else
    if ( accept_registers &  
    registers_if.register.rs_valid[1] ) rs2_valid <= 'd1;

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        result_if.result.hartid <= 'd0;
        result_if.result.id     <= 'd0;
        result_if.result.data   <= 'd0;
        result_if.result.rd     <= 'd0;
        result_if.result.we     <= 'd0;
        result_if.result.exc    <= 'd0;
        result_if.result.exccode<= 'd0;
        result_if.result.dbg    <= 'd0;
        result_if.result.err    <= 'd0;
    end else if ( instr_if.issue_valid & instr_if.issue_ready ) begin
        result_if.result.hartid <= instr_if.issue_req.hartid;
        result_if.result.id     <= instr_if.issue_req.id;
    end

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )           result_if.result_valid <= 'd0;      else
    if ( result_if.result_valid & result_if.result_ready ) result_if.result_valid <= 'd0; else
    if ( ready_posedge )    result_if.result_valid <= 'd1;


// Modules Instances -----------------------------------------------------------------------------------------
posedge_detector i_ready_posedge (
    .clk    ( clk           ),
    .rst_n  ( rst_n         ),
    .signal ( ready         ),
    .flag   ( ready_posedge ) 
);

endmodule