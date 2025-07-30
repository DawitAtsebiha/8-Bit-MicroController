module ALU(
    input [7:0] reg_data_A,      
    input [7:0] reg_data_B,
    input [3:0] ALU_Sel,
    output reg [3:0] NZVC,  // Flags: [N, Z, V, C]
    output reg [7:0] Result
);
    reg [8:0] temp;  // 9-bit for carry/borrow detection

	localparam ADD = 4'd0, SUB = 4'd1,
			LAND= 4'd2, LOR = 4'd3,
			BAND= 4'd4, BOR = 4'd5, XOR = 4'd6,
			INC = 4'd7, DEC = 4'd8;
					
	always @* begin
        {Result, temp, NZVC} = {8'b0, 9'b0, 4'b0};
        
        case(ALU_Sel)
            ADD: temp = {1'b0, reg_data_A} + {1'b0, reg_data_B};                         
            SUB: temp = {1'b0, reg_data_A} - {1'b0, reg_data_B};            				  
            LAND: Result = reg_data_A != 0 && reg_data_B != 0 ? 8'h01 : 8'h00;           
            LOR: Result = reg_data_A != 0 || reg_data_B != 0 ? 8'h01 : 8'h00;             
            BAND: Result = reg_data_A & reg_data_B;            									 
            BOR: Result = reg_data_A | reg_data_B;                                        
            XOR: Result = reg_data_A ^ reg_data_B;                                        
            INC: temp = {1'b0, reg_data_A} + 9'b1;                                        
            DEC: temp = {1'b0, reg_data_A} - 9'b1;                                       
        endcase
		  
		if (ALU_Sel==ADD || ALU_Sel==SUB || ALU_Sel==INC || ALU_Sel==DEC)
				Result = temp[7:0];
				
		NZVC[3] = Result[7];                 // N
        NZVC[2] = ~|Result;                  // Z

        // Overflow & Carry/Borrow only for arithmetic
        if (ALU_Sel==ADD || ALU_Sel==INC) begin
            NZVC[1] = (reg_data_A[7]^Result[7]) & ~(reg_data_A[7]^reg_data_B[7]); // V
            NZVC[0] = temp[8];                                                    // C
        end
        else if (ALU_Sel==SUB || ALU_Sel==DEC) begin
            NZVC[1] = (reg_data_A[7]^Result[7]) &  (reg_data_A[7]^reg_data_B[7]); // V for sub
            NZVC[0] = temp[8];                                                    // Borrow
        end
    end
endmodule
