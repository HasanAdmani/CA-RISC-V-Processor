module RF_ALU_FSM (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    output reg         done,
    output wire [31:0] alu_result_out,
    output wire        zero_flag_out,
    output wire [3:0]  state_out
);

    // one state per thing the FSM does
    localparam S_IDLE     = 4'd0,
               S_W1       = 4'd1,
               S_W2       = 4'd2,
               S_W3       = 4'd3,
               S_ADD      = 4'd4,
               S_SUB      = 4'd5,
               S_AND      = 4'd6,
               S_OR       = 4'd7,
               S_XOR      = 4'd8,
               S_SLL      = 4'd9,
               S_SRL      = 4'd10,
               S_BEQCHK   = 4'd11,
               S_RAW_WR   = 4'd12,
               S_RAW_RD   = 4'd13,
               S_DONE     = 4'd14;

    // ALU module based operations
    localparam ALU_ADD = 4'b0000,
               ALU_SUB = 4'b0001,
               ALU_AND = 4'b0010,
               ALU_OR  = 4'b0011,
               ALU_XOR = 4'b0100,
               ALU_SLL = 4'b0101,
               ALU_SRL = 4'b0110;

    reg [3:0] state, next_state;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] WriteDataReg;
    reg WriteEnable;
    reg [3:0] ALUControl;

    wire [31:0] ReadData1, ReadData2, ALUResult;
    wire zero;

    assign alu_result_out = ALUResult;
    assign zero_flag_out  = zero;
    assign state_out      = state;

    RegisterFile rf (
        .clk(clk), .rst(rst), .WriteEnable(WriteEnable),
        .rs1(rs1), .rs2(rs2), .rd(rd), .WriteData(WriteDataReg),
        .ReadData1(ReadData1), .ReadData2(ReadData2)
    );

    Alu alu (
        .A(ReadData1), .B(ReadData2), .ALUControl(ALUControl),
        .ALUResult(ALUResult), .zero(zero)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) state <= S_IDLE;
        else     state <= next_state;
    end

    always @* begin
        next_state   = state;
        rs1 = 0; rs2 = 0; rd = 0;
        WriteDataReg = 0;
        WriteEnable  = 0;
        ALUControl   = ALU_ADD;
        done = 0;

        case (state)
            S_IDLE: if (start) next_state = S_W1;

            // write known constants into x1, x2, x3
            S_W1: begin rd=1; WriteDataReg=32'h10101010; WriteEnable=1; next_state=S_W2; end
            S_W2: begin rd=2; WriteDataReg=32'h01010101; WriteEnable=1; next_state=S_W3; end
            S_W3: begin rd=3; WriteDataReg=32'h00000005; WriteEnable=1; next_state=S_ADD; end

            // read x1,x2 -> ALU -> write result into x4..x10
            S_ADD: begin rs1=1; rs2=2; ALUControl=ALU_ADD; rd=4;  WriteDataReg=ALUResult; WriteEnable=1; next_state=S_SUB; end
            S_SUB: begin rs1=1; rs2=2; ALUControl=ALU_SUB; rd=5;  WriteDataReg=ALUResult; WriteEnable=1; next_state=S_AND; end
            S_AND: begin rs1=1; rs2=2; ALUControl=ALU_AND; rd=6;  WriteDataReg=ALUResult; WriteEnable=1; next_state=S_OR;  end
            S_OR:  begin rs1=1; rs2=2; ALUControl=ALU_OR;  rd=7;  WriteDataReg=ALUResult; WriteEnable=1; next_state=S_XOR; end
            S_XOR: begin rs1=1; rs2=2; ALUControl=ALU_XOR; rd=8;  WriteDataReg=ALUResult; WriteEnable=1; next_state=S_SLL; end
            S_SLL: begin rs1=1; rs2=3; ALUControl=ALU_SLL; rd=9;  WriteDataReg=ALUResult; WriteEnable=1; next_state=S_SRL; end
            S_SRL: begin rs1=1; rs2=3; ALUControl=ALU_SRL; rd=10; WriteDataReg=ALUResult; WriteEnable=1; next_state=S_BEQCHK; end

            // beq-style check: x1 - x1 is always 0, so Zero should be 1; store the flag in x11
            S_BEQCHK: begin
                rs1=1; rs2=1; ALUControl=ALU_SUB;
                rd=11; WriteDataReg = zero ? 32'd1 : 32'd0; WriteEnable=1;
                next_state = S_RAW_WR;
            end

            // read-after-write timing: write x12, then read it back into x13 the next cycle
            S_RAW_WR: begin rd=12; WriteDataReg=32'hAAAA5555; WriteEnable=1; next_state=S_RAW_RD; end
            S_RAW_RD: begin rs1=12; rd=13; WriteDataReg=ReadData1; WriteEnable=1; next_state=S_DONE; end

            S_DONE: done = 1;
        endcase
    end

endmodule
