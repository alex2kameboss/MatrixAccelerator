`timescale 1ns/1ns

module tb_shifter();

localparam BIT_WIDTH        = 1;
localparam DATA_WIDTH       = 32;
localparam SHIFTER_WIDTH    = 5;

// localparam BIT_WIDTH        = 2;
// localparam DATA_WIDTH       = 16;
// localparam SHIFTER_WIDTH    = 4;

logic   signed  [DATA_WIDTH * BIT_WIDTH - 1 : 0]    data_i, data_right, data_left, result;
logic                    [SHIFTER_WIDTH - 1 : 0]    shift_amt;
logic                                               is_signed;

initial begin
    is_signed = 1'b0;
    data_i = 32'hdeadbeef;
    
    for ( shift_amt = 0; ~&shift_amt; shift_amt = shift_amt + 1 ) begin
        #1;
    
        // left shift
        result = data_i << (shift_amt * BIT_WIDTH);
        assert( data_left == result ) else $error("Invalid left logic shift; input: %h, output: %h, expected: %h, shift: %d", data_i, data_left, result, shift_amt);
    
        // right shift
        result = data_i >> (shift_amt * BIT_WIDTH);
        assert( data_right == result ) else $error("Invalid right logic shift; input: %h, output: %h, expected: %h, shift: %d", data_i, data_right, result, shift_amt);
    end

    is_signed = 1'b1;

    for ( shift_amt = 0; ~&shift_amt; shift_amt = shift_amt + 1 ) begin
        #1;
    
        // right shift
        result = data_i >>> (shift_amt * BIT_WIDTH);
        assert( data_right == result ) else $error("Invalid right arithmetic shift; input: %h, output: %h, expected: %h, shift: %d", data_i, data_right, result, shift_amt);
    end

    shift_amt = {SHIFTER_WIDTH{1'b1}};

    #1;
    // right shift
    result = data_i >>> (shift_amt * BIT_WIDTH);
    assert( data_right == result ) else $error("Invalid right arithmetic shift; input: %h, output: %h, expected: %h, shift: %d", data_i, data_right, result, shift_amt);

    // test logic shift
    is_signed = 1'b0;
    #1;

    // left shift
    result = data_i << (shift_amt * BIT_WIDTH);
    assert( data_left == result ) else $error("Invalid left logic shift; input: %h, output: %h, expected: %h, shift: %d", data_i, data_left, result, shift_amt);

    // right shift
    result = data_i >> (shift_amt * BIT_WIDTH);
    assert( data_right == result ) else $error("Invalid right logic shift; input: %h, output: %h, expected: %h, shift: %d", data_i, data_right, result, shift_amt);

    $finish();
end

right_shifter #(
    .BIT_WIDTH      ( BIT_WIDTH     ),
    .DATA_WIDTH     ( DATA_WIDTH    ),
    .SHIFTER_WIDTH  ( SHIFTER_WIDTH )
) i_right_shifter_dut (
    .is_signed  ( is_signed ),
    .data_i     ( data_i    ),
    .shifter_i  ( shift_amt ),
    .data_o     ( data_right) 
);

left_shifter #(
    .BIT_WIDTH      ( BIT_WIDTH     ),
    .DATA_WIDTH     ( DATA_WIDTH    ),
    .SHIFTER_WIDTH  ( SHIFTER_WIDTH )
) i_left_shifter_dut (
    .data_i     ( data_i    ),
    .shifter_i  ( shift_amt ),
    .data_o     ( data_left ) 
);

endmodule