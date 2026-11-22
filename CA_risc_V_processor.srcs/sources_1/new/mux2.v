`timescale 1ns / 1ps

// 2 to 1 mux, width can be changed with the parameter
// sel = 0 is d0, sel = 1 is d1
module mux2 #(
    parameter W = 32
)(
    input  wire [W-1:0] d0,
    input  wire [W-1:0] d1,
    input  wire         sel,
    output wire [W-1:0] y
);

    assign y = sel ? d1 : d0;

endmodule
