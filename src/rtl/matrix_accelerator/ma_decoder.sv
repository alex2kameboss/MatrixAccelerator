module ma_decoder #(
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
typedef enum logic [1 : 0] { IDL, RESPONSE, DATA, EXECUTE } state_t; // TODO: maybe one more stage for response


// Wires Definition ------------------------------------------------------------------------------------------
riscv_pkg::ma_riscv_inst_t instr;
logic valid_instr;
state_t state, next_state;
logic committed, commit_valid, rs1_valid, rs2_valid;
logic accept_rs1, accept_rs2;
logic execute_done;
logic issue_response, raise_valid, clean, raise_result;
logic issue_accept, response_accept;
logic [1 : 0] register_read;


// Combinatorial Logic ---------------------------------------------------------------------------------------
assign registers_if.register_ready = ~rs1_valid | ~rs2_valid;
assign instr.bits = instr_if.issue_req.instr;

assign scalar = reg2;

assign clean = next_state == IDL & state != IDL;

always_comb begin
    next_state = state;
    issue_response = 1'b0;
    raise_valid = 1'b0;
    raise_result = 1'b0;
    
    case (state)
        IDL: begin
            if ( instr_if.issue_valid ) begin
                issue_response = 1'b1;
                next_state = RESPONSE;
            end
        end
        RESPONSE: begin
            if ( instr_if.issue_resp.accept ) begin
                next_state = DATA;
            end else begin
                next_state = IDL;
            end
        end
        DATA: begin
            if ( commit_valid & rs1_valid & rs2_valid ) begin
                if ( committed ) begin
                    next_state = EXECUTE;
                    raise_valid = 1'b1;
                end else begin
                    next_state = IDL;
                end
            end
        end
        EXECUTE: begin
            if ( execute_done ) begin
                next_state = IDL;
                raise_result = 1'b1;
            end
        end
    endcase
end

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
            instr.r_type.func7 == ma_pkg::SLL    |
            instr.r_type.func7 == ma_pkg::SRL    |
            instr.r_type.func7 == ma_pkg::SRA    |
            instr.r_type.func7 == ma_pkg::MUL    |
            instr.r_type.func7 == ma_pkg::FFT    |
            instr.r_type.func7 == ma_pkg::IFFT   |
            instr.r_type.func7 == ma_pkg::SMUL   );
end

assign issue_accept = instr_if.issue_ready & instr_if.issue_valid;
assign response_accept = result_if.result_valid & result_if.result_ready;
assign register_read[0] = instr.decode.funct3 == ma_pkg::DEFINE   | 
                                instr.decode.funct3 == ma_pkg::DEFINE_POLY  |
                                instr.decode.funct3 == ma_pkg::LOAD         |
                                instr.decode.funct3 == ma_pkg::STORE        ;
assign register_read[1] = instr.decode.funct3 == ma_pkg::DEFINE    | 
                                instr.decode.funct3 == ma_pkg::DEFINE_POLY      |
                                instr.decode.funct3 == ma_pkg::VS               ;

assign accept_rs1 = ~rs1_valid & registers_if.register.rs_valid[0] & registers_if.register_valid;
assign accept_rs2 = ~rs2_valid & registers_if.register.rs_valid[1] & registers_if.register_valid;


// Sequential Logic ------------------------------------------------------------------------------------------
always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )               state = IDL;            else
                                state = next_state;

// xif signals
always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )               instr_if.issue_ready <= 'd0;        else
    if ( issue_accept )         instr_if.issue_ready <= 'd0;        else
    if ( issue_response )       instr_if.issue_ready <= 'd1;        

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        instr_if.issue_resp.accept          <= 'd0;
        instr_if.issue_resp.writeback       <= 'd0;
        instr_if.issue_resp.register_read   <= 'd0;
    end else if ( issue_response ) begin
        instr_if.issue_resp.accept          <= valid_instr;
        instr_if.issue_resp.writeback       <= 'd0;
        instr_if.issue_resp.register_read   <= register_read;
    end else if ( issue_accept ) begin
        instr_if.issue_resp.accept          <= 'd0;
        instr_if.issue_resp.writeback       <= 'd0;
        instr_if.issue_resp.register_read   <= 'd0;
    end

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        result_if.result.hartid <= 'd0;
        result_if.result.id     <= 'd0;
        result_if.result.data   <= 'd0;
        result_if.result.rd     <= 'd0;
        result_if.result.we     <= 'd0;
    end else if ( issue_response ) begin
        result_if.result.hartid <= instr_if.issue_req.hartid;
        result_if.result.id     <= instr_if.issue_req.id;
    end else if ( response_accept ) begin
        result_if.result.hartid <= 'd0;
        result_if.result.id     <= 'd0;
    end

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )           result_if.result_valid <= 'd0;              else
    if ( raise_result )     result_if.result_valid <= 'd1;              else
    if ( response_accept )  result_if.result_valid <= 'd0;

// to control unit
always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )           valid <= 'd0;                               else
    if ( raise_valid )      valid <= 'd1;                               else
    if ( valid & ready )    valid <= 'd0;

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )           funct7 <= ma_pkg::NDT;                      else
    if ( issue_response )   funct7 <= instr.r_type.func7;               else
    if ( clean )            funct7 <= ma_pkg::NDT;

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )           funct3 <= ma_pkg::NF3;                                  else
    if ( issue_response )   funct3 <= ma_pkg::funct3_op_t'(instr.decode.funct3);    else
    if ( clean )            funct3 <= ma_pkg::NF3;

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )           op <= ma_pkg::NOP;                          else
    if ( issue_response )   op <= ma_pkg::operation_t'(instr.r_type.func7);else
    if ( clean )            op <= ma_pkg::NOP;

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        rd  <= 'd0;
        rs1 <= 'd0;
        rs2 <= 'd0;
    end else if ( issue_response ) begin
        rd  <= instr.r_type.rd ;
        rs1 <= instr.r_type.rs1;
        rs2 <= instr.r_type.rs2;
    end else if ( clean ) begin
        rd  <= 'd0;
        rs1 <= 'd0;
        rs2 <= 'd0;
    end

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )           addr <= 'd0;                              else
    if ( issue_response )   addr <= {{(ADDR_WIDTH - 12){instr.i_type.imm[11]}}, instr.i_type.imm}; else
    if ( accept_rs1 )       addr <= addr + registers_if.register.rs[0]; else
    if ( clean )            addr <= 'd0;

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )           reg1 <= 'd0;                            else
    if ( accept_rs1 )       reg1 <= registers_if.register.rs[0];    else
    if ( clean )            reg1 <= 'd0;

always_ff @ ( posedge clk, negedge rst_n )
    if ( ~rst_n )           reg2 <= 'd0;                            else
    if ( accept_rs2)        reg2 <= registers_if.register.rs[1];    else
    if ( clean )            reg2 <= 'd0;

// internal flags
always_ff @ ( posedge clk, negedge rst_n )                              
    if ( ~rst_n )           committed <= 'd0;                               else
    if ( commit_if.commit_valid ) committed <= ~commit_if.commit.commit_kill;else
    if ( clean )            committed <= 'd0;

always_ff @ ( posedge clk, negedge rst_n )                              
    if ( ~rst_n )           commit_valid <= 'd0;                    else
    if ( commit_if.commit_valid ) commit_valid <= 'd1;       else
    if ( clean )            commit_valid <= 'd0;                    

always_ff @ ( posedge clk, negedge rst_n )                              
    if ( ~rst_n )           rs1_valid <= 'd0;                       else
    if ( issue_response )   rs1_valid <= ~register_read[0];         else
    if ( clean )            rs1_valid <= 'd0;                       else
    if ( accept_rs1 )       rs1_valid <= 'd1;

always_ff @ ( posedge clk, negedge rst_n )                              
    if ( ~rst_n )           rs2_valid <= 'd0;                       else
    if ( issue_response )   rs2_valid <= ~register_read[1];         else
    if ( clean )            rs2_valid <= 'd0;                       else
    if ( accept_rs2 )       rs2_valid <= 'd1;


// Modules Instances -----------------------------------------------------------------------------------------
posedge_detector i_ready_edge (
    .clk    ( clk           ),
    .rst_n  ( rst_n         ),
    .signal ( ready         ),
    .flag   ( execute_done  )
);

endmodule