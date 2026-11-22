`timescale 1ns / 1ps

module ADDSUBSYSTEM (
    input [31:0] A,
    input [31:0] B,
    input sub,          // 0 for ADD 1 for SUB
    output [31:0] result
);
    wire [32:0] c;         
    wire [31:0] b_inversed;  
        
    // carry in 1 subt 0 add
    assign c[0] = sub; 
    
    // Invert B if sub is 1
    assign b_inversed = B ^ {32{sub}};

    // combining 32 adders 
    FullAdder fa0  (.A(A[0]),  .B(b_inversed[0]),  .C1(c[0]),  .S(result[0]),  .C2(c[1]));
    FullAdder fa1  (.A(A[1]),  .B(b_inversed[1]),  .C1(c[1]),  .S(result[1]),  .C2(c[2]));
    FullAdder fa2  (.A(A[2]),  .B(b_inversed[2]),  .C1(c[2]),  .S(result[2]),  .C2(c[3]));
    FullAdder fa3  (.A(A[3]),  .B(b_inversed[3]),  .C1(c[3]),  .S(result[3]),  .C2(c[4]));
    FullAdder fa4  (.A(A[4]),  .B(b_inversed[4]),  .C1(c[4]),  .S(result[4]),  .C2(c[5]));
    FullAdder fa5  (.A(A[5]),  .B(b_inversed[5]),  .C1(c[5]),  .S(result[5]),  .C2(c[6]));
    FullAdder fa6  (.A(A[6]),  .B(b_inversed[6]),  .C1(c[6]),  .S(result[6]),  .C2(c[7]));
    FullAdder fa7  (.A(A[7]),  .B(b_inversed[7]),  .C1(c[7]),  .S(result[7]),  .C2(c[8]));
    FullAdder fa8  (.A(A[8]),  .B(b_inversed[8]),  .C1(c[8]),  .S(result[8]),  .C2(c[9]));
    FullAdder fa9  (.A(A[9]),  .B(b_inversed[9]),  .C1(c[9]),  .S(result[9]),  .C2(c[10]));
    FullAdder fa10 (.A(A[10]), .B(b_inversed[10]), .C1(c[10]), .S(result[10]), .C2(c[11]));
    FullAdder fa11 (.A(A[11]), .B(b_inversed[11]), .C1(c[11]), .S(result[11]), .C2(c[12]));
    FullAdder fa12 (.A(A[12]), .B(b_inversed[12]), .C1(c[12]), .S(result[12]), .C2(c[13]));
    FullAdder fa13 (.A(A[13]), .B(b_inversed[13]), .C1(c[13]), .S(result[13]), .C2(c[14]));
    FullAdder fa14 (.A(A[14]), .B(b_inversed[14]), .C1(c[14]), .S(result[14]), .C2(c[15]));
    FullAdder fa15 (.A(A[15]), .B(b_inversed[15]), .C1(c[15]), .S(result[15]), .C2(c[16]));
    FullAdder fa16 (.A(A[16]), .B(b_inversed[16]), .C1(c[16]), .S(result[16]), .C2(c[17]));
    FullAdder fa17 (.A(A[17]), .B(b_inversed[17]), .C1(c[17]), .S(result[17]), .C2(c[18]));
    FullAdder fa18 (.A(A[18]), .B(b_inversed[18]), .C1(c[18]), .S(result[18]), .C2(c[19]));
    FullAdder fa19 (.A(A[19]), .B(b_inversed[19]), .C1(c[19]), .S(result[19]), .C2(c[20]));
    FullAdder fa20 (.A(A[20]), .B(b_inversed[20]), .C1(c[20]), .S(result[20]), .C2(c[21]));
    FullAdder fa21 (.A(A[21]), .B(b_inversed[21]), .C1(c[21]), .S(result[21]), .C2(c[22]));
    FullAdder fa22 (.A(A[22]), .B(b_inversed[22]), .C1(c[22]), .S(result[22]), .C2(c[23]));
    FullAdder fa23 (.A(A[23]), .B(b_inversed[23]), .C1(c[23]), .S(result[23]), .C2(c[24]));
    FullAdder fa24 (.A(A[24]), .B(b_inversed[24]), .C1(c[24]), .S(result[24]), .C2(c[25]));
    FullAdder fa25 (.A(A[25]), .B(b_inversed[25]), .C1(c[25]), .S(result[25]), .C2(c[26]));
    FullAdder fa26 (.A(A[26]), .B(b_inversed[26]), .C1(c[26]), .S(result[26]), .C2(c[27]));
    FullAdder fa27 (.A(A[27]), .B(b_inversed[27]), .C1(c[27]), .S(result[27]), .C2(c[28]));
    FullAdder fa28 (.A(A[28]), .B(b_inversed[28]), .C1(c[28]), .S(result[28]), .C2(c[29]));
    FullAdder fa29 (.A(A[29]), .B(b_inversed[29]), .C1(c[29]), .S(result[29]), .C2(c[30]));
    FullAdder fa30 (.A(A[30]), .B(b_inversed[30]), .C1(c[30]), .S(result[30]), .C2(c[31]));
    FullAdder fa31 (.A(A[31]), .B(b_inversed[31]), .C1(c[31]), .S(result[31]), .C2(c[32]));

endmodule