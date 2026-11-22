`timescale 1ns/1ps

// checks the whole top, not just the fsm. tick is shortened so it doesn't take forever
module top_rf_alu_tb;

    reg clk, pbin;
    reg  [15:0] sw;
    wire [15:0] leds;

    top_rf_alu #(.TICK_CYCLES(4)) dut (
        .clk(clk), .pbin(pbin), .physical_sw(sw), .physical_leds(leds)
    );

    always #5 clk = ~clk;

    integer fails = 0;

    // each step is 4 clocks = 40ns
    task steps(input integer n);
        begin repeat (n) #40; end
    endtask

    task check(input ok, input [255:0] name);
        begin
            if (ok) $display("PASS: %0s", name);
            else begin $display("FAIL: %0s", name); fails = fails + 1; end
        end
    endtask

    initial begin
        #3000000;
        $display("TIMEOUT");
        $stop;
    end

    initial begin
        clk = 0; pbin = 0; sw = 16'd0;

        // skip the debouncer delay, just force the clean reset for a bit
        force dut.rst_clean = 1'b1;
        #100;
        release dut.rst_clean;

        // auto mode, let it run the full sequence
        steps(20);
        check(dut.rf.regs[1]  == 32'h10101010, "auto: x1");
        check(dut.rf.regs[2]  == 32'h01010101, "auto: x2");
        check(dut.rf.regs[3]  == 32'h00000005, "auto: x3");
        check(dut.rf.regs[4]  == 32'h11111111, "auto: x4 ADD");
        check(dut.rf.regs[5]  == 32'h0F0F0F0F, "auto: x5 SUB");
        check(dut.rf.regs[6]  == 32'h00000000, "auto: x6 AND");
        check(dut.rf.regs[7]  == 32'h11111111, "auto: x7 OR");
        check(dut.rf.regs[8]  == 32'h11111111, "auto: x8 XOR");
        check(dut.rf.regs[9]  == 32'h02020200, "auto: x9 SLL");
        check(dut.rf.regs[10] == 32'h00808080, "auto: x10 SRL");
        check(dut.rf.regs[11] == 32'd1,         "auto: x11 beq flag");
        check(dut.rf.regs[13] == 32'hAAAA5555, "auto: x13 read-after-write");

        // manual: ADD into x14, we on
        sw = 16'h81D0;
        steps(20);
        check(dut.rf.regs[14] == 32'h11111111, "manual: x14 = x1 + x2");
        check(leds[15:12] == 4'hF,             "manual: state LEDs = 1111");

        // manual: SRL with B = x3, into x15
        sw = 16'h83F6;
        steps(5);
        check(dut.rf.regs[15] == 32'h00808080, "manual: x15 = x1 >> x3");

        // we off, shouldn't change x14 even if the op changes
        sw = 16'h8180;     // op = ADD, we = 0, rd = x12
        steps(5);
        check(dut.rf.regs[12] == 32'hAAAA5555, "manual: we low, x12 untouched");

        // view x14
        sw = 16'h85C0;
        steps(5);
        check(leds[11:0] == 12'h111, "view: x14 low 12 bits on LEDs");

        // view x1, next slice
        sw = 16'hA420;
        steps(5);
        check(leds[11:0] == ((32'h10101010 >> 12) & 12'hFFF), "view: x1 slice 01");

        // back to auto, it should restart and finish again
        sw = 16'd0;
        steps(25);
        check(dut.rf.regs[13] == 32'hAAAA5555, "auto again: x13");
        check(dut.rf.regs[10] == 32'h00808080, "auto again: x10");

        if (fails == 0) $display("ALL PASSED");
        else            $display("%0d FAILED", fails);
        $stop;
    end

endmodule
