`timescale 1ns / 1ps
// Lab 10 Task 3: Instruction Memory (256 bytes = 64 instructions, little-endian)
// Loads machine code from a .mem file (one hex byte per line, padded to 256 bytes).
//   Default  ("instructions.mem")     : Lab 10 counter program for hardware
//   Override ("instructions_sim.mem") : fast-delay version for simulation
module instructionMemory #(
    parameter OPERAND_LENGTH = 31,
    parameter MEM_FILE       = "instructions.mem"
)(
    input  wire [OPERAND_LENGTH:0] instAddress,
    output reg  [31:0]             instruction
);

    reg [7:0] memory [0:255];

    initial begin
        $readmemh(MEM_FILE, memory);
    end

    // Word-aligned little-endian combinational read (uses low 8 bits of PC)
    always @* begin
        instruction = {memory[{instAddress[7:2], 2'b11}],
                       memory[{instAddress[7:2], 2'b10}],
                       memory[{instAddress[7:2], 2'b01}],
                       memory[{instAddress[7:2], 2'b00}]};
    end

endmodule
