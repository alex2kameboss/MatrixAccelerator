module opcode_decoder (
    input           [6 : 0]     opcode      ,
    input           [2 : 0]     funct3      ,
    output  logic               arth_data   ,
    output  logic               define      ,
    output  logic               ld_st       ,
    output  logic               scalar_op   ,
    output  logic               error       
);

always_comb begin
    if ( opcode == 6'h2b )
        case (funct3)
            3'd0 : begin // define register
                arth_data   = 1'b0;
                define      = 1'b1;
                ld_st       = 1'b0;
                scalar_op   = 1'b0;
                error       = 1'b0;
            end
            3'd1 : begin // load
                arth_data   = 1'b0;
                define      = 1'b0;
                ld_st       = 1'b1;
                scalar_op   = 1'b0;
                error       = 1'b0;
            end
            3'd2 : begin // store
                arth_data   = 1'b0;
                define      = 1'b0;
                ld_st       = 1'b0;
                scalar_op   = 1'b0;
                error       = 1'b0;
            end
            3'd4 : begin // vector-vector operation
                arth_data   = 1'b1;
                define      = 1'b0;
                ld_st       = 1'b0;
                scalar_op   = 1'b0;
                error       = 1'b0;
            end
            3'd5 : begin // vector-scalar operation
                arth_data   = 1'b0;
                define      = 1'b0;
                ld_st       = 1'b0;
                scalar_op   = 1'b1;
                error       = 1'b0;
            end
            default: begin
                arth_data   = 1'b0;
                define      = 1'b0;
                ld_st       = 1'b0;
                scalar_op   = 1'b0;
                error       = 1'b1;
            end 
        endcase
    else begin
        arth_data   = 1'b0;
        define      = 1'b0;
        ld_st       = 1'b0;
        scalar_op   = 1'b0;
        error       = 1'b1;
    end
end

endmodule;