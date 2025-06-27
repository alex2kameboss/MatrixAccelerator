module parallel_to_serial #(
    parameter   SERIAL_DATA_WIDTH   =   32  ,
    parameter   DEPTH               =   8   
) (
    input   logic                               clk                     ,
    input   logic                               rst_n                   ,
    input   logic                               en                      ,
    input   logic                               clear                   ,
    input   logic                               load                    ,
    input   logic                               shift                   ,
    input   logic   [SERIAL_DATA_WIDTH - 1 : 0] data_i  [DEPTH - 1 : 0] ,
    output  logic   [SERIAL_DATA_WIDTH - 1 : 0] data_o   
);
    
// Local Parameters Definition  ------------------------------------------------------------------------------



// Wires Definition ------------------------------------------------------------------------------------------
logic   [SERIAL_DATA_WIDTH - 1 : 0] data  [DEPTH - 1 : 0];


// Combinatorial Logic ---------------------------------------------------------------------------------------
assign data_o = data[0];


// Sequential Logic ------------------------------------------------------------------------------------------
always_ff @( posedge clk, negedge rst_n )
    if ( rst_n )                        data <= '{default: 'd0};          else
    if ( en ) begin
        if ( clear )                    data <= '{default: 'd0};          else
        if ( load )                     data <= data_i;                   else
        if ( shift )                    data[DEPTH - 2 : 0] <= data[DEPTH - 1 : 1];
    end


// Modules Instances -----------------------------------------------------------------------------------------



endmodule