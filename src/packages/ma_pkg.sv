package ma_pkg;

typedef enum logic [6:0] {
    ADD = 1,
    SUB = 2,
    CNV = 4,
    NEWTON=7,
    DIV = 8,
    SLL = 9, // shift left logic
    SRL = 10, // shift right logic
    SRA = 11, // shift right arithmetic
    FFT = 12,
    IFFT = 13,
    MUL = 16,
    SMUL = 48,
    BC = 64, // broadcast
    NOP = {7{1'b1}}
} operation_t;

typedef enum logic [3:0] {
    V_ADD,
    V_SUB,
    V_SLL,
    V_SRL,
    V_SRA,
    // V_DIV, - to much for fpga
    V_MUL,
    V_NEWTON, // TODO
    V_NOP
} vectorial_operation_t;

typedef enum logic [6:0] {
    INT8 = 0,
    UINT8 = 1,
    INT16 = 2,
    UINT16 = 3,
    INT32 = 4,
    UINT32 = 5,
    NDT = {7{1'b1}}
} dtype_t;

typedef enum logic [6:0] {
    RECT, 
    ROW, 
    COL, 
    MD, 
    SD, 
    TRECT
} organization_t;
 
typedef struct packed {
    // matrix information
    logic           [31 : 0]    width;
    logic           [31 : 0]    height;
    dtype_t                     dtype;
    // prf information
    logic           [31 : 0]    prf_x;
    logic           [31 : 0]    prf_y;
    organization_t              prf_org;
    // flags
    logic                       valid;  // if set dtype and w&h
    logic                       prf_valid; // if prf data devided
    logic                       in_mem; // if data loaded in memory
} register_file_line_t;

typedef enum logic [2:0] {
    DEFINE,
    DEFINE_POLY,
    LOAD,
    STORE,
    VV,
    VS,
    NF3 = {3{1'b1}}
} funct3_op_t;

endpackage