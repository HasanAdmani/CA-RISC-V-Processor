`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//notes what to do
// single cycle RISC-V processor
//
//   goes PC -> instructionMemory -> (control, immGen, register file) -> ALU -> memory system (data mem+LEDs+switches use before lab stuff) -> write back to the register file, and choose next pc
//
// one instruction per clock cycle
//
// what instructions done so far: [add sub and or xor sll srl], addi andi | lw sw | beq bne blt bge | jal jalr | lui
// memory mappings (Lab 8):  0-511 data memory, 512-767 LEDs, 768-1023 switches
//   0x300 (768) = switch value,   0x304 (772) or 0x400 (1024) = reset button (bit 0)
////////////////////////////////////////////////////////////////////////////////////////////////////
module TopLevelProcessor #(
    parameter MEM_FILE = "instructions.mem" // .mem file loaded into instructionMemory
)(
    input  wire        clk,
    input  wire        rst,               // hard reset: PC = 0, registers = 0, LEDs off
    input  wire        btn,               // push button, readable at 0x304 (772) or 0x400 (1024)
    input  wire [15:0] switches,          // already synchronised to clk
    output wire [15:0] leds,
    // trying to debuggg 
    output wire [31:0] pc_dbg,
    output wire [31:0] instr_dbg
);

    //wires 
    wire [31:0] pc, pc_plus4, branch_target, pc_after_branch, pc_next;
    wire [31:0] instruction;
    wire [31:0] imm;
    wire [31:0] rs1_data, rs2_data;
    wire [31:0] alu_b, alu_result;
    wire        zero;
    wire [31:0] bus_read_data, mem_read_data;
    wire [31:0] write_back;

    // control signals
    wire        RegWrite, MemRead, MemWrite, ALUSrc, MemtoReg, Branch, Jump, JumpReg, Lui;
    wire [1:0]  ALUOp;
    wire [3:0]  ALUCtrl;
    wire        branch_take, PCSrc;

    // instruction fields
    wire [6:0] opcode = instruction[6:0];
    wire [4:0] rd     = instruction[11:7];
    wire [2:0] funct3 = instruction[14:12];
    wire [4:0] rs1    = instruction[19:15];
    wire [4:0] rs2    = instruction[24:20];
    wire [6:0] funct7 = instruction[31:25];

    assign pc_dbg    = pc;
    assign instr_dbg = instruction;
//making the whole fetch execute cycle thing 

    // fetch 
    ProgramCounter pc_reg (.clk(clk), .rst(rst), .pc_next(pc_next), .pc(pc));

    instructionMemory #(.MEM_FILE(MEM_FILE)) imem (
        .instAddress(pc), .instruction(instruction)
    );

    pcAdder pc_add (.pc(pc), .pc_plus4(pc_plus4));

    // decode
    MainControl main_ctrl (
        .opcode(opcode), .RegWrite(RegWrite), .ALUOp(ALUOp), .MemRead(MemRead),
        .MemWrite(MemWrite), .ALUSrc(ALUSrc), .MemtoReg(MemtoReg), .Branch(Branch),
        .Jump(Jump), .JumpReg(JumpReg), .Lui(Lui)
    );

    ALUControl alu_ctrl (
        .ALUOp(ALUOp), .funct3(funct3), .funct7(funct7), .ALUCtrl(ALUCtrl)
    );

    immGen imm_gen (.instruction(instruction), .imm(imm));

    RegisterFile rf (
        .clk(clk), .rst(rst), .WriteEnable(RegWrite),
        .rs1(rs1), .rs2(rs2), .rd(rd), .WriteData(write_back),
        .ReadData1(rs1_data), .ReadData2(rs2_data)
    );

    // execute
    mux2 #(32) alu_src_mux (.d0(rs2_data), .d1(imm), .sel(ALUSrc), .y(alu_b));

    Alu alu (
        .A(rs1_data), .B(alu_b), .ALUControl(ALUCtrl),
        .ALUResult(alu_result), .zero(zero)
    );

    // memory
    // ALU result is the address. decoder picks data memory, LEDs or switches
    addressDecoderTop mem_sys (
        .clk(clk), .rst(rst), .address(alu_result),
        .readEnable(MemRead), .writeEnable(MemWrite),
        .writeData(rs2_data), .switches(switches),
        .readData(bus_read_data), .leds(leds)
    );

    // the button is at 0x304 (switch device, offset 4). 
    // FIX FINALLY: module only had switches, so we put the button on the read bus here.
    wire btn_select = MemRead & (alu_result[10] | ((alu_result[9:8] == 2'b11) & alu_result[2]));
    assign mem_read_data = btn_select ? {31'd0, btn} : bus_read_data;

    //write back
    
    // jal/jalr write PC+4, lui writes the immediate, lw writes memory data, everything else the ALU
    assign write_back = (Jump | JumpReg) ? pc_plus4 :
                        Lui               ? imm      :
                        MemtoReg          ? mem_read_data :
                                            alu_result;

    // next PC
    BranchControl br_ctrl (
        .Branch(Branch), .funct3(funct3), .zero(zero), .lt(alu_result[0]), .take(branch_take)
    );

    assign PCSrc = branch_take | Jump;   // branch taken or jal

    branchAdder br_add (.pc(pc), .imm(imm), .target(branch_target));

    mux2 #(32) pcsrc_mux (.d0(pc_plus4), .d1(branch_target), .sel(PCSrc), .y(pc_after_branch));

    // jalr logic target is rs1 + imm (from the ALU)
    mux2 #(32) jalr_mux (.d0(pc_after_branch), .d1({alu_result[31:1], 1'b0}), .sel(JumpReg), .y(pc_next));

endmodule
