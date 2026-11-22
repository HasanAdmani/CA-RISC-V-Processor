`timescale 1ns/1ps

module RF_ALU_FSM_tb;

    reg clk, rst, start;
    wire done, zero_flag_out;
    wire [31:0] alu_result_out;
    wire [3:0] state_out;

    RF_ALU_FSM dut (
        .clk(clk), .rst(rst), .start(start), .done(done),
        .alu_result_out(alu_result_out), .zero_flag_out(zero_flag_out),
        .state_out(state_out)
    );

    always #5 clk = ~clk;

    // in case the fsm never gets to done
    initial begin
        #5000;
        $display("TIMEOUT: done never went high");
        $stop;
    end

    initial begin
        clk = 0; rst = 1; start = 0;
        #12 rst = 0;
        #10 start = 1;
        #10 start = 0;

        wait (done);
        #2;

        // peek directly into the register file to check results
        // (dut.rf is the RegisterFile instance inside RF_ALU_FSM)
        if (dut.rf.regs[1] == 32'h10101010) $display("PASS: x1 = 0x10101010"); else $display("FAIL: x1");
        if (dut.rf.regs[2] == 32'h01010101) $display("PASS: x2 = 0x01010101"); else $display("FAIL: x2");
        if (dut.rf.regs[3] == 32'h00000005) $display("PASS: x3 = 0x00000005"); else $display("FAIL: x3");
        if (dut.rf.regs[0] == 32'd0)        $display("PASS: x0 is still 0");    else $display("FAIL: x0");
        if (dut.rf.regs[4] == (32'h10101010 + 32'h01010101)) $display("PASS: x4 = ADD result"); else $display("FAIL: x4 ADD");
        if (dut.rf.regs[5] == (32'h10101010 - 32'h01010101)) $display("PASS: x5 = SUB result"); else $display("FAIL: x5 SUB");
        if (dut.rf.regs[6] == (32'h10101010 & 32'h01010101)) $display("PASS: x6 = AND result"); else $display("FAIL: x6 AND");
        if (dut.rf.regs[7] == (32'h10101010 | 32'h01010101)) $display("PASS: x7 = OR result"); else $display("FAIL: x7 OR");
        if (dut.rf.regs[8] == (32'h10101010 ^ 32'h01010101)) $display("PASS: x8 = XOR result"); else $display("FAIL: x8 XOR");
        if (dut.rf.regs[9]  == (32'h10101010 << 5)) $display("PASS: x9 = SLL result");  else $display("FAIL: x9 SLL");
        if (dut.rf.regs[10] == (32'h10101010 >> 5)) $display("PASS: x10 = SRL result"); else $display("FAIL: x10 SRL");
        if (dut.rf.regs[11] == 32'd1) $display("PASS: x11 beq flag set (x1 == x1)"); else $display("FAIL: x11 beq flag");
        if (dut.rf.regs[12] == 32'hAAAA5555) $display("PASS: x12 = 0xAAAA5555");        else $display("FAIL: x12");
        if (dut.rf.regs[13] == 32'hAAAA5555) $display("PASS: x13 = read-after-write of x12"); else $display("FAIL: x13 RAW");
        $stop;
    end

endmodule
