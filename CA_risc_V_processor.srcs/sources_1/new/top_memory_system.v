`timescale 1ns / 1ps

module top_memory_system #(
    parameter TICK_CYCLES = 5_000_000       // 100MHz / 5M = 20 steps clock mapping 
)(
    input  wire clk,
    input  wire pbin,                       // center = reset
    input  wire [15:0] physical_sw,
    output wire [15:0] physical_leds
);

    wire rst_clean;

    // from old lab debouncer
    debouncer rst_db (.clk(clk), .pbin(pbin), .pbout(rst_clean));

    // switches timing issue fix  (2 flops first) 
    reg [15:0] sw_meta = 16'd0, sw_sync = 16'd0;
    always @(posedge clk) begin
        sw_meta <= physical_sw;
        sw_sync <= sw_meta;
    end

    // tick = 1 tick cycles clock
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

    // manual mode logicv switch mapping so i dont forget 
    wire        manual   = sw_sync[15];     // 1 = switches drive the bus
    wire        man_we   = sw_sync[14];     // write enable
    wire        man_re   = sw_sync[13];     // read enable
    wire [1:0]  man_dev  = sw_sync[12:11];  // becomes address[9:8] (which device)
    wire [2:0]  man_addr = sw_sync[10:8];   // becomes address[2:0] (spot inside the device)
    wire [7:0]  man_data = sw_sync[7:0];    // data to write

    // bus signals
    wire [31:0] address, writeData, readData;
    wire        readEnable, writeEnable;

    // auto FSM thing 
    wire [31:0] fsm_address, fsm_writeData;
    wire        fsm_readEnable, fsm_writeEnable;
    wire [1:0]  state;

    // FSM pause for manual mode
    MemoryTestFSM fsm (
        .clk(clk), .rst(rst_clean), .tick(tick & ~manual), .readData(readData),
        .address(fsm_address), .readEnable(fsm_readEnable), .writeEnable(fsm_writeEnable),
        .writeData(fsm_writeData), .state_out(state)
    );

    // what are we making the bus do, write read stuff
    assign address     = manual ? {22'd0, man_dev, 5'd0, man_addr} : fsm_address;
    assign readEnable  = manual ? man_re            : fsm_readEnable;
    assign writeEnable = manual ? (man_we & tick)   : fsm_writeEnable;   // write only on a tick
    assign writeData   = manual ? {24'd0, man_data} : fsm_writeData;

    wire [15:0] led_dev;   // LED device value

    addressDecoderTop mem_sys (
        .clk(clk), .rst(rst_clean), .address(address),
        .readEnable(readEnable), .writeEnable(writeEnable),
        .writeData(writeData), .switches(sw_sync),
        .readData(readData), .leds(led_dev)
    );

    // manuals how what we read else show the LED device
    assign physical_leds = (manual & man_re) ? readData[15:0] : led_dev;

endmodule