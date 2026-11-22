`timescale 1ns / 1ps

// board top test: auto mode first, then manual mode
module MemoryTestFSM_tb;

    reg clk, pbin;
    reg  [15:0] sw;
    wire [15:0] leds;

    top_memory_system #(.TICK_CYCLES(4)) dut (
        .clk(clk), .pbin(pbin), .physical_sw(sw), .physical_leds(leds)
    );

    always #5 clk = ~clk;

    integer fails = 0;
    reg [2:0] loc_before;
    task check(input ok, input [8*44-1:0] name);
        begin
            if (ok) $display("PASS: %0s", name);
            else begin $display("FAIL: %0s", name); fails = fails + 1; end
        end
    endtask

    // 4 steps per round, 4 clocks per step = 160ns, wait 2 rounds
    task pass2; begin #320; end endtask
    // manual mode needs a few ticks
    task wait_m; begin #200; end endtask

    // sw = {manual, we, re, dev[1:0], addr[2:0], data[7:0]}
    task man(input we, input re, input [1:0] dev, input [2:0] addr, input [7:0] data);
        begin
            sw = {1'b1, we, re, dev, addr, data};
            wait_m;
        end
    endtask

    initial begin
        clk = 0; pbin = 0; sw = 16'h0000;
        // force reset for a bit at the start
        force dut.rst_clean = 1'b1;
        #100;
        release dut.rst_clean;

        // ---- auto mode ----
        sw = 16'h25A5; pass2;
        check(leds == 16'h25A5, "auto: LEDs follow switches (25A5)");
        check(dut.mem_sys.dmem.mem[0] == 32'h000025A5 || dut.mem_sys.dmem.mem[1] == 32'h000025A5 ||
              dut.mem_sys.dmem.mem[2] == 32'h000025A5, "auto: value went into data memory");
        sw = 16'h1234; pass2;
        check(leds == 16'h1234, "auto: LEDs follow switches (1234)");
        sw = 16'h0000; pass2;
        check(leds == 16'h0000, "auto: all switches down");

        // ---- manual mode ----
        // write 2A into memory address 3, then 55 into address 5
        man(1, 0, 2'b00, 3'd3, 8'h2A);
        man(1, 0, 2'b00, 3'd5, 8'h55);
        // read them back, data switches set to something else on purpose
        man(0, 1, 2'b00, 3'd3, 8'hFF);
        check(leds == 16'h002A, "manual: read mem[3] = 2A");
        man(0, 1, 2'b00, 3'd5, 8'hFF);
        check(leds == 16'h0055, "manual: read mem[5] = 55");
        // memory outside 0-7 range of address bits (device bits 01 = 256-511) is a different box
        man(0, 1, 2'b01, 3'd3, 8'hFF);
        check(leds == 16'h0000, "manual: mem[259] still empty");

        // write to the LED device
        man(1, 0, 2'b10, 3'd0, 8'hA5);
        man(0, 0, 2'b10, 3'd0, 8'h00);
        check(leds == 16'h00A5, "manual: LED write (A5) stays on LEDs");
        // reading the LED address gives nothing
        man(0, 1, 2'b10, 3'd0, 8'h00);
        check(leds == 16'h0000, "manual: read of LED address = 0");

        // read the switches device, LEDs show the switch pattern
        man(0, 1, 2'b11, 3'd0, 8'h3C);
        check(leds == sw, "manual: read switches device");

        // writing to the switch address does nothing
        man(1, 0, 2'b11, 3'd0, 8'hFF);
        man(0, 0, 2'b11, 3'd0, 8'h00);
        check(leds == 16'h00A5, "manual: switch write did nothing");

        // back to auto
        sw = 16'h00F0; pass2; pass2;
        check(leds == 16'h00F0, "back in auto mode");
        loc_before = dut.fsm.loc;
        pass2;
        check(dut.fsm.loc != loc_before, "auto: memory location keeps moving");

        if (fails == 0) $display("ALL PASSED");
        else            $display("%0d FAILED", fails);
        $stop;
    end

endmodule