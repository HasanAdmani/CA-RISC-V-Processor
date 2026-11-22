`timescale 1ns / 1ps

// Lab 11 Task 1 testbench: ProgramCounter + pcAdder + branchAdder + mux2 + immGen
// Verifies:
//   - PC increments by 4 when PCSrc = 0
//   - PC updates to the branch target when PCSrc = 1
//   - immGen produces correct signed values (I, S, B, J, U)
module PCDatapath_tb;

    reg         clk = 0, rst = 1, PCSrc = 0;
    reg  [31:0] instruction = 32'd0;

    wire [31:0] pc, pc_plus4, imm, branch_target, pc_next;

    ProgramCounter pc_reg (.clk(clk), .rst(rst), .pc_next(pc_next), .pc(pc));
    pcAdder        pc_add (.pc(pc), .pc_plus4(pc_plus4));
    immGen         ig     (.instruction(instruction), .imm(imm));
    branchAdder    br_add (.pc(pc), .imm(imm), .target(branch_target));
    mux2 #(32)     pc_mux (.d0(pc_plus4), .d1(branch_target), .sel(PCSrc), .y(pc_next));

    always #5 clk = ~clk;

    integer fails = 0;
    task check(input ok, input [8*44-1:0] name);
        begin
            if (ok) $display("PASS: %0s", name);
            else begin $display("FAIL: %0s", name); fails = fails + 1; end
        end
    endtask

    // set an instruction, wait a little, compare the immediate
    task imm_test(input [8*30-1:0] name, input [31:0] inst, input [31:0] exp_imm);
        begin
            instruction = inst; #2;
            if (imm === exp_imm) $display("PASS: immGen %0s  imm = %0d (0x%h)", name, $signed(imm), imm);
            else begin $display("FAIL: immGen %0s  got 0x%h wanted 0x%h", name, imm, exp_imm); fails = fails + 1; end
        end
    endtask

    initial begin
        // ---------- immediates ----------
        imm_test("addi x1,x0,-1      (I)", 32'hfff00093, 32'hffffffff);
        imm_test("addi x1,x0,2047    (I)", 32'h7ff00093, 32'h000007ff);
        imm_test("sw x2,-4(x1)       (S)", 32'hfe20ae23, 32'hfffffffc);
        imm_test("beq x1,x2,+16      (B)", 32'h00208863, 32'h00000008);   // 16 >> 1 = 8 (branchAdder shifts it back)
        imm_test("bne x1,x2,-8       (B)", 32'hfe209ce3, 32'hfffffffc);   // -8 >> 1 = -4
        imm_test("blt x1,x2,+12      (B)", 32'h0020c663, 32'h00000006);
        imm_test("jal ra,-12         (J)", 32'hff5ff0ef, 32'hfffffffa);   // -12 >> 1 = -6
        imm_test("lui x5,0x12345     (U)", 32'h123452b7, 32'h12345000);

        // ---------- PC updating ----------
        #3 rst = 0; PCSrc = 0;                  // release reset away from the clock edge
        check(pc === 32'd0, "PC = 0 after reset");
        @(posedge clk); #1; check(pc === 32'd4,  "PC = 4,  PCSrc=0, +4");
        @(posedge clk); #1; check(pc === 32'd8,  "PC = 8,  PCSrc=0, +4");
        @(posedge clk); #1; check(pc === 32'd12, "PC = 12, PCSrc=0, +4");

        // branch: beq with offset +16 at PC = 12 -> target 28
        instruction = 32'h00208863; PCSrc = 1; #2;
        check(branch_target === 32'd28, "branchAdder: 12 + (8<<1) = 28");
        @(posedge clk); #1; check(pc === 32'd28, "PC = 28 branch taken, PCSrc=1");

        // backwards branch: bne offset -8 at PC = 28 -> target 20
        instruction = 32'hfe209ce3; #2;
        check(branch_target === 32'd20, "branchAdder: 28 + (-4<<1) = 20");
        @(posedge clk); #1; check(pc === 32'd20, "PC = 20 (backward branch)");

        // not taken again: back to +4
        PCSrc = 0;
        @(posedge clk); #1; check(pc === 32'd24, "PC = 24 (PCSrc=0, +4)");

        // reset in the middle of running
        rst = 1; #2; check(pc === 32'd0, "PC = 0 (async reset)");

        if (fails == 0) $display("ALL TESTS PASSED");
        else            $display("%0d TESTS FAILED", fails);
        $stop;
    end
endmodule
