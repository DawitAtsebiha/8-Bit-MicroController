module ALU(
    input [7:0] A, B,
    input [2:0] ALU_Sel,
    output reg [3:0] NZVC,  // Flags: [N, Z, V, C]
    output reg [7:0] Result
);
    reg [8:0] temp;  // 9-bit for carry/borrow detection

    always @* begin
        {Result, temp, NZVC} = {8'b0, 9'b0, 4'b0};
        
        case(ALU_Sel)
            // ADD
            3'b000: begin
                temp = {1'b0, A} + {1'b0, B};
                Result = temp[7:0];
                NZVC[3] = Result[7];                            // Negative
                NZVC[2] = (Result == 0);                         // Zero
                NZVC[1] = (A[7] & B[7] & ~Result[7]) |           // Overflow
                         (~A[7] & ~B[7] & Result[7]);
                NZVC[0] = temp[8];                              // Carry
            end
            
            // SUB
            3'b001: begin
                temp = {1'b0, A} - {1'b0, B};
                Result = temp[7:0];
                NZVC[3] = Result[7];                            // Negative
                NZVC[2] = (Result == 0);                         // Zero
                NZVC[1] = (A[7] & ~B[7] & ~Result[7]) |          // Overflow
                         (~A[7] & B[7] & Result[7]);
                NZVC[0] = temp[8];                              // Borrow
            end
            
            // AND
            3'b010: begin
                Result = A & B;
                NZVC[3] = Result[7];                            // Negative
                NZVC[2] = (Result == 0);                         // Zero
            end
            
            // OR
            3'b011: begin
                Result = A | B;
                NZVC[3] = Result[7];                            // Negative
                NZVC[2] = (Result == 0);                         // Zero
            end
            
            // INC (A + 1)
            3'b100: begin
                temp = {1'b0, A} + 9'b1;
                Result = temp[7:0];
                NZVC[3] = Result[7];                            // Negative
                NZVC[2] = (Result == 0);                         // Zero
                NZVC[1] = (A == 8'h7F);                         // Overflow
                NZVC[0] = temp[8];                              // Carry
            end
            
            // DEC (A - 1)
            3'b101: begin
                temp = {1'b0, A} - 9'b1;
                Result = temp[7:0];
                NZVC[3] = Result[7];                            // Negative
                NZVC[2] = (Result == 0);                         // Zero
                NZVC[1] = (A == 8'h80);                         // Overflow
                NZVC[0] = temp[8];                              // Borrow
               
            end
            
            default: Result = 8'b0;
        endcase
    end
endmodule
