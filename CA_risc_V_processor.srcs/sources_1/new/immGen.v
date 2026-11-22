`timescale 1ns / 1ps

// what to do
// takes the whole 32 bit instruction 
//looks at the opcode to know which format it is 
//rebuilds the sign extended immediate.
//
//   I (addi andi lw jalr) imm[11:0]  = inst[31:20]
//   S  (sw)   imm[11:0]  = inst[31:25] , inst[11:7]
//   B  (beq bne blt bge) imm[12:1]  = inst[31] inst[7] inst[30:25] inst[11:8]
//   J  (jal)  imm[20:1]  = inst[31] inst[19:12] inst[20] inst[30:21]
//   U  (lui)  mm[31:12] = inst[31:12]   (low 12 bits = 0)
//
// remmeber for B and J we output imm12:1 (the missing bit 0 is always 0). 
module immGen (
    input  wire [31:0] instruction,
    output reg  [31:0] imm
);

    localparam OP_ITYPE  = 7'b0010011,   // addi andi
               OP_LOAD   = 7'b0000011,   // lw
               OP_JALR   = 7'b1100111,   // jalr
               OP_STORE  = 7'b0100011,   // sw
               OP_BRANCH = 7'b1100011,   // beq bne blt bge
               OP_JAL    = 7'b1101111,   // jal
               OP_LUI    = 7'b0110111;   // lui

    always @* begin
        case (instruction[6:0])
            OP_ITYPE, OP_LOAD, OP_JALR:
                imm = {{20{instruction[31]}}, instruction[31:20]};

            OP_STORE:
                imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

            OP_BRANCH:
                imm = {{20{instruction[31]}}, instruction[31], instruction[7],
                       instruction[30:25], instruction[11:8]};

            OP_JAL:
                imm = {{12{instruction[31]}}, instruction[31], instruction[19:12],
                       instruction[20], instruction[30:21]};

            OP_LUI:
                imm = {instruction[31:12], 12'd0};

            default:
                imm = 32'd0;
        endcase
    end

endmodule
