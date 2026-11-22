`timescale 1ns/1ps

module RegisterFile_tb;

    reg clk, rst, WriteEnable;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] WriteData;
    wire [31:0] ReadData1, ReadData2;

    RegisterFile dut (
        .clk(clk), .rst(rst), .WriteEnable(WriteEnable),
        .rs1(rs1), .rs2(rs2), .rd(rd), .WriteData(WriteData),
        .ReadData1(ReadData1), .ReadData2(ReadData2)
    );

    always #5 clk = ~clk; // 10ns clock period

    initial begin
        clk = 0; rst = 1; WriteEnable = 0;
        rs1 = 0; rs2 = 0; rd = 0; WriteData = 0;
        #12 rst = 0;

        // Test 1: write x5, read it back on both ports
        @(negedge clk);
        rd = 5; WriteData = 32'hDEADBEEF; WriteEnable = 1;
        @(negedge clk);
        WriteEnable = 0; rs1 = 5; rs2 = 5;
        #1;
        if (ReadData1 == 32'hDEADBEEF && ReadData2 == 32'hDEADBEEF)
            $display("Test 1 PASSED: write/read x5");
        else
            $display("Test 1 FAILED: did not correctly write/read x5");

        // Test 2: write to x0, confirm it stays 0
        @(negedge clk);
        rd = 0; WriteData = 32'hFFFFFFFF; WriteEnable = 1;
        @(negedge clk);
        WriteEnable = 0; rs1 = 0;
        #1;
        if (ReadData1 == 32'd0)
            $display("Test 2 PASSED: x0 stays zero");
        else
            $display("Test 2 FAILED: x0 should stay zero");

        // Test 3: two different registers, read both ports at once
        @(negedge clk);
        rd = 6; WriteData = 32'h11111111; WriteEnable = 1;
        @(negedge clk);
        rd = 7; WriteData = 32'h22222222; WriteEnable = 1;
        @(negedge clk);
        WriteEnable = 0; rs1 = 6; rs2 = 7;
        #1;
        if (ReadData1 == 32'h11111111 && ReadData2 == 32'h22222222)
            $display("Test 3 PASSED: simultaneous reads");
        else
            $display("Test 3 FAILED: simultaneous reads not shown");

        // Test 4: overwrite x5 with a new value
        @(negedge clk);
        rd = 5; WriteData = 32'hCAFEDEAD; WriteEnable = 1;
        @(negedge clk);
        WriteEnable = 0; rs1 = 5;
        #1;
        if (ReadData1 == 32'hCAFEDEAD)
            $display("Test 4 PASSED: overwrite x5");
        else
            $display("Test 4 FAILED: didnt overwrite x5");

        // Test 5: reset clears everything
        @(negedge clk);
        rst = 1;
        @(negedge clk);
        rst = 0; rs1 = 5;
        #1;
        if (ReadData1 == 32'd0)
            $display("Test 5 PASSED: reset clears registers");
        else
            $display("Test 5 FAILED: reset clears registers");

        $display("All tests complete.");
        $stop;
    end

endmodule
