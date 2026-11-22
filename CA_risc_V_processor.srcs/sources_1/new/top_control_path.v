`timescale 1ns / 1ps
// switches 
//   SW[6:0]   opcode
//   SW[9:7]   funct3
//   SW[10]    funct7 bit 5 (only bit that matters rest 0
// LEDs 
//   LED0 RegWrite   LED1 ALUSrc   LED2 MemRead   LED3 MemWrite   LED4 MemtoReg   LED5 Branch
//   LED[7:6] ALUOp  LED[11:8] ALUControl   LED[15:12] off
//
// center button = reset
module top_control_path (
    input  wire clk,
    input  wire pbin,
    input  wire [15:0] physical_sw,
    output wire [15:0] physical_leds
);

    wire rst_clean;
    wire [31:0] switch_data;

    // Lab 5 debouncer
    debouncer rst_db (.clk(clk), .pbin(pbin), .pbout(rst_clean));

    // switches are async, two flops first
    reg [15:0] sw_meta = 16'd0, sw_sync = 16'd0;
    always @(posedge clk) begin
        sw_meta <= physical_sw;
        sw_sync <= sw_meta;
    end

    // FSM 
    // READ   : read the switches through the switch interface
    // DECODE : control path works on what we read, grab the outputs
    // SHOW   : write them to the LEDs through the LED interface
    localparam S_READ = 2'd0, S_DECODE = 2'd1, S_SHOW = 2'd2;

    reg [1:0]  state = S_READ;
    reg [6:0]  opcode   = 7'd0;
    reg [2:0]  funct3   = 3'd0;
    reg        funct7_5 = 1'b0;
    reg [11:0] ctrl_reg = 12'd0;

    wire readEnable  = (state == S_READ);
    wire writeEnable = (state == S_SHOW);

    // control path
    wire       RegWrite, MemRead, MemWrite, ALUSrc, MemtoReg, Branch;
    wire [1:0] ALUOp;
    wire [3:0] ALUCtrl;

    MainControl main_ctrl (
        .opcode(opcode), .RegWrite(RegWrite), .ALUOp(ALUOp),
        .MemRead(MemRead), .MemWrite(MemWrite), .ALUSrc(ALUSrc),
        .MemtoReg(MemtoReg), .Branch(Branch)
    );

    ALUControl alu_ctrl (
        .ALUOp(ALUOp), .funct3(funct3), .funct7({1'b0, funct7_5, 5'b00000}),
        .ALUCtrl(ALUCtrl)
    );

    always @(posedge clk) begin
        if (rst_clean) begin
            state    <= S_READ;
            opcode   <= 7'd0;
            funct3   <= 3'd0;
            funct7_5 <= 1'b0;
            ctrl_reg <= 12'd0;
        end else begin
            case (state)
                S_READ: begin
                    opcode   <= switch_data[6:0];
                    funct3   <= switch_data[9:7];
                    funct7_5 <= switch_data[10];
                    state    <= S_DECODE;
                end
                S_DECODE: begin
                    ctrl_reg <= {ALUCtrl, ALUOp, Branch, MemtoReg, MemWrite, MemRead, ALUSrc, RegWrite};
                    state    <= S_SHOW;
                end
                S_SHOW: begin
                    state    <= S_READ;
                end
                default: state <= S_READ;
            endcase
        end
    end
    // Lab 5 switch and LED interfaces
    leds switch_reader (
        .clk(clk), .rst(rst_clean), .btns(16'd0),
        .writeData(32'd0), .writeEnable(1'b0),
        .readEnable(readEnable), .memAddress(30'd0),
        .switches(sw_sync), .readData(switch_data)
    );

    switches led_writer (
        .clk(clk), .rst(rst_clean),
        .writeData({20'd0, ctrl_reg}), .writeEnable(writeEnable),
        .readEnable(1'b0), .memAddress(30'd0),
        .readData(), .leds(physical_leds)
    );

endmodule
