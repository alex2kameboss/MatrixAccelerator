module matrix_a_addr_gen #(
    parameter   SA_WIDTH            =   4   ,
    parameter   SA_HEIGHT           =   4   ,
    parameter   MEM_DATA_WIDTH      =   128 ,
    parameter   MEM_ADDR_WIDTH      =   16  ,
    parameter   REGISTER_NUMBERS    =   32  ,
    parameter   ADDR_WIDTH          =   32  
) (
    input   logic                                           clk     ,
    input   logic                                           rst_n   ,
    // matricex sizes
    input   logic               [ADDR_WIDTH - 1 : 0]        m       ,
    input   logic               [ADDR_WIDTH - 1 : 0]        n       ,
    input   logic               [ADDR_WIDTH - 1 : 0]        p       ,
    // out data
    output  logic               [MEM_ADDR_WIDTH - 1 : 0]    addr_a  ,
    output  logic                                           done    ,
    // control signals
    input   ma_pkg::dtype_t                                 dtype   ,
    input   logic                                           en       
);

localparam MEM_DATA_BYTES = MEM_DATA_WIDTH / 8;
localparam MEM_DATA_BYTES_CLOG2 = $clog2(MEM_DATA_BYTES);
localparam SA_HEIGHT_BITS = $clog2(SA_HEIGHT);

logic   [ADDR_WIDTH - 1 : 0]        x, y, x_next, y_next, x_limit_bytes, y_limit;
logic   [MEM_ADDR_WIDTH - 1 : 0]    addr_next, addr_xy;
logic   [MEM_ADDR_WIDTH - 1 : 0]    x_addr_step;
logic                               x_done, y_done;

logic   [SA_HEIGHT_BITS - 1 : 0]    y_cnt, y_cnt_next;
logic                               y_cnt_done;

logic [2 : 0] x_step;
always_comb begin
    case (dtype)
        ma_pkg::INT16   :   x_step = MEM_DATA_BYTES / 'd2;
        ma_pkg::UINT16  :   x_step = MEM_DATA_BYTES / 'd2;
        ma_pkg::INT32   :   x_step = MEM_DATA_BYTES / 'd4;
        ma_pkg::UINT32  :   x_step = MEM_DATA_BYTES / 'd4;
        default         :   x_step = MEM_DATA_BYTES / 'd1;
    endcase
end

always_comb begin
    case (dtype)
        ma_pkg::INT16   :   x_limit_bytes = n * 'd2;
        ma_pkg::UINT16  :   x_limit_bytes = n * 'd2;
        ma_pkg::INT32   :   x_limit_bytes = n * 'd4;
        ma_pkg::UINT32  :   x_limit_bytes = n * 'd4;
        default         :   x_limit_bytes = n * 'd1;
    endcase
end
assign x_addr_step = x_limit_bytes[ADDR_WIDTH + MEM_DATA_BYTES_CLOG2 - 1 : MEM_DATA_BYTES_CLOG2];
assign x_next = x + x_step;
assign y_next = y + SA_HEIGHT;
assign x_done = x_next >= n;
assign y_done = y_next >= m;
//assign done = x_done & y_done & en & y_cnt_done;

assign y_cnt_next = y_cnt + 1'b1;
assign y_cnt_done = &y_cnt & ~|y_cnt_next;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       done <= 'b0;                        else
    if ( done )                         done <= 'b0;                        else
    if ( x_done & y_done & en & y_cnt_done ) done <= 'b1;

always_comb begin
    if ( x_done & y_cnt_done )          addr_next = addr_a + 1'b1;          else
    if ( y_cnt_done )                   addr_next = addr_xy + 1'b1;         else
                                        addr_next = addr_a + x_addr_step;
end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       addr_a <= 'd0;                      else
    if ( done )                         addr_a <= 'd0;                      else
    if ( en )                           addr_a <= addr_next;                

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       addr_xy <= 'd0;                     else
    if ( done )                         addr_xy <= 'd0;                     else
    if ( x_done )                       addr_xy <= addr_next;               else
    if ( y_cnt_done )                   addr_xy <= addr_xy + 1'b1;
    
always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       x <= 'd0;                           else
    if ( done )                         x <= 'd0;                           else
    if ( x_done & y_cnt_done )          x <= 'd0;                           else
    if ( y_cnt_done )                   x <= x_next;                        

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       y <= 'd0;                           else
    if ( done )                         y <= 'd0;                           else
    if ( x_done & y_cnt_done )          y <= y_next;                        

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                       y_cnt <= 'd0;                       else
    if ( done )                         y_cnt <= 'd0;                       else
    if ( en )                           y_cnt <= y_cnt_next;

endmodule