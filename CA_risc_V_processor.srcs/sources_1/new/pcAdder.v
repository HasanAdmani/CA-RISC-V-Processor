`timescale 1ns / 1ps

// PC + 4 : address of the next instruction (every instruction is 4 bytes)
// also used as the "return address" that jal / jalr save in rd
module pcAdder (
    input  wire [31:0] pc,
    output wire [31:0] pc_plus4
);

    assign pc_plus4 = pc + 32'd4;

endmodule
