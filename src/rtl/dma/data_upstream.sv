// dma -> memory

module data_upstream #(
    parameter   IN_WIDTH    =   64  ,
    parameter   OUT_WIDTH   =   256 
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
logic in_valid;

assign in_valid = valid_in & valid_out;

always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )                       out_data <= 'd0;    else
    if ( en ) begin
        if ( start )                    out_data <= 'd0;    else
        if ( in_valid )                 out_data[(cnt + 1) * IN_WIDTH -: IN_WIDTH] <= in_data;
    end

always_comb
    ready_in = 'd0;
    if ( en & ~start ) begin
        if ( valid_out )
            ready_in = ready_out;
        else
            ready_in = 'd1;
    end

always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )                       cnt <= 'd0;         else
    if ( en ) begin 
        if ( start )                    cnt <= 'd0;         else
        if ( in_valid )                 cnt <= cnt + 1'b1;                      
    end

always_ff @(posedge clk, negedge rst_n)
    if ( ~rst_n )                       valid_out <= 'd0;   else
    if ( en ) begin
        if ( in_valid & &cnt )          valid_out <= 'd1;   else
        if ( ready_out )                valid_out <= 'd0;   else
    end

endmodule