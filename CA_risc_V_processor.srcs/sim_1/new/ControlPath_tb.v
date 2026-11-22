`timescale 1ns / 1ps

// feeds every supported instruction into MainControl -> ALUControl and checks the control signals
// UPDATED for Lab 11: addi is now ALUOp = 11 (I-type ALU), and jal / jalr / lui / andi / bne / blt / bge are checked too
module ControlPath_tb;
    reg  [6:0] opcode, funct7;
    reg  [2:0] funct3;
    wire       RegWrite, MemRead, MemWrite, ALUSrc, MemtoReg, Branch, Jump, JumpReg, Lui;
    wire [1:0] ALUOp;
    wire [3:0] ALUCtrl;

    MainControl mc (
        .opcode(opcode), .RegWrite(RegWrite), .ALUOp(ALUOp),
        .MemRead(MemRead), .MemWrite(MemWrite), .ALUSrc(ALUSrc),
        .MemtoReg(MemtoReg), .Branch(Branch),
        .Jump(Jump), .JumpReg(JumpReg), .Lui(Lui)
    );
    ALUControl ac (
        .ALUOp(ALUOp), .funct3(funct3), .funct7(funct7), .ALUCtrl(ALUCtrl)
    );

    integer fails = 0;

    // exp  = {RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg, Branch}
    // exp2 = {Jump, JumpReg, Lui}
    task instr(input [8*10-1:0] name, input [6:0] op, input [2:0] f3, input [6:0] f7,
               input [5:0] exp, input [2:0] exp2, input [1:0] exp_aluop, input [3:0] exp_alu);
        begin
            opcode = op; funct3 = f3; funct7 = f7;
            #10;
            if ({RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg, Branch} === exp &&
                {Jump, JumpReg, Lui} === exp2 &&
                ALUOp === exp_aluop && ALUCtrl === exp_alu)
                $display("PASS: %0s", name);
            else begin
                $display("FAIL: %0s  got RegW=%b ALUSrc=%b MemR=%b MemW=%b M2R=%b Br=%b Jmp=%b Jr=%b Lui=%b ALUOp=%b ALUCtrl=%b",
                         name, RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg, Branch, Jump, JumpReg, Lui, ALUOp, ALUCtrl);
                fails = fails + 1;
            end
        end
    endtask

    localparam R = 7'b0110011, I = 7'b0010011, L = 7'b0000011, S = 7'b0100011, B = 7'b1100011,
               JAL = 7'b1101111, JALR = 7'b1100111, LUI = 7'b0110111;
    localparam F7_0 = 7'b0000000, F7_SUB = 7'b0100000;

    initial begin
        opcode = 0; funct3 = 0; funct7 = 0;
        #10;

        //         name    opcode f3     f7      {RegW,ALUSrc,MemR,MemW,M2R,Br} {Jmp,Jr,Lui} ALUOp ALUCtrl
        instr("ADD",   R, 3'b000, F7_0,   6'b100000, 3'b000, 2'b10, 4'b0000);
        instr("SUB",   R, 3'b000, F7_SUB, 6'b100000, 3'b000, 2'b10, 4'b0001);
        instr("SLL",   R, 3'b001, F7_0,   6'b100000, 3'b000, 2'b10, 4'b0101);
        instr("SRL",   R, 3'b101, F7_0,   6'b100000, 3'b000, 2'b10, 4'b0110);
        instr("AND",   R, 3'b111, F7_0,   6'b100000, 3'b000, 2'b10, 4'b0010);
        instr("OR",    R, 3'b110, F7_0,   6'b100000, 3'b000, 2'b10, 4'b0011);
        instr("XOR",   R, 3'b100, F7_0,   6'b100000, 3'b000, 2'b10, 4'b0100);
        instr("ADDI",  I, 3'b000, F7_0,   6'b110000, 3'b000, 2'b11, 4'b0000);
        instr("ANDI",  I, 3'b111, F7_0,   6'b110000, 3'b000, 2'b11, 4'b0010);   // new
        instr("LW",    L, 3'b010, F7_0,   6'b111010, 3'b000, 2'b00, 4'b0000);
        instr("SW",    S, 3'b010, F7_0,   6'b010100, 3'b000, 2'b00, 4'b0000);
        instr("BEQ",   B, 3'b000, F7_0,   6'b000001, 3'b000, 2'b01, 4'b0001);
        instr("BNE",   B, 3'b001, F7_0,   6'b000001, 3'b000, 2'b01, 4'b0001);
        instr("BLT",   B, 3'b100, F7_0,   6'b000001, 3'b000, 2'b01, 4'b0111);   // new, ALU does SLT
        instr("BGE",   B, 3'b101, F7_0,   6'b000001, 3'b000, 2'b01, 4'b0111);
        instr("JAL",   JAL,  3'b000, F7_0, 6'b100000, 3'b100, 2'b00, 4'b0000);
        instr("JALR",  JALR, 3'b000, F7_0, 6'b110000, 3'b010, 2'b00, 4'b0000);
        instr("LUI",   LUI,  3'b000, F7_0, 6'b100000, 3'b001, 2'b00, 4'b0000);  // new

        // things that shouldn't change the result
        instr("ADDI f7", I, 3'b000, F7_SUB, 6'b110000, 3'b000, 2'b11, 4'b0000);   // funct7 ignored for addi
        instr("LW f7",   L, 3'b010, F7_SUB, 6'b111010, 3'b000, 2'b00, 4'b0000);   // and for loads

        // opcode we don't support: everything off
        instr("bad op",  7'b1111111, 3'b111, F7_SUB, 6'b000000, 3'b000, 2'b00, 4'b0000);

        if (fails == 0) $display("ALL TESTS PASSED");
        else            $display("%0d TESTS FAILED", fails);
        $stop;
    end
endmodule
