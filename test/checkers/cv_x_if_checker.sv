module cv_x_if_checker (
    input       clk ,
    core_v_xif  xif
);
    
// Compressed interface
assert property (@(posedge clk) (xif.compressed_valid && xif.compressed_ready |=> $stable(compressed_req)));
assert property (@(posedge clk) (xif.compressed_valid && xif.compressed_ready |=> $stable(compressed_resp)));

// Issue interface
assert property (@(posedge clk) (xif.issue_valid && xif.issue_ready |=> $stable(issue_req)));
assert property (@(posedge clk) (xif.issue_valid && xif.issue_ready |=> $stable(issue_resp)));

// Register interface
assert property (@(posedge clk) (xif.register_valid && xif.register_ready |=> $stable(register)));

// Commit interface
assert property (@(posedge clk) (xif.commit_valid |=> $stable(commit)));

// Result interface
assert property (@(posedge clk) (xif.result_valid && xif.result_ready |=> $stable(result)));



endmodule