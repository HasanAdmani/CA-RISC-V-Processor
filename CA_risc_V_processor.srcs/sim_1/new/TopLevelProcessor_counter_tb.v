`timescale 1ns / 1ps
// Lab 11 demo testbench with switches and leds 
//
//   switches = 0      -> LEDs stay 0                 waiting part
//   switches = N      countdown
//   switch changes during the countdown are ignored
//   reset button (btn) during the countdown -> LEDs clear, back to waiting
//   hard reset (rst)                      
//
// The program comes from instructions_sim.mem (same code as instructions.mem,
// only the delay numbers are small so the countdown takes ~34 clocks per step
// instead of ~10 million).
// =====================================================================
module TopLevelProcessor_counter_tb;

    reg         clk = 0;
    reg         rst = 1;          // hard reset, starts ON
    reg         btn = 0;          // the Lab 10 reset button
    reg  [15:0] switches = 0;
    wire [15:0] leds;
    wire [31:0] pc;               // current instruction address (nice to see in the waveform)
    wire [31:0] instr;            // current instruction


    // Load the fast-delay simulation .mem file directly via the MEM_FILE parameter
    TopLevelProcessor #(.MEM_FILE("instructions_sim.mem")) dut (
        .clk(clk), .rst(rst), .btn(btn),
        .switches(switches), .leds(leds),
        .pc_dbg(pc), .instr_dbg(instr)
    );

    // clock flips every 5 ns giving one clock = 10 ns 
    always #5 clk = ~clk;

    //test
    initial begin
        // small reset 
        #40 rst = 0;

        // test 1 it should just wait here 
        #600;
        if (leds == 0) $display("waiting works : switches=0, LEDs stay 0");
        else           $display("issue with waiting: LEDs = %0d", leds);

        // test switches = 3, so countdown from 3
        switches = 3;
        wait (leds == 3);  $display("LEDs = %0d at %0t ns", leds, $time);
        switches = 7;                                         //ignoring change mid count
        wait (leds == 2);  $display("LEDs = %0d at %0t ns", leds, $time);
        wait (leds == 1);  $display("LEDs = %0d at %0t ns", leds, $time);
        switches = 0;                                          // so it does not start again afterwards
        wait (leds == 0);  $display("LEDs = %0d at %0t ns", leds, $time);
        #600;
        if (leds == 0) $display("PASSED count from 3, swich was ignored");
        else           $display("FAILED count: LEDs = %0d", leds);

        // testing another with 5
        switches = 5;
        wait (leds == 5);
        wait (leds == 4);
        wait (leds == 3);
        wait (leds == 2);
        wait (leds == 1);
        switches = 0;
        wait (leds == 0);
        #600;
        if (leds == 0) $display("passed 5 count");
        else           $display("failed 5 count: LEDs = %0d", leds);

        // testing reset
        switches = 4;
        wait (leds == 4);
        wait (leds == 3);
        switches = 0;                                          // release the switches
        btn = 1;                                               // press the reset button
        wait (leds == 0);                                      // LEDs must clear right away
        #20 btn = 0;                                           // let go of the button
        #600;
        if (leds == 0 && pc >= 32'h10 && pc <= 32'h18) $display("PASS 4: reset button -> LEDs 0, back in the waiting loop");
        else                                          $display("FAIL 4: LEDs = %0d, pc = 0x%h", leds, pc);

  
        switches = 6;
        wait (leds == 6);
        wait (leds == 5);
        switches = 0;
        rst = 1;                                               // hard reset
        @(posedge clk); #1;                                    // wait one clock edge
        if (leds == 0) $display("PASS 5: hard reset cleared the LEDs");
        else           $display("FAIL 5: LEDs = %0d", leds);
        #20 rst = 0;                                           // release, program restarts at address 0
        #600;
        if (leds == 0 && pc <= 32'h18) $display("PASS 5b: program restarted and is waiting");
        else                           $display("FAIL 5b: LEDs = %0d, pc = 0x%h", leds, pc);

        $display("ALL DONE");
        $stop;
    end


    initial begin
        #200000;
        $display("TIMEOUT: something is stuck");
        $stop;
    end

endmodule