`timescale 1ns / 1ps
// main control: opcode in, control signals out
// R-type 0110011, I-type ALU (addi andi) 0010011, loads 0000011, stores 0100011,
// BEQ/BNE/BLT/BGE 1100011, JAL 1101111, JALR 1100111, LUI 0110111
// the don't cares are set to 0, and any opcode we don't know turns everything off
//
// CHANGES for the processor (Lab 11):
//   + Jump    (jal)  : pc <= pc + offset, rd <= pc + 4
//   + JumpReg (jalr) : pc <= rs1 + imm,   rd <= pc + 4
//   + Lui    (lui)   : rd <= imm (upper 20 bits)           <- extra instruction 1
//   ALUOp 11 = "I-type ALU, look at funct3" (needed so andi is not treated as addi) <- extra instruction 2
module MainControl (
    input  wire [6:0] opcode,
    output reg        RegWrite,
    output reg  [1:0] ALUOp,
    output reg        MemRead,
    output reg        MemWrite,
    output reg        ALUSrc,
    output reg        MemtoReg,
    output reg        Branch,
    output reg        Jump,
    output reg        JumpReg,
    output reg        Lui
);

    localparam OP_RTYPE  = 7'b0110011,
               OP_ITYPE  = 7'b0010011,   // ADDI ANDI
               OP_LOAD   = 7'b0000011,   // LW
               OP_STORE  = 7'b0100011,   // SW
               OP_BRANCH = 7'b1100011,   // BEQ BNE BLT BGE
               OP_JAL    = 7'b1101111,
               OP_JALR   = 7'b1100111,
               OP_LUI    = 7'b0110111;

    // ALUOp: 00 = add, 01 = branch compare (sub or slt), 10 = R-type (funct3/funct7), 11 = I-type ALU (funct3)
    always @* begin
        RegWrite = 1'b0;
        ALUOp    = 2'b00;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        ALUSrc   = 1'b0;
        MemtoReg = 1'b0;
        Branch   = 1'b0;
        Jump     = 1'b0;
        JumpReg  = 1'b0;
        Lui      = 1'b0;

        case (opcode)
            OP_RTYPE:  begin RegWrite = 1; ALUOp = 2'b10; end
            OP_ITYPE:  begin RegWrite = 1; ALUOp = 2'b11; ALUSrc = 1; end
            OP_LOAD:   begin RegWrite = 1; ALUOp = 2'b00; ALUSrc = 1; MemRead = 1; MemtoReg = 1; end
            OP_STORE:  begin ALUOp = 2'b00; ALUSrc = 1; MemWrite = 1; end
            OP_BRANCH: begin ALUOp = 2'b01; Branch = 1; end
            OP_JAL:    begin RegWrite = 1; Jump = 1; end
            OP_JALR:   begin RegWrite = 1; JumpReg = 1; ALUOp = 2'b00; ALUSrc = 1; end   // ALU adds rs1 + imm = target
            OP_LUI:    begin RegWrite = 1; Lui = 1; end
            default:   ;   // unsupported, all zeros
        endcase
    end

endmodule
