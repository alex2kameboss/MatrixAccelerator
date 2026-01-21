module ma_fft_unit (
    ma_config_bus.accelerator   config_intf ,
    ma_data_bus.accelerator     data_intf   ,
    ma_rsp_intf.accelerator     rsp_intf    
);

// Local Parameters Definition  ------------------------------------------------------------------------------


// Wires Definition ------------------------------------------------------------------------------------------
logic   en;


// Combinatorial Logic ---------------------------------------------------------------------------------------
assign data_intf.unit_id = ma_intf_pkg::VECTORIAL_UNIT;
assign data_intf.op1.scheme = prf_dtypes::ROW;
assign data_intf.op2.scheme = prf_dtypes::ROW;
assign data_intf.rez.scheme = prf_dtypes::ROW;
assign data_intf.rez.lane_valid = {data_intf.PRF_N_LANES{1'b1}};
assign rsp_intf.unit_id = data_intf.unit_id;
assign en = config_intf.dst_unit == data_intf.unit_id;
assign data_intf.op1.valid = en;
assign data_intf.op2.valid = en;


// Sequential Logic ------------------------------------------------------------------------------------------
genvar lane;
generate;
    for ( lane = 0; lane < data_intf.PRF_N_LANES; lane = lane + 1  ) begin : data_assignment
always_ff @(posedge data_intf.clk) begin
    if ( ~data_intf.rst_n ) begin
        z[lane] <= '0;
    end else if ( fft_feed_active && !prf_read[0] ) begin
        z[lane] <= data_intf.op1_data[(lane + 1) * 32 - 1 -: 32];
    end
end
    end
endgenerate

always_ff @(posedge clk) begin
    if (~reset_n) begin
        fft_enable <= 1'b0;
        fft_feed_count <= 0;
        fft_feed_active <= 1'b0;
        fft_run_count <= 0;
        fft_run_active <= 1'b0;
        for (int lane = 0; lane < 16; lane++) begin
            z[lane] <= '0;
        end
    end else if (fft_feed_start) begin
        fft_feed_active <= 1'b1;
        fft_feed_count <= 0;
    end else if (fft_feed_active && !prf_read[0]) begin
        for (int lane = 0; lane < 16; lane++) begin
            z[lane] <= prf_data_out_r[0][lane];
        end
        fft_feed_count <= fft_feed_count + 1;
        if (fft_feed_count + 1 >= FFT_FEED_BLOCKS) begin
            fft_feed_active <= 1'b0;
            fft_run_active <= 1'b1;
            fft_run_count <= 0;
        end
    end else if (fft_run_active) begin
        fft_run_count <= fft_run_count + 1;
        if (fft_run_count + 1 >= FFT_OUTPUT_CYCLES) begin
            fft_run_active <= 1'b0;
        end
    end
    fft_enable <= (fft_feed_active || fft_run_active);
end

// Modules Instances -----------------------------------------------------------------------------------------
FFT256 #(
    .DATA_WIDTH(data_intf.SRAM_WIDTH)
) fft256_i (
    .clk    (data_intf.clk),
    .enable (fft_enable),
    .rst_n  (data_intf.rst_n),
    .FFT_type (FFT_type),
    .z      (z),
    .Z      (Z)
);

endmodule