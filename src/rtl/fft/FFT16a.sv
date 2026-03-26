module FFT16a #(
    parameter DATA_WIDTH     = 16,
    parameter TWIDDLE_WIDTH  = 24,
    parameter INCREASE_WIDTH = 1,
    localparam DATA_WIDTH_STAGE0 = DATA_WIDTH + INCREASE_WIDTH + 4  // Final output width
) (
    // Clock and control signals
    input  logic                              clk,
    input  logic                              enable,
    input  logic [1:0]                        FFT_type,
  
    // Input complex data arrays
    input  logic signed [DATA_WIDTH-1:0]      zr[0:15],
    input  logic signed [DATA_WIDTH-1:0]      zi[0:15],
  
    // Output complex data arrays (with progressive bit width increase)
    output logic signed [DATA_WIDTH_STAGE0-1:0] Zr[0:15],
    output logic signed [DATA_WIDTH_STAGE0-1:0] Zi[0:15]
);

    // ========================================================================
    // PIPELINE STAGE DATA WIDTH PARAMETERS
    // Each stage progressively increases bit width to prevent overflow
    // ========================================================================
    localparam DATA_WIDTH_STAGE4 = DATA_WIDTH + INCREASE_WIDTH;        // Stage 4: Input + optional increase
    localparam DATA_WIDTH_STAGE3 = DATA_WIDTH_STAGE4 + 1;              // Stage 3: +1 bit for butterfly growth
    localparam DATA_WIDTH_STAGE2 = DATA_WIDTH_STAGE3 + 1;              // Stage 2: +1 bit for butterfly growth
    localparam DATA_WIDTH_STAGE1 = DATA_WIDTH_STAGE2 + 1;              // Stage 1: +1 bit for butterfly growth
    // Note: DATA_WIDTH_STAGE0 is now defined as a parameter above

    // ========================================================================
    // INTER-STAGE SIGNAL DECLARATIONS
    // Pipeline carries data through 5 stages with progressive bit width growth
    // ========================================================================
    logic signed [DATA_WIDTH_STAGE4-1:0]    stage4_r[0:15];    // Stage 4 real outputs
    logic signed [DATA_WIDTH_STAGE4-1:0]    stage4_i[0:15];    // Stage 4 imaginary outputs
    logic signed [DATA_WIDTH_STAGE3-1:0]    stage3_r[0:15];    // Stage 3 real outputs
    logic signed [DATA_WIDTH_STAGE3-1:0]    stage3_i[0:15];    // Stage 3 imaginary outputs
    logic signed [DATA_WIDTH_STAGE2-1:0]    stage2_r[0:15];    // Stage 2 real outputs
    logic signed [DATA_WIDTH_STAGE2-1:0]    stage2_i[0:15];    // Stage 2 imaginary outputs
    logic signed [DATA_WIDTH_STAGE1-1:0]    stage1_r[0:15];    // Stage 1 real outputs
    logic signed [DATA_WIDTH_STAGE1-1:0]    stage1_i[0:15];    // Stage 1 imaginary outputs
    logic signed [DATA_WIDTH_STAGE0-1:0]    stage0_r[0:15];    // Stage 0 real outputs (final)
    logic signed [DATA_WIDTH_STAGE0-1:0]    stage0_i[0:15];    // Stage 0 imaginary outputs (final)
   
    // Control signals
    logic                                    enable_stage4_3, enable_stage3_2, enable_stage2_1, enable_stage1_0;
    genvar                                   i;
    int                                      k;
     // ========================================================================
    // STAGE ENABLE CONTROL LOGIC
    // Enables only the required stages based on desired FFT size
    // ========================================================================
    always_comb begin
        enable_stage4_3 = enable;                                                                  // Always enabled (input stage)
        enable_stage3_2 = enable && (FFT_type == 2'b01 || FFT_type == 2'b10 || FFT_type == 2'b00); // FFT4, FFT8, FFT16
        enable_stage2_1 = enable && (FFT_type == 2'b10 || FFT_type == 2'b00);                      // FFT8, FFT16
        enable_stage1_0 = enable && (FFT_type == 2'b00);                                           // FFT16 only
    end

    // ========================================================================
    // DEBUG MONITORING (Currently inactive)
    // ========================================================================
   /*
    always_ff @(posedge clk) begin
       $display("[%0t] Time", $time);
        for (k = 0; k < 16; k++) begin
           $display("  stage0[%0d] = (%0d, %0d)", k, stage0_r[k], stage0_i[k]);
        end
       $display("  ");
    end
   */
   
    // ========================================================================
    // INPUT STAGE: DATA LOADING WITH WIDTH EXTENSION
    // Latency: 1 clock

    // Optionally increases width by INCREASE_WIDTH to accommodate the
    // width of the norm of the complex input, norm(zr+j*zi)=sqrt(zr^2+zi^2).

    // ========================================================================
    generate  
        for (i = 0; i < 16; i++) begin : gen_input_stage
            always_ff @(posedge clk) begin
                if (enable) begin
                    stage4_r[i] <= (DATA_WIDTH_STAGE4)'(zr[i]);
                    stage4_i[i] <= (DATA_WIDTH_STAGE4)'(zi[i]);
                end
            end
        end 
    endgenerate

    // ========================================================================
    // STAGE 4→3: FIRST BUTTERFLY STAGE (Radix-2, stride 1)
    // Latency: 1 clock
    // ========================================================================
    stage4to3 #(
        .DATA_WIDTH (DATA_WIDTH_STAGE4)
    ) u_stage4_3 (
        .clk       (clk),
        .enable    (enable_stage4_3),
        .stage4_r  (stage4_r),
        .stage4_i  (stage4_i),
        .stage3_r  (stage3_r),
        .stage3_i  (stage3_i)
    );

    // ========================================================================
    // STAGE 3→2: SECOND BUTTERFLY STAGE (Radix-2, stride 2)
    // Latency: 1 clock
    // ========================================================================
    stage3to2 #(
        .DATA_WIDTH (DATA_WIDTH_STAGE3)
    ) u_stage3_2 (
        .clk       (clk),
        .enable    (enable_stage3_2),
        .stage3_r  (stage3_r),
        .stage3_i  (stage3_i),
        .stage2_r  (stage2_r),
        .stage2_i  (stage2_i)
    );

    // ========================================================================
    // STAGE 2→1: THIRD BUTTERFLY STAGE (Radix-2, stride 4, with twiddle factors)
    // Latency: 8/9 clocks (depends on TWIDDLE_WIDTH)
    // ========================================================================

    stage2to1 #(
        .DATA_WIDTH    (DATA_WIDTH_STAGE2),
        .TWIDDLE_WIDTH (TWIDDLE_WIDTH)
    ) u_stage2_1 (
        .clk       (clk),
        .enable    (enable_stage2_1),
        .stage2_r  (stage2_r),
        .stage2_i  (stage2_i),
        .stage1_r  (stage1_r),
        .stage1_i  (stage1_i)
    );

    // ========================================================================
    // STAGE 1→0: FOURTH BUTTERFLY STAGE (Radix-2, stride 8, with twiddle factors)
    // Latency: 8/9 clocks (depends on TWIDDLE_WIDTH)
    // ========================================================================
    
    stage1to0 #(
        .DATA_WIDTH    (DATA_WIDTH_STAGE1),
        .TWIDDLE_WIDTH (TWIDDLE_WIDTH)
    ) u_stage1_0 (
        .clk       (clk),
        .enable    (enable_stage1_0),
        .stage1_r  (stage1_r),
        .stage1_i  (stage1_i),
        .stage0_r  (stage0_r),
        .stage0_i  (stage0_i)
    );
 
    // ==============================================================================
    // OUTPUT STAGE: MULTI-SIZE FFT OUTPUT SELECTION WITH BIT-REVERSAL
    // Latency: 1 clock
    // 
    // FFT_type encoding and bit-reversal patterns:
    // ==============================================================================
    // FFT_type[1:0] | FFT Size | Output Stage | Bit-reversal Pattern
    // --------------|----------|--------------|-------------------------------------
    // 11 (3)        | FFT2     | Stage 3      | 0,8,1,9,2,10,3,11,4,12,5,13,6,14,7,15
    // 01 (2)        | FFT4     | Stage 2      | 0,8,4,12,1,9,5,13,2,10,6,14,3,11,7,15  
    // 10 (1)        | FFT8     | Stage 1      | 0,8,4,12,2,10,6,14,1,9,5,13,3,11,7,15  
    // 00 (0)        | FFT16    | Stage 0      | 0,8,4,12,2,10,6,14,1,9,5,13,3,11,7,15
    // ===============================================================================
    always_ff @(posedge clk) begin
        if (enable) begin
           // Real part outputs with stage selection and bit-reversal
	   //                                                                    11                                   01                                                   10              00
            Zr[0]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_r[ 0]) : (DATA_WIDTH_STAGE0)'(stage2_r[ 0])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_r[ 0]) : stage0_r[ 0]);
            Zr[1]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_r[ 8]) : (DATA_WIDTH_STAGE0)'(stage2_r[ 8])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_r[ 8]) : stage0_r[ 8]);
            Zr[2]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_r[ 1]) : (DATA_WIDTH_STAGE0)'(stage2_r[ 4])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_r[ 4]) : stage0_r[ 4]);
            Zr[3]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_r[ 9]) : (DATA_WIDTH_STAGE0)'(stage2_r[12])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_r[12]) : stage0_r[12]);
            Zr[4]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_r[ 2]) : (DATA_WIDTH_STAGE0)'(stage2_r[ 1])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_r[ 2]) : stage0_r[ 2]);
            Zr[5]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_r[10]) : (DATA_WIDTH_STAGE0)'(stage2_r[ 9])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_r[10]) : stage0_r[10]);
            Zr[6]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_r[ 3]) : (DATA_WIDTH_STAGE0)'(stage2_r[ 5])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_r[ 6]) : stage0_r[ 6]);
            Zr[7]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_r[11]) : (DATA_WIDTH_STAGE0)'(stage2_r[13])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_r[14]) : stage0_r[14]);
            Zr[8]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_r[ 4]) : (DATA_WIDTH_STAGE0)'(stage2_r[ 2])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_r[ 1]) : stage0_r[ 1]);
            Zr[9]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_r[12]) : (DATA_WIDTH_STAGE0)'(stage2_r[10])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_r[ 9]) : stage0_r[ 9]);
            Zr[10] <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_r[ 5]) : (DATA_WIDTH_STAGE0)'(stage2_r[ 6])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_r[ 5]) : stage0_r[ 5]);
            Zr[11] <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_r[13]) : (DATA_WIDTH_STAGE0)'(stage2_r[14])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_r[13]) : stage0_r[13]);
            Zr[12] <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_r[ 6]) : (DATA_WIDTH_STAGE0)'(stage2_r[ 3])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_r[ 3]) : stage0_r[ 3]);
            Zr[13] <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_r[14]) : (DATA_WIDTH_STAGE0)'(stage2_r[11])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_r[11]) : stage0_r[11]);
            Zr[14] <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_r[ 7]) : (DATA_WIDTH_STAGE0)'(stage2_r[ 7])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_r[ 7]) : stage0_r[ 7]);
            Zr[15] <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_r[15]) : (DATA_WIDTH_STAGE0)'(stage2_r[15])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_r[15]) : stage0_r[15]);

            // Imaginary part outputs with stage selection and bit-reversal
            Zi[0]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_i[ 0]) : (DATA_WIDTH_STAGE0)'(stage2_i[ 0])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_i[ 0]) : stage0_i[ 0]);
            Zi[1]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_i[ 8]) : (DATA_WIDTH_STAGE0)'(stage2_i[ 8])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_i[ 8]) : stage0_i[ 8]);
            Zi[2]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_i[ 1]) : (DATA_WIDTH_STAGE0)'(stage2_i[ 4])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_i[ 4]) : stage0_i[ 4]);
            Zi[3]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_i[ 9]) : (DATA_WIDTH_STAGE0)'(stage2_i[12])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_i[12]) : stage0_i[12]);
            Zi[4]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_i[ 2]) : (DATA_WIDTH_STAGE0)'(stage2_i[ 1])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_i[ 2]) : stage0_i[ 2]);
            Zi[5]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_i[10]) : (DATA_WIDTH_STAGE0)'(stage2_i[ 9])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_i[10]) : stage0_i[10]);
            Zi[6]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_i[ 3]) : (DATA_WIDTH_STAGE0)'(stage2_i[ 5])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_i[ 6]) : stage0_i[ 6]);
            Zi[7]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_i[11]) : (DATA_WIDTH_STAGE0)'(stage2_i[13])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_i[14]) : stage0_i[14]);
            Zi[8]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_i[ 4]) : (DATA_WIDTH_STAGE0)'(stage2_i[ 2])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_i[ 1]) : stage0_i[ 1]);
            Zi[9]  <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_i[12]) : (DATA_WIDTH_STAGE0)'(stage2_i[10])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_i[ 9]) : stage0_i[ 9]);
            Zi[10] <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_i[ 5]) : (DATA_WIDTH_STAGE0)'(stage2_i[ 6])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_i[ 5]) : stage0_i[ 5]);
            Zi[11] <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_i[13]) : (DATA_WIDTH_STAGE0)'(stage2_i[14])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_i[13]) : stage0_i[13]);
            Zi[12] <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_i[ 6]) : (DATA_WIDTH_STAGE0)'(stage2_i[ 3])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_i[ 3]) : stage0_i[ 3]);
            Zi[13] <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_i[14]) : (DATA_WIDTH_STAGE0)'(stage2_i[11])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_i[11]) : stage0_i[11]);
            Zi[14] <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_i[ 7]) : (DATA_WIDTH_STAGE0)'(stage2_i[ 7])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_i[ 7]) : stage0_i[ 7]);
            Zi[15] <= FFT_type[0] ? (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage3_i[15]) : (DATA_WIDTH_STAGE0)'(stage2_i[15])) : (FFT_type[1] ? (DATA_WIDTH_STAGE0)'(stage1_i[15]) : stage0_i[15]);
        end
    end

endmodule
