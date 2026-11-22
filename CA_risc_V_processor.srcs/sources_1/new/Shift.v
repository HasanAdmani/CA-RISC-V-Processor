`timescale 1ns / 1ps

module Shift(
    input func, // 1 = left, 0 = right
    input [31:0]x,
    input [4:0]shift_parameter, // how much to shift needs to be less than 5
    output [31:0]y
    );
    
    assign y = func ? (x << shift_parameter) : (x >> shift_parameter);
    
endmodule
