package riscv_pkg;
    
typedef logic[6 : 0]    funct7_t; // 7 bits
typedef logic[4 : 0]    reg_t   ; // 5 bits
typedef logic[2 : 0]    funct3_t; // 3 bits
typedef logic[6 : 0]    opcode_t; // 7 bits
typedef logic[11 : 0]   imm_t   ; // 12 bits

typedef struct packed {
    logic [11 : 0]  data;
    reg_t           rs1;
    funct3_t        funct3;
    reg_t           rd;
    opcode_t        opcode;
} ma_riscv_common_t;

typedef struct packed {
    funct7_t    func7;
    reg_t       rs2;
    reg_t       rs1;
    funct3_t    funct3;
    reg_t       rd;
    opcode_t    opcode;
} riscv_r_t;

typedef struct packed {
    imm_t       imm;
    reg_t       rs1;
    funct3_t    funct3;
    reg_t       rd;
    opcode_t    opcode;
} riscv_i_t;

typedef union packed {
    logic [31 : 0]      bits;
    ma_riscv_common_t   decode;
    riscv_r_t           r_type;
    riscv_i_t           i_type;
} ma_riscv_inst_t;

endpackage