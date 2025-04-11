module ma_alu #(
    parameter DATA_WIDTH    =   32
) (
    input                                               clk ,
    input                                               en  ,
    input   ma_pkg::operation_t                         op  ,
    input   logic               [DATA_WIDTH - 1 : 0]    op1 ,
    input   logic               [DATA_WIDTH - 1 : 0]    op2 ,
    output  logic               [DATA_WIDTH - 1 : 0]    rez 
);
    
`ifdef TARGET_VIVADO
ma_pkg::vectorial_operation_t vectorial_op;

logic               [DATA_WIDTH - 1 : 0]    rez_comb;

always_comb
    case ( op )
        ma_pkg::SUB : vectorial_op = ma_pkg::V_SUB;
//        ma_pkg::DIV : vectorial_op = ma_pkg::V_DIV;
        ma_pkg::SMUL: vectorial_op = ma_pkg::V_MUL;
        ma_pkg::ADD : vectorial_op = ma_pkg::V_ADD;
        default     : vectorial_op = ma_pkg::V_NOP;
    endcase

always_comb
    unique case( vectorial_op )
        ma_pkg::V_SUB : rez_comb = op1 - op2;
//        ma_pkg::V_DIV : rez_comb = div;
        ma_pkg::V_MUL : rez_comb = op1 * op2;
        ma_pkg::V_ADD : rez_comb = op1 + op2;
        ma_pkg::V_NOP : rez_comb = 'd0;
    endcase 

assign rez = rez_comb;

`else
always_comb
    case (op)
        ma_pkg::SUB : rez = op1 - op2;
        ma_pkg::DIV : rez = op1 / op2;
        ma_pkg::SMUL: rez = op1 * op2;
        default     : rez = op1 + op2;
    endcase
`endif

endmodule