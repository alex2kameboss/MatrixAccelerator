module ma_alu #(
    parameter DATA_WIDTH    =   32
) (
    input   ma_pkg::operation_t                         op  ,
    input   logic               [DATA_WIDTH - 1 : 0]    op1 ,
    input   logic               [DATA_WIDTH - 1 : 0]    op2 ,
    output  logic               [DATA_WIDTH - 1 : 0]    rez 
);
    
always_comb
    case (op)
        ma_pkg::SUB : rez = op1 - op2;
        ma_pkg::DIV : rez = op1 / op2;
        ma_pkg::SMUL: rez = op1 * op2;
        default     : rez = op1 + op2;
    endcase

endmodule