module FFT256 #(
    parameter  DATA_WIDTH = 16,
    localparam CMPL_DATA_WIDTH = 2 * DATA_WIDTH
    // parameter TWIDDLE_WIDTH = 24
) (
    // Clock and control signals
    input  logic                           clk,
    input  logic                           enable,
    input  logic                           rst_n,
    input  logic [1:0]                     FFT_type,    // FFT stage selector
    
    // Input complex data array (16 samples)
    input  logic [CMPL_DATA_WIDTH-1:0]     z[0:15],
    
    // Output complex data array (16 samples)
    output logic [CMPL_DATA_WIDTH-1:0]     Z[0:15]
);
    // Local parameters for data width calculations
    // Note: CMPL_DATA_WIDTH moved to parameter list for port declaration usage
    localparam DATA_WIDTH_FFT16_1    = DATA_WIDTH + 5;     // First FFT16 output width
    localparam DATA_WIDTH_FFT16_2    = DATA_WIDTH + 9;     // Second FFT16 output width
    localparam DATA_CONV             = DATA_WIDTH + 8;     // Convergent rounding width
    localparam CMPL_DATA_WIDTH_FFT16_1 = 2 * DATA_WIDTH_FFT16_1;
    
    // Pipeline stage signals
    logic [CMPL_DATA_WIDTH-1:0]                  stage_transpose1[0:15];
    
    // First FFT16 stage signals
    logic signed [DATA_WIDTH-1:0]                z_r[0:15];
    logic signed [DATA_WIDTH-1:0]                z_i[0:15];
    logic signed [DATA_WIDTH_FFT16_1-1:0]        stage_FFT16_1_r[0:15];
    logic signed [DATA_WIDTH_FFT16_1-1:0]        stage_FFT16_1_i[0:15];
    
    // First multiplication stage signals
    logic signed [DATA_WIDTH_FFT16_1-1:0]        stage_mult_1_r[0:15];
    logic signed [DATA_WIDTH_FFT16_1-1:0]        stage_mult_1_i[0:15];
    logic signed [17-1:0]                        c1[0:15];          
    logic signed [17-1:0]                        s1[0:15];          
    logic [15:0]                                 mult_one;
    logic [CMPL_DATA_WIDTH_FFT16_1-1:0]          stage_mult_1_z[0:15];
    
    // Second transpose stage signals
    logic [CMPL_DATA_WIDTH_FFT16_1-1:0]          stage_transpose2[0:15];
    logic signed [DATA_WIDTH_FFT16_1-1:0]        z2_r[0:15];
    logic signed [DATA_WIDTH_FFT16_1-1:0]        z2_i[0:15];
    
    // Second FFT16 stage signals
    logic signed [DATA_WIDTH_FFT16_2-1:0]        stage_FFT16_2_r[0:15];
    logic signed [DATA_WIDTH_FFT16_2-1:0]        stage_FFT16_2_i[0:15];
    
    // Rounding and output stage signals
    logic signed [DATA_WIDTH_FFT16_2-1:0]        stage_conv_2_r[0:15];
    logic signed [DATA_WIDTH_FFT16_2-1:0]        stage_conv_2_i[0:15];
    logic signed [DATA_WIDTH-1:0]                stage_round_2_r[0:15];
    logic signed [DATA_WIDTH-1:0]                stage_round_2_i[0:15];
    
    // Control and utility signals
    logic [3:0]                                  c16;
    genvar                                       k;
    int                                          i;
   
    // Counter for twiddle factor addressing (synchronized with pipeline)
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            c16 <= 4'sd10;
        end else begin
            if (enable) begin
                c16 <= c16 + 1;
            end
        end
    end
   
    // ========================================================================
    // STAGE 1: First Transpose (Input Matrix Transpose)
    // ========================================================================
    transpose_16 #(
        .N          (16),
        .DATA_WIDTH (CMPL_DATA_WIDTH),
        .DELAY      (4'b0)
    ) TRANSPOSE1 (
        .clk    (clk),
        .enable (enable),
        .rst_n  (rst_n),
        .in     (z),
        .out    (stage_transpose1)
    );

    // Split complex data into real and imaginary components
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_split_input
            always_comb begin
                z_r[k] = signed'(stage_transpose1[k][DATA_WIDTH-1:0]);
                z_i[k] = signed'(stage_transpose1[k][2*DATA_WIDTH-1:DATA_WIDTH]);
            end
        end
    endgenerate

    // ========================================================================
    // STAGE 2: First 16-Point FFT (Row Processing)
    // ========================================================================
    FFT16a #(
        .DATA_WIDTH     (DATA_WIDTH),
        .TWIDDLE_WIDTH  (24),
        .INCREASE_WIDTH (1)
    ) FFT16_1 (
        .clk      (clk),
        .enable   (enable),
        .FFT_type (FFT_type),
        .zr       (z_r),
        .zi       (z_i),
        .Zr       (stage_FFT16_1_r),
        .Zi       (stage_FFT16_1_i)
    );

    // ========================================================================
    // STAGE 3: Twiddle Factor Generation
    // ========================================================================
    twiddle_256 #(
        .N             (16),
        .TWIDDLE_WIDTH (17)
    ) TWIDDLE_256 (
        .clk      (clk),
        .enable   (enable),
        .addr     (c16),
        .c        (c1),
        .s        (s1),
        .mult_one (mult_one)
    );


    // ========================================================================
    // STAGE 4: First Complex Multiplication (Twiddle Factor Application)
    // ========================================================================
    column_multipliers_16 #(
        .DATA_WIDTH     (DATA_WIDTH_FFT16_1),
        .TWIDDLE_WIDTH  (17)
    ) MULT_CMPL1 (
        .clk      (clk),
        .enable   (enable),
        .mult_one (mult_one),
        .zr       (stage_FFT16_1_r),
        .zi       (stage_FFT16_1_i),
        .c        (c1),
        .s        (s1),
        .Zr       (stage_mult_1_r),
        .Zi       (stage_mult_1_i)
    );

    // Combine real and imaginary parts back into complex format
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_combine_mult1
            always_comb begin
                stage_mult_1_z[k] = {stage_mult_1_i[k], stage_mult_1_r[k]};
            end
        end
    endgenerate

    // ========================================================================
    // STAGE 5: Second Transpose (Column to Row conversion)
    // ========================================================================
    transpose_16 #(
        .N          (16),
        .DATA_WIDTH (CMPL_DATA_WIDTH_FFT16_1),
        .DELAY      (4'd14)
    ) TRANSPOSE2 (
        .clk    (clk),
        .enable (enable),
        .rst_n  (rst_n),
        .in     (stage_mult_1_z),
        .out    (stage_transpose2)
    );

    // Split transposed complex data for second FFT stage
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_split_transpose2
            always_ff @(posedge clk) begin
                z2_r[k] <= stage_transpose2[k][DATA_WIDTH_FFT16_1-1:0];
                z2_i[k] <= stage_transpose2[k][2*DATA_WIDTH_FFT16_1-1:DATA_WIDTH_FFT16_1];
            end
        end
    endgenerate

    // ========================================================================
    // STAGE 6: Second 16-Point FFT (Column Processing)
    // ========================================================================
    FFT16a #(
        .DATA_WIDTH     (DATA_WIDTH_FFT16_1),
        .TWIDDLE_WIDTH  (24),
        .INCREASE_WIDTH (0)                     // No additional width increase
    ) FFT16_2 (
        .clk      (clk),
        .enable   (enable),
        .FFT_type (FFT_type),
        .zr       (z2_r),
        .zi       (z2_i),
        .Zr       (stage_FFT16_2_r),
        .Zi       (stage_FFT16_2_i)
    );

    // ========================================================================
    // STAGE 7: Convergent Rounding (Round to original DATA_WIDTH)
    // ========================================================================
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_convergent_rounding
            always_ff @(posedge clk) begin
                // Convergent rounding for real part
                stage_conv_2_r[k] <= stage_FFT16_2_r[k][(DATA_CONV-1):0]
                                   + { {(DATA_WIDTH){1'b0}},
                                       stage_FFT16_2_r[k][(DATA_CONV-DATA_WIDTH)],
                                       {(DATA_CONV-DATA_WIDTH-1){!stage_FFT16_2_r[k][(DATA_CONV-DATA_WIDTH)]}}};
                
                // Convergent rounding for imaginary part
                stage_conv_2_i[k] <= stage_FFT16_2_i[k][(DATA_CONV-1):0]
                                   + { {(DATA_WIDTH){1'b0}},
                                       stage_FFT16_2_i[k][(DATA_CONV-DATA_WIDTH)],
                                       {(DATA_CONV-DATA_WIDTH-1){!stage_FFT16_2_i[k][(DATA_CONV-DATA_WIDTH)]}}};
            end
        end
    endgenerate
    
    // Extract rounded result to original data width
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_extract_rounded
            always_ff @(posedge clk) begin
                stage_round_2_r[k] <= stage_conv_2_r[k][(DATA_CONV-1):(DATA_CONV-DATA_WIDTH)];
                stage_round_2_i[k] <= stage_conv_2_i[k][(DATA_CONV-1):(DATA_CONV-DATA_WIDTH)];
            end
        end
    endgenerate

    // ========================================================================
    // STAGE 8: Output Generation
    // Combine real and imaginary parts into final complex output format
    // ========================================================================
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_output
            always_ff @(posedge clk) begin
                Z[k] <= {stage_round_2_i[k], stage_round_2_r[k]};
            end
        end
    endgenerate

    // ========================================================================
    // DEBUG SECTION 
    // Uncomment for detailed pipeline stage monitoring
    // ========================================================================
    /* -----\/----- EXCLUDED -----\/-----
    always @(posedge clk) begin
        $display("[%0t] Time", $time);
        for (i = 0; i < 16; i++) begin
            //$display("  transpose1[%0d] = (%0d, %0d)", i, z_r[i], z_i[i]);
            //$display("  fft1[%0d] = (%0d, %0d)", i, stage_FFT16_1_r[i], stage_FFT16_1_i[i]);
            //$display("  omega[%0d] = (%0d, %0d) %d", i, c1[i], s1[i], mult_one[i]);
            //$display("  mult[%0d] = (%0d, %0d)", i, stage_mult_1_r[i], stage_mult_1_i[i]);
            //$display("  transpose2[%0d] = (%0d, %0d)", i, z2_r[i], z2_i[i]);
            //$display("  fft2[%0d] = (%0d, %0d)", i, stage_FFT16_2_r[i], stage_FFT16_2_i[i]);
            $display("  round2[%0d] = (%0d, %0d)", i, stage_round_2_r[i], stage_round_2_i[i]);
        end
    end
    -----/\----- EXCLUDED -----/\----- */

endmodule


