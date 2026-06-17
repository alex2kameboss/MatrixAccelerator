module ma_control_unit #(
    parameter ADDR_WIDTH        =   32   ,
    parameter REGISTER_NUMBERS  =   32  
) (
    // generic signals
    input   logic                                                               clk             ,
    input   logic                                                               rst_n           ,
    // internal interfaces
    ma_config_bus.control                                                       config_intf     ,
    ma_rsp_intf.control                                                         rsp_intf        ,
    // signals from CPU interface                               
// communication signals                            
    input   logic                                                               valid           ,
    output  logic                                                               ready           ,
// control signal                           
    input   ma_pkg::funct3_op_t                                                 funct3          ,
    input   ma_pkg::operation_t                                                 op              ,
    input   logic                           [ADDR_WIDTH - 1 : 0]                addr            ,
    input   logic                           [ADDR_WIDTH - 1 : 0]                scalar          ,
    input   logic                           [$clog2(REGISTER_NUMBERS) - 1 : 0]  rd              ,
    input   logic                           [$clog2(REGISTER_NUMBERS) - 1 : 0]  rs1             ,
    input   logic                           [$clog2(REGISTER_NUMBERS) - 1 : 0]  rs2             ,
    input   logic                           [ADDR_WIDTH - 1 : 0]                reg1            ,
    input   logic                           [ADDR_WIDTH - 1 : 0]                reg2            ,
    input   logic                           [6 : 0]                             funct7                    
);

// Local Parameters Definition  ------------------------------------------------------------------------------



// Wires Definition ------------------------------------------------------------------------------------------
ma_pkg::register_file_line_t  rft [REGISTER_NUMBERS - 1 : 0];

int rft_i;

ma_intf_pkg::unit_id_t dst_unit;
ma_intf_pkg::internal_op_t internal_op;

logic   define_operation;


// Combinatorial Logic ---------------------------------------------------------------------------------------
always_comb begin
    dst_unit = ma_intf_pkg::NONE_MODULE;
    internal_op = ma_intf_pkg::NOP;
    if ( funct3 == ma_pkg::LOAD ) begin
        dst_unit = ma_intf_pkg::DMA_UNIT;
        internal_op = ma_intf_pkg::LOAD;
    end else if ( funct3 == ma_pkg::STORE ) begin
        dst_unit = ma_intf_pkg::DMA_UNIT;
        internal_op = ma_intf_pkg::STORE;
    end else if ( op == ma_pkg::NEWTON ) begin
        dst_unit = ma_intf_pkg::NEWTON_UNIT;
        internal_op = funct3 == ma_pkg::VS ? ma_intf_pkg::NEWTON_VS : ma_intf_pkg::NEWTON_VV;
    end else if ( funct3 == ma_pkg::VS ) begin
        dst_unit = ma_intf_pkg::VECTORIAL_UNIT;
        case( op )
            ma_pkg::ADD : internal_op = ma_intf_pkg::ADD_VS;
            ma_pkg::SUB : internal_op = ma_intf_pkg::SUB_VS;
            ma_pkg::DIV : internal_op = ma_intf_pkg::DIV_VS;
            ma_pkg::SLL : internal_op = ma_intf_pkg::SLL_VS;
            ma_pkg::SRL : internal_op = ma_intf_pkg::SRL_VS;
            ma_pkg::SRA : internal_op = ma_intf_pkg::SRA_VS;
            ma_pkg::MUL : internal_op = ma_intf_pkg::MUL_VS;
            default     : internal_op = ma_intf_pkg::NOP;
        endcase
    end else if ( funct3 == ma_pkg::VV ) begin
        case( op )
            ma_pkg::ADD : begin 
                internal_op = ma_intf_pkg::ADD_VV;
                dst_unit = ma_intf_pkg::VECTORIAL_UNIT;
            end
            ma_pkg::SUB : begin 
                internal_op = ma_intf_pkg::SUB_VV;
                dst_unit = ma_intf_pkg::VECTORIAL_UNIT;
            end
            ma_pkg::DIV : begin 
                internal_op = ma_intf_pkg::DIV_VV;
                dst_unit = ma_intf_pkg::VECTORIAL_UNIT;
            end
            ma_pkg::SMUL : begin 
                internal_op = ma_intf_pkg::SMUL_VV;
                dst_unit = ma_intf_pkg::VECTORIAL_UNIT;
            end
            ma_pkg::MUL : begin 
                internal_op = ma_intf_pkg::MUL_VV;
                dst_unit = ma_intf_pkg::MATRIX_UNIT;
            end
            ma_pkg::CNV : begin 
                internal_op = ma_intf_pkg::CNV_VV;
                dst_unit = ma_intf_pkg::CNV_UNIT;
            end
            ma_pkg::BC : begin 
                internal_op = ma_intf_pkg::BROADCAST;
                dst_unit = ma_intf_pkg::VECTORIAL_UNIT;
            end
            ma_pkg::FFT : begin 
                internal_op = ma_intf_pkg::FFT;
                dst_unit = ma_intf_pkg::FFT_UNIT;
            end
            ma_pkg::IFFT : begin 
                internal_op = ma_intf_pkg::IFFT;
                dst_unit = ma_intf_pkg::FFT_UNIT;
            end
            default     : begin 
                internal_op = ma_intf_pkg::BROADCAST;
                dst_unit = ma_intf_pkg::NONE_MODULE;
            end
        endcase
    end
end


// Sequential Logic ------------------------------------------------------------------------------------------
always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin
        for ( rft_i = 0; rft_i < REGISTER_NUMBERS; rft_i = rft_i + 1 ) begin
            rft[rft_i]  <= 'd0;
        end
    end else if ( valid & ready & funct3 == ma_pkg::DEFINE ) begin
        rft[rd].height      <= reg1[31 : 0];
        rft[rd].width       <= reg2[31 : 0];
        rft[rd].dtype       <= ma_pkg::dtype_t'(funct7);
        rft[rd].valid       <= 1'b1;
    end else if ( valid & ready & funct3 == ma_pkg::DEFINE_POLY ) begin
        rft[rd].prf_x       <= reg1[31 : 0];
        rft[rd].prf_y       <= reg2[31 : 0];
        rft[rd].prf_org     <= ma_pkg::organization_t'(funct7);
        rft[rd].prf_valid   <= 1'b1;
    end else if ( valid & ready & (funct3 == ma_pkg::LOAD | funct3 == ma_pkg::VV | funct3 == ma_pkg::VS ) ) begin
        rft[rd].in_mem  <= 1'b1;
    end

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                           define_operation <= 'd0;    else
                                            define_operation <= funct3 == ma_pkg::DEFINE | funct3 == ma_pkg::DEFINE_POLY;

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n )                           ready <= 1'b1;              else
    if ( valid & ready )                    ready <= 1'b0;              else
    if ( rsp_intf.done | define_operation ) ready <= 1'b1;              

always_ff @( posedge clk, negedge rst_n )
    if ( ~rst_n ) begin 
        config_intf.dst_unit    <= ma_intf_pkg::NONE_MODULE;
        config_intf.internal_op <= ma_intf_pkg::NOP;
        config_intf.op          <= ma_pkg::NOP;
        config_intf.rs1         <= 'd0;
        config_intf.rs2         <= 'd0;
        config_intf.rd          <= 'd0;
        config_intf.start       <= 'd0;
        config_intf.scalar      <= 'd0;
    end else if ( valid & ready & dst_unit != ma_intf_pkg::NONE_MODULE & internal_op != ma_intf_pkg::NOP ) begin
        config_intf.dst_unit    <= dst_unit;
        config_intf.internal_op <= internal_op;
        config_intf.op          <= op;
        config_intf.rs1         <= rft[rs1];
        config_intf.rs2         <= rft[rs2];
        config_intf.rd          <= rft[rd];
        config_intf.start       <= 'd1;
        config_intf.scalar      <= dst_unit == ma_intf_pkg::DMA_UNIT ? addr : scalar;
    end else if ( config_intf.start ) begin 
        config_intf.start <= 'd0;
    end else if ( rsp_intf.done ) begin
        config_intf.dst_unit    <= ma_intf_pkg::NONE_MODULE;
        config_intf.internal_op <= ma_intf_pkg::NOP;
        config_intf.op          <= ma_pkg::NOP;
        config_intf.rs1         <= 'd0;
        config_intf.rs2         <= 'd0;
        config_intf.rd          <= 'd0;
        config_intf.start       <= 'd0;
        config_intf.scalar      <= 'd0;
    end      


// Modules Instances -----------------------------------------------------------------------------------------

endmodule