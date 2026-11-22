`timescale 1ns / 1ps

// ALU control: ALUOp + funct3 + funct7 in, the 4 bit code our Alu uses out
// codes are the same ones from Lab 6, plus SLT (0111) for blt / bge
//
// CHANGES for the processor (Lab 11):
//   ALUOp 01 now looks at funct3: beq/bne -> SUB, blt/bge -> SLT   <- extra instruction 3 (blt)
//   ALUOp 11 (I-type ALU) looks at funct3: addi -> ADD, andi -> AND <- extra instruction 2 (andi)
module ALUControl (
    input  wire [1:0] ALUOp,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg  [3:0] ALUCtrl
);

    localparam ALU_ADD = 4'b0000,
               ALU_SUB = 4'b0001,
               ALU_AND = 4'b0010,
               ALU_OR  = 4'b0011,
               ALU_XOR = 4'b0100,
               ALU_SLL = 4'b0101,
               ALU_SRL = 4'b0110,
               ALU_SLT = 4'b0111;

    always @* begin
        ALUCtrl = ALU_ADD;   // safe default

        case (ALUOp)
            2'b00: ALUCtrl = ALU_ADD;    // lw/sw/jalr address add
            2'b01: begin                 // branches
                case (funct3)
                    3'b100, 3'b101: ALUCtrl = ALU_SLT;   // blt, bge : signed compare
                    default:        ALUCtrl = ALU_SUB;   // beq, bne : subtract, check zero
                endcase
            end
            2'b10: begin                 // R-type, funct decides
                case (funct3)
                    3'b000:  ALUCtrl = funct7[5] ? ALU_SUB : ALU_ADD;
                    3'b001:  ALUCtrl = ALU_SLL;
                    3'b101:  ALUCtrl = ALU_SRL;
                    3'b111:  ALUCtrl = ALU_AND;
                    3'b110:  ALUCtrl = ALU_OR;
                    3'b100:  ALUCtrl = ALU_XOR;
                    default: ALUCtrl = ALU_ADD;
                endcase
            end
            2'b11: begin                 // I-type ALU, funct3 decides (funct7 is part of the immediate here, ignore it)
                case (funct3)
                    3'b000:  ALUCtrl = ALU_ADD;   // addi
                    3'b111:  ALUCtrl = ALU_AND;   // andi
                    3'b110:  ALUCtrl = ALU_OR;    // ori  (comes for free)
                    3'b100:  ALUCtrl = ALU_XOR;   // xori (comes for free)
                    default: ALUCtrl = ALU_ADD;
                endcase
            end
            default: ALUCtrl = ALU_ADD;
        endcase
    end

endmodule
