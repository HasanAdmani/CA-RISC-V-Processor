`timescale 1ns / 1ps

// Lab 11 Task 2 the whole processor running real programs.
//   dut0 : PROGRAM 0 = Lab 10 FSM   (switches -> countdown on LEDs, button = reset)
//   dut1 : PROGRAM 1 = Task 2a      (fibonacci, uses lui / andi / blt and the stack)
// The clock here is 10 ns (100 MHz) just to keep the simulation short, the logic does not care.
// The real delay loop is ~0.5 s long, so at time 0 we patch ONE instruction of the FSM program
// (lui t0,30  ->  lui t0,1) to make every countdown step ~16 k cycles instead of ~490 k.
module TopLevelProcessor_tb;

    reg clk = 0;
    always #5 clk = ~clk;

    // ---------------- FSM processor ----------------
    reg         rst0 = 1, btn0 = 0;
    reg  [15:0] sw0  = 16'd0;
    wire [15:0] leds0;
    wire [31:0] pc0, instr0;

    TopLevelProcessor #(.PROGRAM(0)) dut0 (
        .clk(clk), .rst(rst0), .btn(btn0), .switches(sw0),
        .leds(leds0), .pc_dbg(pc0), .instr_dbg(instr0)
    );

    // ---------------- fibonacci processor ----------------
    reg         rst1 = 1;
    reg  [15:0] sw1  = 16'd0;
    wire [15:0] leds1;
    wire [31:0] pc1, instr1;

    TopLevelProcessor #(.PROGRAM(1)) dut1 (
        .clk(clk), .rst(rst1), .btn(1'b0), .switches(sw1),
        .leds(leds1), .pc_dbg(pc1), .instr_dbg(instr1)
    );

    // shorten the delay loop of the FSM program (word at address 0x5c = lui t0,30 -> lui t0,1)
    initial begin
        #1;
        dut0.imem.memory[8'h5c] = 8'hb7;
        dut0.imem.memory[8'h5d] = 8'h12;
        dut0.imem.memory[8'h5e] = 8'h00;
        dut0.imem.memory[8'h5f] = 8'h00;
    end

    integer fails = 0;
    task check(input ok, input [8*50-1:0] name);
        begin
            if (ok) $display("PASS: %0s", name);
            else begin $display("FAIL: %0s", name); fails = fails + 1; end
        end
    endtask

    // wait until the FSM LEDs show a value (or give up after max cycles)
    task wait_led0(input [15:0] value, input [31:0] max);
        integer n;
        begin
            n = 0;
            while (leds0 !== value && n < max) begin @(posedge clk); n = n + 1; end
            check(leds0 === value, "FSM LEDs reached expected value");
            $display("      t=%0t  LEDs = %0d", $time, leds0);
        end
    endtask

    function [15:0] fib(input [31:0] n);
        integer a, b, t, k;
        begin
            a = 0; b = 1;
            for (k = 0; k < n; k = k + 1) begin t = a + b; a = b; b = t; end
            fib = a;
        end
    endfunction

    integer n, test_n;
    reg [4:0] ns [0:5];

    initial begin
        // ---------- reset both ----------
        repeat (4) @(posedge clk);
        #1 rst0 = 0; rst1 = 0;

        // =================== FSM tests ===================
        $display("--- Lab 10 FSM ---");
        repeat (100) @(posedge clk);
        check(leds0 === 16'd0, "idle: switches = 0, LEDs = 0");
        check(pc0 >= 32'h0c && pc0 <= 32'h18, "idle: PC is inside the wait loop");

        // switch value 3 -> captured, shown, counted down 3,2,1,0. new switch input must be ignored
        sw0 = 16'd3;
        wait_led0(16'd3, 100);
        sw0 = 16'd12;                                   // ignored during countdown
        wait_led0(16'd2, 40000);
        wait_led0(16'd1, 40000);
        sw0 = 16'd0;                                    // so it does not restart afterwards
        wait_led0(16'd0, 40000);
        repeat (200) @(posedge clk);
        check(leds0 === 16'd0, "countdown finished, LEDs stay 0");
        while (pc0 !== 32'h0c) @(posedge clk);
        check(dut0.rf.regs[2] === 32'd508, "stack pointer restored (508)");

        // reset button during countdown
        sw0 = 16'd9;
        wait_led0(16'd9, 100);
        wait_led0(16'd8, 40000);
        sw0 = 16'd0;
        btn0 = 1;                                       // press reset
        repeat (50) @(posedge clk);
        check(leds0 === 16'd0, "reset button: LEDs cleared immediately");
        btn0 = 0;
        while (pc0 !== 32'h0c) @(posedge clk);
        check(dut0.rf.regs[2] === 32'd508, "reset button: stack pointer restored");
        repeat (100) @(posedge clk);
        check(leds0 === 16'd0 && pc0 <= 32'h18, "reset button: back in input waiting state");

        // =================== fibonacci tests ===================
        $display("--- Task 2a fibonacci (lui, andi, blt, stack) ---");
        repeat (4) @(posedge clk);
        ns[0] = 0; ns[1] = 1; ns[2] = 2; ns[3] = 7; ns[4] = 12; ns[5] = 15;
        for (n = 0; n < 6; n = n + 1) begin
            test_n = ns[n];
            sw1 = 16'hFFF0 | test_n;                    // upper bits set on purpose, andi must mask them off
            repeat (500) @(posedge clk);
            while (pc1 !== 32'h0c) @(posedge clk);      // top of the main loop
            if (leds1 === (16'h8000 | fib(test_n)))
                $display("PASS: n=%0d  LEDs = 0x%h (fib = %0d, LED15 on)", test_n, leds1, fib(test_n));
            else begin
                $display("FAIL: n=%0d  LEDs = 0x%h  wanted 0x%h", test_n, leds1, 16'h8000 | fib(test_n));
                fails = fails + 1;
            end
            check(dut1.rf.regs[2] === 32'd508, "stack pointer back to 508 after fib()");
        end

        if (fails == 0) $display("ALL TESTS PASSED");
        else            $display("%0d TESTS FAILED", fails);
        $stop;
    end

    // safety net so a bug cannot hang the simulation forever
    initial begin
        #200_000_000;
        $display("TIMEOUT");
        $stop;
    end

endmodule
