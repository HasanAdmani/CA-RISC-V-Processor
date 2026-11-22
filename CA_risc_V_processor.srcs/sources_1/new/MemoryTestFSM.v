`timescale 1ns / 1ps
//   RD_SW  = read switches (address 768)
//   WR_MEM = save that value in data memory
//   RD_MEM = read it back from memory
//   WR_LED = send it to the LEDs (address 512)
module MemoryTestFSM (
    input  wire        clk,
    input  wire        rst,
    input  wire        tick,          // slow pulse so we can see each step
    input  wire [31:0] readData,
    output reg  [31:0] address,
    output reg         readEnable,
    output wire        writeEnable,
    output reg  [31:0] writeData,
    output wire [1:0]  state_out
);
    localparam RD_SW  = 2'd0,
               WR_MEM = 2'd1,
               RD_MEM = 2'd2,
               WR_LED = 2'd3;
    reg [1:0]  state = RD_SW;
    reg [15:0] sw_reg  = 16'd0;    // value from the switches
    reg [15:0] mem_reg = 16'd0;    // value we got back from memory
    reg [2:0]  loc = 3'd0;         // memory location for this round (0-7)
    assign state_out = state;
    // write only on a tick so it happens once per step
    reg we_state;
    assign writeEnable = we_state & tick;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state   <= RD_SW;
            sw_reg  <= 16'd0;
            mem_reg <= 16'd0;
            loc     <= 3'd0;
        end else if (tick) begin
            case (state)
                RD_SW:  begin sw_reg  <= readData[15:0]; state <= WR_MEM; end
                WR_MEM: state <= RD_MEM;
                RD_MEM: begin mem_reg <= readData[15:0]; state <= WR_LED; end
                WR_LED: begin loc <= loc + 1; state <= RD_SW; end
            endcase
        end
    end
    // what the bus does in each state
    always @* begin
        address    = 32'd0;
        readEnable = 1'b0;
        we_state   = 1'b0;
        writeData  = 32'd0;
        case (state)
            RD_SW:  begin address = 32'd768; readEnable = 1'b1; end
            WR_MEM: begin address = {29'd0, loc}; we_state = 1'b1; writeData = {16'd0, sw_reg}; end
            RD_MEM: begin address = {29'd0, loc}; readEnable = 1'b1; end
            WR_LED: begin address = 32'd512; we_state = 1'b1; writeData = {16'd0, mem_reg}; end
        endcase
    end
endmodule
