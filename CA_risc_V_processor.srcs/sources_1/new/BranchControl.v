`timescale 1ns / 1ps

// decides if a branch is really taken
// Branch      : main control says "this instruction is a branch"
// funct3      : which branch (000 beq, 001 bne, 100 blt, 101 bge)
// zero        : ALU zero flag   (used by beq / bne, ALU did A - B)
// lt          : ALU result bit 0 (used by blt / bge, ALU did signed A < B)
module BranchControl (
    input  wire       Branch,
    input  wire [2:0] funct3,
    input  wire       zero,
    input  wire       lt,
    output reg        take
);

    always @* begin
        if (Branch) begin
            case (funct3)
                3'b000:  take = zero;     // beq : equal
                3'b001:  take = ~zero;    // bne : not equal
                3'b100:  take = lt;       // blt : less than
                3'b101:  take = ~lt;      // bge : greater or equal
                default: take = 1'b0;
            endcase
        end else begin
            take = 1'b0;                  // explicit else (prevents latch inference)
        end
    end

endmodule
