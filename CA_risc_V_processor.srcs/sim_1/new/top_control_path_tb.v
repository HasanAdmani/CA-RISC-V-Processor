`timescale 1ns / 1ps

// board top, set the switches like an instruction and look at the LEDs
module top_control_path_tb;

    reg clk, pbin;
    reg  [15:0] sw;
    wire [15:0] leds;

    top_control_path dut (.clk(clk), .pbin(pbin), .physical_sw(sw), .physical_leds(leds));

    always #5 clk = ~clk;

    integer fails = 0;

    // LEDs = {4'b0, ALUControl, ALUOp, Branch, MemtoReg, MemWrite, MemRead, ALUSrc, RegWrite}
    task instr(input [8*6-1:0] name, input [6:0] op, input [2:0] f3, input f7_5, input [11:0] exp);
        begin
            sw = {5'b00000, f7_5, f3, op};
            #200;                       // a few trips around the fsm
            if (leds === {4'b0000, exp}) $display("PASS: %0s  LEDs = %b", name, leds[11:0]);
            else begin
                $display("FAIL: %0s  LEDs = %b, wanted %b", name, leds[11:0], exp);
                fails = fails + 1;
            end
        end
    endtask

    localparam R = 7'b0110011, I = 7'b0010011, L = 7'b0000011, S = 7'b0100011, B = 7'b1100011;

    initial begin
        clk = 0; pbin = 0; sw = 16'd0;
        force dut.rst_clean = 1'b1;     // skip the debouncer delay
        #100;
        release dut.rst_clean;

        //           name     op  f3      f7[5]  {ALUControl, ALUOp, Branch, MemtoReg, MemWrite, MemRead, ALUSrc, RegWrite}
        instr("ADD",  R, 3'b000, 1'b0, {4'b0000, 2'b10, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1});
        instr("SUB",  R, 3'b000, 1'b1, {4'b0001, 2'b10, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1});
        instr("SLL",  R, 3'b001, 1'b0, {4'b0101, 2'b10, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1});
        instr("SRL",  R, 3'b101, 1'b0, {4'b0110, 2'b10, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1});
        instr("AND",  R, 3'b111, 1'b0, {4'b0010, 2'b10, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1});
        instr("OR",   R, 3'b110, 1'b0, {4'b0011, 2'b10, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1});
        instr("XOR",  R, 3'b100, 1'b0, {4'b0100, 2'b10, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1});
        instr("ADDI", I, 3'b000, 1'b0, {4'b0000, 2'b11, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1});
        instr("LW",   L, 3'b010, 1'b0, {4'b0000, 2'b00, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b1});
        instr("LH",   L, 3'b001, 1'b0, {4'b0000, 2'b00, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b1});
        instr("LB",   L, 3'b000, 1'b0, {4'b0000, 2'b00, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b1});
        instr("SW",   S, 3'b010, 1'b0, {4'b0000, 2'b00, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0});
        instr("SH",   S, 3'b001, 1'b0, {4'b0000, 2'b00, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0});
        instr("SB",   S, 3'b000, 1'b0, {4'b0000, 2'b00, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0});
        instr("BEQ",  B, 3'b000, 1'b0, {4'b0001, 2'b01, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0});

        // (ADDI now has ALUOp = 11, I-type ALU, after the Lab 11 change)
        // switches changing while it runs, and an opcode we dont support
        instr("ADD",  R, 3'b000, 1'b0, {4'b0000, 2'b10, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1});
        instr("bad",  7'b1111111, 3'b111, 1'b1, 12'b0000_00_0_0_0_0_0_0);

        if (fails == 0) $display("ALL PASSED");
        else            $display("%0d FAILED", fails);
        $stop;
    end

endmodule
