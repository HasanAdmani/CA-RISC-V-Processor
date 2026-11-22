`timescale 1ns / 1ps

// board top for the Basys 3
//   100 MHz board clock -> divided to 1 MHz CPU clock (course project requirement)
//   pbrst (btnU) : hard reset, restarts the program from address 0
//   pbin  (btnC) : the "reset button" of Lab 10, software reads it at 0x304 or 0x400
//   physical_sw  : 16 switches, software reads them at address 0x300
//   physical_leds: 16 LEDs, software writes them at address 0x200
// Set MEM_FILE to "instructions.mem" for Task 1 (Lab 10 FSM), or your Task 2b .mem file.
module top_riscv_fpga #(
    parameter MEM_FILE = "instructions.mem",
    parameter HALF     = 50          // 100 MHz / (2*50) = 1 MHz. (HALF = 5 would give 10 MHz)
)(
    input  wire        clk,
    input  wire        pbin,
    input  wire        pbrst,
    input  wire [15:0] physical_sw,
    output wire [15:0] physical_leds
);

    // ---------- clock divider: toggle every HALF board clocks ----------
    reg [7:0] div_cnt = 8'd0;
    reg       div_clk = 1'b0;
    always @(posedge clk) begin
        if (div_cnt == HALF - 1) begin
            div_cnt <= 8'd0;
            div_clk <= ~div_clk;
        end else begin
            div_cnt <= div_cnt + 1'b1;
        end
    end

    wire cpu_clk;
    BUFG cpu_clk_buf (.I(div_clk), .O(cpu_clk));   // put the slow clock on a proper clock wire

    // ---------- inputs: debounce (Lab 5 module) + 2 flop synchroniser ----------
    wire btn_clean;
    debouncer btn_db (.clk(cpu_clk), .pbin(pbin), .pbout(btn_clean));

    reg [15:0] sw_meta = 16'd0, sw_sync = 16'd0;
    reg        btn_meta = 1'b0, btn_sync = 1'b0;
    reg [1:0]  rst_ff   = 2'b11;                  // starts in reset so power on is clean
    always @(posedge cpu_clk) begin
        sw_meta  <= physical_sw;   sw_sync  <= sw_meta;
        btn_meta <= btn_clean;     btn_sync <= btn_meta;
        rst_ff   <= {rst_ff[0], pbrst};
    end
    wire rst = rst_ff[1];

    // ---------- the processor ----------
    TopLevelProcessor #(.MEM_FILE(MEM_FILE)) cpu (
        .clk(cpu_clk), .rst(rst), .btn(btn_sync), .switches(sw_sync),
        .leds(physical_leds), .pc_dbg(), .instr_dbg()
    );

endmodule
