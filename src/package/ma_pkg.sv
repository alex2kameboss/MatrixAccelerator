package ma_pkg;

typedef enum logic [6:0] {
    ADD = 1,
    SUB = 2,
    CNV = 4,
    DIV = 8,
    MUL = 16,
    SMUL = 48,
    NOP = {7{1'b1}}
} operation;

typedef enum logic [6:0] {
    INT8 = 0,
    UINT8 = 1,
    INT16 = 2,
    UINT16 = 3,
    INT32 = 4,
    UINT32 = 5,
    NDT = {7{1'b1}}
} dtype;

typedef struct packed {
    logic   [31 : 0]    width;
    logic   [31 : 0]    height;
    dtype               dtype;
    logic               valid;
    logic               in_mem;
} register_file_line;

typedef enum logic [2:0] {
    DEFINE = 3'd0,
    LOAD = 3'd1,
    STORE = 3'd2,
    VV = 3'd4,
    VS = 3'd5,
    NF3 = {3{1'b1}}
} funct3_op;

endpackage