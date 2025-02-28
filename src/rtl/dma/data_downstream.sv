// memory -> dma

module data_upstream #(
    parameter   IN_WIDTH    =   256 ,
    parameter   OUT_WIDTH   =   64  
) (
    input   logic                       clk         ,
    input   logic                       rst_n       ,
    input   logic                       en          ,
    input   logic                       start       ,
    input   logic   [IN_WIDTH - 1 : 0]  in_data     ,
    input   logic                       valid_in    ,
    output  logic                       ready_in    ,
    output  logic   [OUT_WIDTH - 1 : 0] out_data    ,
    output  logic                       valid_out   ,
    input   logic                       ready_out   
);
    
localparam CNT_LIMIT    =   OUT_WIDTH / IN_WIDTH;
localparam CNT_BIT      =   $clog2(CNT_LIMIT);

logic [CNT_BIT - 1 : 0] cnt;
logic [IN_WIDTH - 1 : 0] buffer;
logic in_valid, valid_data;

assign in_valid = ready_in & valid_in;
assign out_valid = ready_out & valid_out;

always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )                       valid_data <= 'd0;      else
    if ( en ) begin
        if ( start | ~|cnt)             valid_data <= valid_in;
    end

always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )                       buffer <= 'd0;      else
    if ( en ) begin
        if ( in_valid )                 buffer <= in_data;
    end

assign out_data = buffer[(cnt + 1) * OUT_WIDTH -: OUT_WIDTH];
assign ready_in = en & (start | ~|cnt);
assign valid_out = en & valid_data;

always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )                       cnt <= 'd0;         else
    if ( en ) begin
        if ( start )                    cnt <= 'd0;         else
        if ( out_valid )                cnt <= cnt + 1'b1; 
    end                      


endmodule