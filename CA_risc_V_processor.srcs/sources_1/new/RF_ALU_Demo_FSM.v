`timescale 1ns / 1ps

// same sequence as RF_ALU_FSM, but this one only makes control signals.
// the top module owns the register file and the ALU
module RF_ALU_Demo_FSM (
    input  wire        clk,
    input  wire        rst,
    input  wire        tick,        // one pulse per step so we can actually watch it
    input  wire        manual,      // SW15
    output wire [3:0]  state_out,
    output wire        in_manual,
    output reg  [4:0]  rs1,
    output reg  [4:0]  rs2,
    output reg  [4:0]  rd,
    output reg         we,
    output reg  [1:0]  wd_sel,      // what goes into WriteData
    output reg  [31:0] const_data,
    output reg  [3:0]  alu_ctrl
);

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
               S_DONE     = 4'd14,
               S_MANUAL   = 4'd15;

    localparam ALU_ADD = 4'b0000,
               ALU_SUB = 4'b0001,
               ALU_SLL = 4'b0101,
               ALU_SRL = 4'b0110,
               ALU_AND = 4'b0010,
               ALU_OR  = 4'b0011,
               ALU_XOR = 4'b0100;

    localparam WD_CONST = 2'd0,
               WD_ALU   = 2'd1,
               WD_ZERO  = 2'd2,
               WD_RD1   = 2'd3;

    reg [3:0] state = S_IDLE;
    reg [3:0] next_state;

    assign state_out = state;
    assign in_manual = (state == S_MANUAL);

    // only moves on a tick
    always @(posedge clk or posedge rst) begin
        if (rst)       state <= S_IDLE;
        else if (tick) state <= next_state;
    end

    always @* begin
        next_state = state;
        rs1 = 0; rs2 = 0; rd = 0; we = 0;
        wd_sel = WD_ALU;
        const_data = 32'd0;
        alu_ctrl = ALU_ADD;

        case (state)
            S_IDLE: next_state = S_W1;

            // constants into x1, x2, x3
            S_W1: begin rd=1; const_data=32'h10101010; wd_sel=WD_CONST; we=1; next_state=S_W2; end
            S_W2: begin rd=2; const_data=32'h01010101; wd_sel=WD_CONST; we=1; next_state=S_W3; end
            S_W3: begin rd=3; const_data=32'h00000005; wd_sel=WD_CONST; we=1;
                        next_state = manual ? S_MANUAL : S_ADD; end

            // x1 op x2 -> x4..x10
            S_ADD: begin rs1=1; rs2=2; alu_ctrl=ALU_ADD; rd=4;  we=1; next_state=S_SUB; end
            S_SUB: begin rs1=1; rs2=2; alu_ctrl=ALU_SUB; rd=5;  we=1; next_state=S_AND; end
            S_AND: begin rs1=1; rs2=2; alu_ctrl=ALU_AND; rd=6;  we=1; next_state=S_OR;  end
            S_OR:  begin rs1=1; rs2=2; alu_ctrl=ALU_OR;  rd=7;  we=1; next_state=S_XOR; end
            S_XOR: begin rs1=1; rs2=2; alu_ctrl=ALU_XOR; rd=8;  we=1; next_state=S_SLL; end
            S_SLL: begin rs1=1; rs2=3; alu_ctrl=ALU_SLL; rd=9;  we=1; next_state=S_SRL; end   // shifts by x3 = 5
            S_SRL: begin rs1=1; rs2=3; alu_ctrl=ALU_SRL; rd=10; we=1; next_state=S_BEQCHK; end

            // x1 - x1 = 0 so zero should be 1, flag goes in x11
            S_BEQCHK: begin rs1=1; rs2=1; alu_ctrl=ALU_SUB; rd=11; wd_sel=WD_ZERO; we=1; next_state=S_RAW_WR; end

            // write x12 then read it back into x13 on the next step
            S_RAW_WR: begin rd=12; const_data=32'hAAAA5555; wd_sel=WD_CONST; we=1; next_state=S_RAW_RD; end
            S_RAW_RD: begin rs1=12; rd=13; wd_sel=WD_RD1; we=1; next_state=S_DONE; end

            // go around again
            S_DONE: next_state = S_IDLE;

            // top takes over the ports here, leave once SW15 goes low
            S_MANUAL: if (!manual) next_state = S_W1;

            default: next_state = S_IDLE;
        endcase

        // SW15 jumps to manual any time after x1-x3 are loaded
        if (manual && state >= S_ADD && state != S_MANUAL)
            next_state = S_MANUAL;
    end

endmodule
