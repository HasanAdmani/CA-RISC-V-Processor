`timescale 1ns / 1ps

// branch or jump target is PC + (imm << 1)
// immGen is offset WITHOUT its last bit (bit 0 of a branch offset is always 0, so the instruction does not store it). shifting left by 1 puts it back.
module branchAdder (
    input  wire [31:0] pc,
    input  wire [31:0] imm,
    output wire [31:0] target
);

    assign target = pc + (imm << 1);

endmodule
