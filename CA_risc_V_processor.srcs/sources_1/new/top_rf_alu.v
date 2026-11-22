`timescale 1ns / 1ps
//writing mapings so i dont forget 
// SW15 = 0 : FSM demo runs by itself (auto)
// SW15 = 1 : manual mode, ALU does  x1 <op> x[rs2]  and can store it in x[rd]
//
// manual mode switches
//   SW[3:0]   ALU op
//   SW[7:4]   rd, where the result gets stored (x0..x15)
//   SW[8]     WriteEnable
//   SW[12:9]  rs2, second ALU input (x0..x15), first input is always x1
//   SW[14]    7-seg shows top 16 bits instead of bottom 16
//
// LEDs
//   auto:   LED[15:12] FSM state, LED[11:0] low bits of the value being written
//   manual: LED[15:0] bottom 16 bits of whatever is stored in x[rd]
//
// 7-seg shows the same value as 4 hex digits
module top_rf_alu #(
    parameter TICK_CYCLES = 50_000_000      // 100MHz / 50M = 2 steps a second
)(
    input  wire clk,
    input  wire pbin,
    input  wire [15:0] physical_sw,
    output wire [15:0] physical_leds,
    output wire [6:0]  seg,
    output wire [3:0]  an,
    output wire        dp
);

    wire rst_clean;
    wire [31:0] switch_data;
    reg  [31:0] led_data = 32'd0;

    // Lab 5 modules, reused as-is
    debouncer rst_db (.clk(clk), .pbin(pbin), .pbout(rst_clean));

    leds switch_reader (.clk(clk), .rst(rst_clean), .btns(16'd0),
        .writeData(32'd0), .writeEnable(1'b0), .readEnable(1'b1),
        .memAddress(30'd0), .switches(physical_sw), .readData(switch_data));

    switches led_writer (.clk(clk), .rst(rst_clean),
        .writeData(led_data), .writeEnable(1'b1),
        .readEnable(1'b0), .memAddress(30'd0),
        .readData(), .leds(physical_leds));

    // switches come in async, two flops before using them
    reg [15:0] sw_meta = 16'd0, sw = 16'd0;
    always @(posedge clk) begin
        sw_meta <= switch_data[15:0];
        sw      <= sw_meta;
    end

    // everything runs on clk, tick just says when to take a step
    reg [31:0] tick_cnt = 32'd0;
    reg        tick = 1'b0;
    always @(posedge clk) begin
        if (rst_clean) begin
            tick_cnt <= 32'd0;
            tick     <= 1'b0;
        end else if (tick_cnt == TICK_CYCLES - 1) begin
            tick_cnt <= 32'd0;
            tick     <= 1'b1;
        end else begin
            tick_cnt <= tick_cnt + 1;
            tick     <= 1'b0;
        end
    end

    // in manual mode the two read ports are shared:
    // most of each step they feed the ALU (x1 and rs2), then for a short window
    // right after the write they read x[rd] back so the LEDs can show it
    reg rb_phase = 1'b0;     // 1 = reading x[rd] back
    reg rb_cap   = 1'b0;     // grab the value now
    always @(posedge clk) begin
        rb_phase <= (tick_cnt >= 32) && (tick_cnt < 64);
        rb_cap   <= (tick_cnt == 60);
    end

    wire        manual   = sw[15];
    wire        hi       = sw[14];
    wire [3:0]  man_rs2  = sw[12:9];
    wire        man_we   = sw[8];
    wire [3:0]  man_rd   = sw[7:4];
    wire [3:0]  man_op   = sw[3:0];

    // FSM
    wire [3:0]  state;
    wire        in_manual;
    wire [4:0]  f_rs1, f_rs2, f_rd;
    wire        f_we;
    wire [1:0]  f_wd_sel;
    wire [31:0] f_const;
    wire [3:0]  f_alu_ctrl;

    RF_ALU_Demo_FSM fsm (
        .clk(clk), .rst(rst_clean), .tick(tick), .manual(manual),
        .state_out(state), .in_manual(in_manual),
        .rs1(f_rs1), .rs2(f_rs2), .rd(f_rd), .we(f_we),
        .wd_sel(f_wd_sel), .const_data(f_const), .alu_ctrl(f_alu_ctrl)
    );

    // in manual mode the switches take over the register file and ALU controls
    wire [4:0] rs1 = in_manual ? (rb_phase ? {1'b0, man_rd} : 5'd1)       : f_rs1;
    wire [4:0] rs2 = in_manual ? (rb_phase ? 5'd0 : {1'b0, man_rs2})      : f_rs2;
    wire [4:0] rd  = in_manual ? {1'b0, man_rd}                           : f_rd;
    wire       we  = in_manual ? man_we                                   : f_we;
    wire [3:0] alu_ctrl = in_manual ? (rb_phase ? 4'd0 : man_op)          : f_alu_ctrl;

    wire [31:0] ReadData1, ReadData2, alu_result;
    wire        zero;
    reg  [31:0] WriteData;

    always @* begin
        if (in_manual) WriteData = alu_result;
        else begin
            case (f_wd_sel)
                2'd0:    WriteData = f_const;
                2'd1:    WriteData = alu_result;
                2'd2:    WriteData = {31'd0, zero};
                default: WriteData = ReadData1;
            endcase
        end
    end

    // write only happens on a tick, same edge the FSM moves
    RegisterFile rf (
        .clk(clk), .rst(rst_clean), .WriteEnable(we & tick),
        .rs1(rs1), .rs2(rs2), .rd(rd), .WriteData(WriteData),
        .ReadData1(ReadData1), .ReadData2(ReadData2)
    );

    Alu alu (
        .A(ReadData1), .B(ReadData2), .ALUControl(alu_ctrl),
        .ALUResult(alu_result), .zero(zero)
    );

    // x[rd] readback (x[rd] + x0 goes through the ALU during the read window)
    reg [31:0] rd_view = 32'd0;
    always @(posedge clk)
        if (rb_cap) rd_view <= alu_result;

    // what we show
    wire [31:0] shown_val = in_manual ? rd_view : WriteData;

    always @(posedge clk)
        led_data <= in_manual ? {16'd0, rd_view[15:0]}
                              : {16'd0, state, WriteData[11:0]};

    // 7-seg
    reg [15:0] seg_value = 16'd0;
    always @(posedge clk)
        seg_value <= hi ? shown_val[31:16] : shown_val[15:0];

    SevenSegHex seven_seg (.clk(clk), .value(seg_value), .seg(seg), .an(an));
    assign dp = 1'b1;   // decimal point off

endmodule