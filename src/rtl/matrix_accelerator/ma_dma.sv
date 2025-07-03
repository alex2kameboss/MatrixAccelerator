module ma_dma (
    ma_config_bus.accelerator   config_intf ,
    ma_data_bus.accelerator     data_intf   ,
    ma_rsp_intf.accelerator     rsp_intf    ,
    // axi interface
    input   logic               aclk        ,
    input   logic               arst_n      ,
    AXI_BUS.Master              axi         
);

// Local Parameters Definition  ------------------------------------------------------------------------------



// Wires Definition ------------------------------------------------------------------------------------------
logic   en;

logic   [data_intf.PRF_LOG_N - 1 : 0]    dma_i_out;
logic   [data_intf.PRF_LOG_M - 1 : 0]    dma_j_out;

// write chanel
logic                                   dma_write_valid ;
logic                                   dma_write_ready ;
logic   [axi.AXI_ADDR_WIDTH - 1 : 0]    dma_write_addr  ;
logic   [axi.AXI_ADDR_WIDTH - 1 : 0]    dma_write_len   ;
logic                                   dma_write_done  ;
// read chanel          
logic                                   dma_read_valid  ;
logic                                   dma_read_ready  ;
logic   [axi.AXI_ADDR_WIDTH - 1 : 0]    dma_read_addr   ;
logic   [axi.AXI_ADDR_WIDTH - 1 : 0]    dma_read_len    ;
logic                                   dma_read_done   ;
// data chanel
logic   [data_intf.DATA_WIDTH - 1 : 0]  dma_read_data       ;          
logic                                   dma_read_data_valid ;          
logic                                   dma_read_data_ready ;       
logic   [data_intf.DATA_WIDTH - 1 : 0]  dma_write_data      ;
logic[data_intf.DATA_WIDTH / 8 - 1 : 0] dma_write_mask      ;         
logic                                   dma_write_data_valid;          
logic                                   dma_write_data_ready;   

logic   dma_write_done_edge, dma_read_done_edge;

logic                                   load, store;
logic   [2 : 0]                         bytes_len  ;
logic   [axi.AXI_ADDR_WIDTH - 1 : 0]    dma_len    ;

logic   start_delayed;
logic   dma_addr_en, dma_done, dma_addr_gen_en;
logic   dma_read_incr, dma_write_incr, dma_addr_gen_incr;
logic   start_addr_gen_delayed, dma_addr_gen_done_delayed;

AXI_BUS #(
    .AXI_ADDR_WIDTH ( axi.AXI_ADDR_WIDTH    ),
    .AXI_DATA_WIDTH ( data_intf.DATA_WIDTH  ),
    .AXI_ID_WIDTH   ( axi.AXI_ID_WIDTH      ),
    .AXI_USER_WIDTH ( axi.AXI_USER_WIDTH    )
) axi_n_lanes();


// Combinatorial Logic ---------------------------------------------------------------------------------------
assign data_intf.unit_id = ma_intf_pkg::DMA_UNIT;
assign rsp_intf.unit_id = data_intf.unit_id;
assign en = config_intf.dst_unit == data_intf.unit_id;
assign data_intf.op1.scheme = prf_dtypes::ROW;
assign data_intf.op1.i = dma_i_out;
assign data_intf.op1.j = dma_j_out;
//assign data_intf.op1.valid = store;
assign dma_write_data = data_intf.op1_data;
assign data_intf.op2 = 'd0;
assign data_intf.rez.scheme = prf_dtypes::ROW;
assign data_intf.rez.lane_valid = {data_intf.PRF_N_LANES{1'b1}};
assign data_intf.rez.i = dma_i_out;
assign data_intf.rez.j = dma_j_out;
assign data_intf.rez.valid = load & dma_read_incr;
assign data_intf.rez_data = dma_read_data;

assign rsp_intf.done = en & (dma_write_done_edge & store | dma_read_done & load & dma_done);

assign load = config_intf.internal_op == ma_intf_pkg::LOAD;
assign store = config_intf.internal_op == ma_intf_pkg::STORE;

always_comb begin
    case (config_intf.rd.dtype)
        ma_pkg::INT16   :   bytes_len = 'd2;
        ma_pkg::UINT16  :   bytes_len = 'd2;
        ma_pkg::INT32   :   bytes_len = 'd4;
        ma_pkg::UINT32  :   bytes_len = 'd4;
        default         :   bytes_len = 'd1;
    endcase
end

assign dma_len = config_intf.rd.width * config_intf.rd.height * bytes_len;
assign dma_addr_gen_en = config_intf.start | dma_addr_en;
assign dma_addr_gen_incr = load & dma_read_incr | store & dma_write_incr;
assign dma_read_incr = dma_read_data_valid & dma_read_data_ready;
assign dma_write_incr = dma_write_data_valid & dma_write_data_ready | config_intf.start;
assign dma_read_data_ready = load;


// Sequential Logic ------------------------------------------------------------------------------------------
always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n ) begin
        dma_write_valid <= 'd0;
        dma_write_addr  <= 'd0;
        dma_write_len   <= 'd0;
    end else if ( en & store & config_intf.start ) begin
        dma_write_valid <= 'd1;
        dma_write_addr  <= config_intf.scalar;
        dma_write_len   <= dma_len;
    end else if ( dma_write_valid & dma_write_ready ) begin
        dma_write_valid <= 'd0;
        dma_write_addr  <= 'd0;
        dma_write_len   <= 'd0;
    end

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n ) begin
        dma_read_valid <= 'd0;
        dma_read_addr  <= 'd0;
        dma_read_len   <= 'd0;
    end else if ( en & load & config_intf.start ) begin
        dma_read_valid <= 'd1;
        dma_read_addr  <= config_intf.scalar;
        dma_read_len   <= dma_len;
    end else if ( dma_read_valid & dma_read_ready ) begin
        dma_read_valid <= 'd0;
        dma_read_addr  <= 'd0;
        dma_read_len   <= 'd0;
    end

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )                 dma_addr_en <= 'd0;                 else
    if ( load | store & config_intf.start ) dma_addr_en <= 'd1;                 else
    if ( dma_done )                         dma_addr_en <= 'd0;   

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )                 dma_write_data_valid <= 'd0;        else
    if ( dma_done )                         dma_write_data_valid <= 'd0;        else
    if ( store & en ) begin
        if ( data_intf.op1.valid )          dma_write_data_valid <= 'd1;        else
        if ( dma_write_data_ready )         dma_write_data_valid <= 'd0;        
    end   

always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )                 data_intf.op1.valid <= 'd0;        else
    if ( dma_done )                         data_intf.op1.valid <= 'd0;        else
    if ( store & en )                       data_intf.op1.valid <= dma_write_incr;

/* TODO: remove */ always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )                 start_addr_gen_delayed <= 'd0;      else
    if ( en )                               start_addr_gen_delayed <= config_intf.start;

/* TODO: remove */ always_ff @( posedge data_intf.clk, negedge data_intf.rst_n )
    if ( ~data_intf.rst_n )                 dma_addr_gen_done_delayed <= 'd0;   else
    if ( en )                               dma_addr_gen_done_delayed <= dma_done;


// Modules Instances -----------------------------------------------------------------------------------------
axi_dw_converter_intf #(
    .AXI_ID_WIDTH           ( axi.AXI_ID_WIDTH      ),
    .AXI_ADDR_WIDTH         ( axi.AXI_ADDR_WIDTH    ),
    .AXI_SLV_PORT_DATA_WIDTH( data_intf.DATA_WIDTH  ),
    .AXI_MST_PORT_DATA_WIDTH( axi.AXI_DATA_WIDTH    ),
    .AXI_USER_WIDTH         ( axi.AXI_USER_WIDTH    ),
    .AXI_MAX_READS          ( 1                     )
) i_axi_dma_dw (
    .clk_i  ( aclk          ),
    .rst_ni ( arst_n        ),
    .slv    ( axi_n_lanes   ),
    .mst    ( axi           )
);

dma #(
    .ADDR_WIDTH ( axi.AXI_ADDR_WIDTH    ),
    .DATA_WIDTH ( data_intf.DATA_WIDTH  ) 
) i_dma (
    .clk                ( data_intf.clk         ),
    .rst_n              ( data_intf.rst_n       ),
    // write chanel
    .write_valid_i      ( dma_write_valid       ),
    .write_ready_o      ( dma_write_ready       ),
    .write_addr_i       ( dma_write_addr        ),
    .write_len_i        ( dma_write_len         ),
    .write_done_o       ( dma_write_done        ),
    // read chanel
    .read_valid_i       ( dma_read_valid        ),
    .read_ready_o       ( dma_read_ready        ),
    .read_addr_i        ( dma_read_addr         ),
    .read_len_i         ( dma_read_len          ),
    .read_done_o        ( dma_read_done         ),
    // data fifos
    // write fifo
    .write_data_i       ( dma_write_data        ),
    .write_data_mask_i  ( dma_write_mask        ),
    .write_data_valid_i ( dma_write_data_valid  ),
    .write_data_ready_o ( dma_write_data_ready  ),
    // read fifo
    .read_data_o        ( dma_read_data         ),
    .read_data_valid_o  ( dma_read_data_valid   ),
    .read_data_ready_i  ( dma_read_data_ready   ),
    // axi interface
    .aclk               ( aclk                  ),
    .arst_n             ( arst_n                ),
    .axi                ( axi_n_lanes           ) 
);

prf_addr_gen_seq #(
    .PRF_N_LANES    ( data_intf.PRF_N_LANES ),
    .PRF_LOG_N      ( data_intf.PRF_LOG_N   ),
    .PRF_LOG_M      ( data_intf.PRF_LOG_M   )
) i_dma_addr_gen (
    .clk     ( data_intf.clk        ),
    .rst_n   ( data_intf.rst_n      ),
    .start   ( config_intf.start    ),
    .en      ( dma_addr_gen_en      ),
    .incr    ( dma_addr_gen_incr    ),
    .r       ( config_intf.rd       ),
    .i_out   ( dma_i_out            ),
    .j_out   ( dma_j_out            ),
    .done    ( dma_done             )
);

posedge_detector i_write_done (
    .clk    ( data_intf.clk         ),
    .rst_n  ( data_intf.rst_n       ),
    .signal ( dma_write_done        ),
    .flag   ( dma_write_done_edge   ) 
);

posedge_detector i_read_done (
    .clk    ( data_intf.clk         ),
    .rst_n  ( data_intf.rst_n       ),
    .signal ( dma_read_done         ),
    .flag   ( dma_read_done_edge    ) 
);

prf_mask_gen #(
    .PRF_N_LANES    ( data_intf.PRF_N_LANES ),
    .PRF_LOG_N      ( data_intf.PRF_LOG_N   ),
    .PRF_LOG_M      ( data_intf.PRF_LOG_M   ),
    .SRAM_WIDTH     ( data_intf.SRAM_WIDTH  )
) i_write_mask_generator (
    .clk    ( data_intf.clk     ),
    .rst_n  ( data_intf.rst_n   ),
    .en     ( dma_addr_gen_en   ),
    .start  ( config_intf.start ),
    .incr   ( dma_write_incr    ),
    .r      ( config_intf.rd    ),
    .mask   ( dma_write_mask    )
);

endmodule