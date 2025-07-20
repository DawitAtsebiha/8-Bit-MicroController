module ALU(
    input [7:0] reg_data_A,      
    input [7:0] reg_data_B,
    input [3:0] ALU_Sel,
    output reg [3:0] NZVC,  // Flags: [N, Z, V, C]
    output reg [7:0] Result
);
    reg [8:0] temp;  // 9-bit for carry/borrow detection

    always @* begin
        {Result, temp, NZVC} = {8'b0, 9'b0, 4'b0};
        
        case(ALU_Sel)
            // ADD;

            4'd0: begin
                temp = {1'b0, reg_data_A} + {1'b0, reg_data_B};                  
                Result = temp[7:0];
                NZVC[3] = Result[7];                            // Negative
                NZVC[2] = ~|Result;                             // Zero
                NZVC[1] = (reg_data_A[7] & reg_data_B[7] & ~Result[7]) |          // Overflow
                         (~reg_data_A[7] & ~reg_data_B[7] & Result[7]);
                NZVC[0] = temp[8];                              // Carry
            end
            
            // SUB
            4'd1: begin
                temp = {1'b0, reg_data_A} - {1'b0, reg_data_B};
                Result = temp[7:0];
                NZVC[3] = Result[7];                            // Negative
                NZVC[2] = ~|Result;                             // Zero
                NZVC[1] = (reg_data_A[7] & ~reg_data_B[7] & ~Result[7]) |         // Overflow
                         (~reg_data_A[7] & reg_data_B[7] & Result[7]);
                NZVC[0] = temp[8];                              // Borrow
            end
            
            // Logical AND
            4'd2: begin
                Result = reg_data_A != 0 && reg_data_B != 0 ? 8'h01 : 8'h00; 
                NZVC[3] = Result[7];                            // Negative
                NZVC[2] = ~|Result;                             // Zero
            end
            
            // Logical OR
            4'd3: begin
                Result = reg_data_A != 0 || reg_data_B != 0 ? 8'h01 : 8'h00;
                NZVC[3] = Result[7];                            // Negative
                NZVC[2] = ~|Result;                             // Zero
            end

            // Bitwise AND
            4'd4: begin
                Result = reg_data_A & reg_data_B;
                NZVC[3] = Result[7];                           // Negative
                NZVC[2] = ~|Result;                             // Zero
            end

            // Bitwise OR
            4'd5: begin
                Result = reg_data_A | reg_data_B;
                NZVC[3] = Result[7];                           // Negative
                NZVC[2] = ~|Result;                             // Zero
            end

            // XOR
            4'd6: begin
                Result = reg_data_A ^ reg_data_B;
                NZVC[3] = Result[7];                           // Negative
                NZVC[2] = ~|Result;                             // Zero
            end
            
            // INC (A + 1)
            4'd7: begin
                temp = {1'b0, reg_data_A} + 9'b1;
                Result = temp[7:0];
                NZVC[3] = Result[7];                            // Negative
                NZVC[2] = ~|Result;                             // Zero
                NZVC[1] = (reg_data_A == 8'h7F);                // Overflow
                NZVC[0] = temp[8];                              // Carry
            end
            // DEC (A - 1)
            4'd8: begin
                temp = {1'b0, reg_data_A} - 9'b1;
                Result = temp[7:0];
                NZVC[3] = Result[7];                            // Negative
                NZVC[2] = ~|Result;                             // Zero
                NZVC[1] = (reg_data_A == 8'h00);                // Overflow
                NZVC[0] = temp[8];                              // Borrow
            end           
            
            default: Result = 8'b0;
        endcase
    end
endmodule
