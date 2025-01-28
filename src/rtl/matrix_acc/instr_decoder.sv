module instr_decoder (
    input   logic   [2 : 0]     funct3      ,
    output  logic               arth_data   ,
    output  logic               define      ,
    output  logic               define_prf  ,
    output  logic               ld_st       ,
    output  logic               scalar_op   ,
    output  logic               error       
);

ma_pkg::funct3_op_t funct3_enum;

assign funct3_enum = ma_pkg::funct3_op_t'(funct3);

always_comb begin
    case (funct3_enum)
        ma_pkg::DEFINE : begin // define register
            arth_data   = 1'b0;
            define      = 1'b1;
            define_prf  = 1'b0;
            ld_st       = 1'b0;
            scalar_op   = 1'b0;
            error       = 1'b0;
        end
        ma_pkg::DEFINE_POLY: begin // define prf
            arth_data   = 1'b0;
            define      = 1'b1;
            define_prf  = 1'b1;
            ld_st       = 1'b0;
            scalar_op   = 1'b0;
            error       = 1'b0;
        end
        ma_pkg::LOAD : begin // load
            arth_data   = 1'b0;
            define      = 1'b0;
            define_prf  = 1'b0;
            ld_st       = 1'b1;
            scalar_op   = 1'b0;
            error       = 1'b0;
        end
        ma_pkg::STORE : begin // store
            arth_data   = 1'b0;
            define      = 1'b0;
            define_prf  = 1'b0;
            ld_st       = 1'b0;
            scalar_op   = 1'b0;
            error       = 1'b0;
        end
        ma_pkg::VV : begin // vector-vector operation
            arth_data   = 1'b1;
            define      = 1'b0;
            define_prf  = 1'b0;
            ld_st       = 1'b0;
            scalar_op   = 1'b0;
            error       = 1'b0;
        end
        ma_pkg::VS : begin // vector-scalar operation
            arth_data   = 1'b1;
            define      = 1'b0;
            define_prf  = 1'b0;
            ld_st       = 1'b0;
            scalar_op   = 1'b1;
            error       = 1'b0;
        end
        default: begin
            arth_data   = 1'b0;
            define      = 1'b0;
            define_prf  = 1'b0;
            ld_st       = 1'b0;
            scalar_op   = 1'b0;
            error       = 1'b1;
        end 
    endcase
end

endmodule;