`timescale 1ns / 1ps
module FullAdder(
    input A, input B, input C1,
    output S, output C2
);
    assign S  = A ^ B ^ C1;
    assign C2 = (A & B) | (C1 & (A ^ B));
endmodule