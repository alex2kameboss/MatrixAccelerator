module axi_mem_monitor #(
    parameter MEM_SIZE      = 1024 * 1024   ,
    parameter DATA_WIDTH    = 128           ,
    parameter ADDR_WIDTH    = 32            
) (
    input                   aclk                        ,
    input                   arst_n                      ,
    input           [7 : 0] mem     [MEM_SIZE - 1 : 0]  ,
    AXI_BUS.Monitor         axi                         
);

axi_mem_ch_monitor #(
    .MEM_SIZE   ( MEM_SIZE   ),
    .DATA_WIDTH ( DATA_WIDTH ),
    .ADDR_WIDTH ( ADDR_WIDTH )
) i_write (
    .aclk       ( aclk          ),
    .arst_n     ( arst_n        ),
    .mem        ( mem           ),
    .ctrl_valid ( axi.aw_valid  ),
    .ctrl_ready ( axi.aw_ready  ),
    .addr       ( axi.aw_addr   ),
    .ch_valid   ( axi.w_valid   ),
    .ch_ready   ( axi.w_ready   ),
    .data       ( axi.w_data    )  
);

axi_mem_ch_monitor #(
    .MEM_SIZE   ( MEM_SIZE   ),
    .DATA_WIDTH ( DATA_WIDTH ),
    .ADDR_WIDTH ( ADDR_WIDTH )      
) i_read (
    .aclk       ( aclk          ),
    .arst_n     ( arst_n        ),
    .mem        ( mem           ),
    .ctrl_valid ( axi.ar_valid  ),
    .ctrl_ready ( axi.ar_ready  ),
    .addr       ( axi.ar_addr   ),
    .ch_valid   ( axi.r_valid   ),
    .ch_ready   ( axi.r_ready   ),
    .data       ( axi.r_data    )  
);

endmodule

module axi_mem_ch_monitor #(
    parameter MEM_SIZE      = 1024 * 1024   ,
    parameter DATA_WIDTH    = 128           ,
    parameter ADDR_WIDTH    = 32            
) (
    input                           aclk                            ,
    input                           arst_n                          ,
    input   [7 : 0]                 mem         [MEM_SIZE - 1 : 0]  ,
    input                           ctrl_valid                      ,
    input                           ctrl_ready                      ,
    input   [ADDR_WIDTH - 1 : 0]    addr                            ,
    input                           ch_valid                        ,
    input                           ch_ready                        ,
    input   [DATA_WIDTH - 1 : 0]    data                              
);

localparam DATA_BYTES = DATA_WIDTH / 8;

logic [ADDR_WIDTH - 1 : 0]  addr_cache;
always_ff @(posedge aclk)
    if ( ctrl_valid & ctrl_ready )  addr_cache <= addr;     else
    if ( ch_valid & ch_ready ) begin
        assert property(data == { >> {mem[addr_cache +: DATA_BYTES]}}) else $display("%d, %h, %h", addr_cache, data, { >> {mem[addr_cache +: DATA_BYTES]}});
        addr_cache <= addr_cache + DATA_BYTES;
    end

endmodule