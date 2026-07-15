(* keep_hierarchy = "yes" *) module ma_alu #(
    parameter DATA_WIDTH    =   32
) (
    input                                               clk     ,
    input                                               en      ,
    input   ma_pkg::operation_t                         op      ,
    input   ma_pkg::dtype_t                             dtype   ,
    input   logic               [DATA_WIDTH - 1 : 0]    op1     ,
    input   logic               [DATA_WIDTH - 1 : 0]    op2     ,
    output  logic               [DATA_WIDTH - 1 : 0]    rez     
);

localparam SHIFTER_WIDTH = $clog2(DATA_WIDTH);

logic [DATA_WIDTH - 1 : 0]  data_left_shifter, data_right_shifter;
logic                       is_signed;

assign is_signed = (op == ma_pkg::SRA) & (dtype == ma_pkg::INT32 | dtype == ma_pkg::INT16 | dtype == ma_pkg::INT8);

`ifdef TARGET_VIVADO
ma_pkg::vectorial_operation_t vectorial_op;

logic               [DATA_WIDTH - 1 : 0]    rez_comb;

always_comb
    case ( op )
        ma_pkg::SUB : vectorial_op = ma_pkg::V_SUB;
//        ma_pkg::DIV : vectorial_op = ma_pkg::V_DIV;
        ma_pkg::SLL : vectorial_op = ma_pkg::V_SLL;
        ma_pkg::SRL : vectorial_op = ma_pkg::V_SRL;
        ma_pkg::SRA : vectorial_op = ma_pkg::V_SRA;
        ma_pkg::SMUL: vectorial_op = ma_pkg::V_MUL;
        ma_pkg::MUL : vectorial_op = ma_pkg::V_MUL;
        ma_pkg::ADD : vectorial_op = ma_pkg::V_ADD;
        default     : vectorial_op = ma_pkg::V_NOP;
    endcase

always_comb
    unique case( vectorial_op )
        ma_pkg::V_SUB : rez_comb = op1 - op2;
//        ma_pkg::V_DIV : rez_comb = div;
        ma_pkg::V_SLL : rez_comb = data_left_shifter;
        ma_pkg::V_SRL : rez_comb = data_right_shifter;
        ma_pkg::V_SRA : rez_comb = data_right_shifter;
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
        ma_pkg::SLL : rez = data_left_shifter;
        ma_pkg::SRL : rez = data_right_shifter;
        ma_pkg::SRA : rez = data_right_shifter;
        ma_pkg::SMUL: rez = op1 * op2;
        ma_pkg::MUL : rez = op1 * op2;
        default     : rez = op1 + op2;
    endcase
`endif

left_shifter #(
    .BIT_WIDTH      ( 1             ),
    .DATA_WIDTH     ( DATA_WIDTH    ),
    .SHIFTER_WIDTH  ( SHIFTER_WIDTH )
) i_left_shifter (
    .data_i     ( op1                       ),
    .shifter_i  ( op2[SHIFTER_WIDTH - 1 : 0]),
    .data_o     ( data_left_shifter         ) 
);

right_shifter #(
    .BIT_WIDTH      ( 1             ),
    .DATA_WIDTH     ( DATA_WIDTH    ),
    .SHIFTER_WIDTH  ( SHIFTER_WIDTH )
) i_right_shifter (
    .is_signed  ( is_signed                 ),
    .data_i     ( op1                       ),
    .shifter_i  ( op2[SHIFTER_WIDTH - 1 : 0]),
    .data_o     ( data_right_shifter        ) 
);

endmodule