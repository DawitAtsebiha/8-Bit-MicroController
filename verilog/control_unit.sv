module control_unit (
    input clk,
    input reset,
    input [7:0] IR,
    input [3:0] CCR_Result,
    output reg IR_Load,
    output reg MAR_Load,
    output reg PC_Load,
    output reg PC_Inc,
    output reg A_Load,
    output reg B_Load,
    output reg [3:0] ALU_Sel,
    output reg CCR_Load,
    output reg [1:0] Bus2_Sel,
    output reg [1:0] Bus1_Sel,
    output reg ALU_B_Sel,
    output reg write
);

    parameter [4:0] 
        Fetch0 = 0, Fetch1 = 1, Fetch2 = 2, Decode = 3,
        LoadStore0 = 4, LoadStore1 = 5, LoadStore2 = 6, LoadStore3 = 7, LoadStore4 = 8,
        Data = 9, Branch0 = 10, Branch1 = 11, Branch2 = 12;
    
    reg [4:0] state, next;
    reg LoadStoreOP, DataOP, BranchOP;
    
    always @(posedge clk or negedge reset) begin
        if (!reset) state <= Fetch0;
        else state <= next;
    end

    // Instruction decoding logic - moved outside the main state machine
    always @* begin
        LoadStoreOP = 0;
        DataOP = 0;
        BranchOP = 0;

        case(IR)
            // LoadStore operations
            8'h86, 8'hB6, 8'h88, 8'hB7, 8'h96, 8'h97: LoadStoreOP = 1;
            
            // Data operations
            8'h42, 8'h43, 8'h44, 8'h45, 8'h46, 8'h47, 8'h48, 8'h49, 8'h50, 8'h51, 8'h52: DataOP = 1;
            
            // Branch operations
            8'h20, 8'h21, 8'h22, 8'h23, 8'h24, 8'h25, 8'h26, 8'h27, 8'h28: BranchOP = 1;
        endcase
    end

    always @* begin
        // Defaults
        next = state;
        {IR_Load, MAR_Load, PC_Load, PC_Inc, A_Load, B_Load, 
         ALU_Sel, CCR_Load, Bus2_Sel, Bus1_Sel, ALU_B_Sel, write} = 17'b0;

        case(state)
            Fetch0: begin
                Bus1_Sel = 2'b00;
                Bus2_Sel = 2'b01;
                MAR_Load = 1;
                next = Fetch1;
            end

            Fetch1: begin
                PC_Inc = 1;
                next = Fetch2;
            end

            Fetch2: begin
                Bus2_Sel = 2'b10;
                IR_Load = 1;
                next = Decode;
            end

            Decode: begin 
                if (LoadStoreOP)       next = LoadStore0;
                else if (DataOP)       next = Data;
                else if (BranchOP)     next = Branch0;
                else                  next = Fetch0;
            end

            LoadStore0: begin
                Bus1_Sel = 2'b00;
                Bus2_Sel = 2'b01;
                MAR_Load = 1;
                next = LoadStore1;
            end

            LoadStore1: begin
                PC_Inc = 1;
                next = LoadStore2;
            end

            LoadStore2: begin
                if (IR == 8'h86) begin 
                    Bus2_Sel = 2'b10; 
                    A_Load = 1; 
                    next = Fetch0; 
                end
                else if (IR == 8'h88) begin 
                    Bus2_Sel = 2'b10; 
                    B_Load = 1; 
                    next = Fetch0; 
                end
                else if ((IR == 8'h96) || (IR == 8'h97)) begin
                    Bus2_Sel = 2'b10;
                    MAR_Load = 1;
                    next = LoadStore3;
                end
                else begin
                    next = Fetch0;
                end
            end

			LoadStore3 : begin          
				case (IR)     
                    8'h96: Bus1_Sel = 2'b01; // A Reg for STAA
                    8'h97: Bus1_Sel = 2'b10; // B for STAB
                    8'hB6, 8'hB7: Bus1_Sel = 2'b00; // LDA and LDAB direct (loading, not storing)
                endcase			              
				
                next = LoadStore4;   
			end

			LoadStore4 : begin     
				case(IR) 
			    	8'h96: begin
                        Bus1_Sel = 2'b01;
                        write = 1;
                    end
                    8'h97: begin
                        Bus1_Sel = 2'b10;
                        write = 1;
                    end
                    8'hB6: begin
                        Bus2_Sel = 2'b10;
                        A_Load = 1;
                    end
                    8'hB7: begin
                        Bus2_Sel = 2'b10;
                        B_Load = 1;
                    end
                endcase

				next  = Fetch0;
			end

            Data: begin
                CCR_Load = 1;
                Bus1_Sel = 2'b01;
                Bus2_Sel = 2'b00;
                A_Load = 1;
                B_Load = 0;

                case(IR)
                    8'h42: ALU_Sel = 4'd0; // ADD
                    8'h43: ALU_Sel = 4'd1; // SUB
                    8'h44: ALU_Sel = 4'd2; // Logical AND
                    8'h45: ALU_Sel = 4'd3; // Logical OR
                    8'h46: ALU_Sel = 4'd4; // Bitwise AND
                    8'h47: ALU_Sel = 4'd5; // Bitwise OR
                    8'h48: ALU_Sel = 4'd6; // XOR

                    8'h49: ALU_Sel = 4'd7; // INC A

                    8'h50: begin
                        ALU_Sel = 4'd8; // INCB
                        Bus1_Sel = 2'b10; 
                        A_Load = 0;
                        B_Load = 1;       
                    end

                    8'h51: ALU_Sel = 4'd9; // DECA

                    8'h52: begin
                        ALU_Sel = 4'd10; // DECB
                        Bus1_Sel = 2'b10;  
                        A_Load = 0;
                        B_Load = 1;       
                    end
                    default: ALU_Sel = 4'd0; // Default to ADD
                endcase

                next = Fetch0;
            end

            Branch0: begin
                Bus1_Sel = 2'b00;  // PC (pointing to offset) on Bus1
                Bus2_Sel = 2'b01;  // Bus1 on Bus2
                MAR_Load = 1;      // Load offset address into MAR
                next = Branch1;
            end

            Branch1: begin
                PC_Inc = 1;        // Increment PC to point after instruction
                next = Branch2;
            end

            Branch2: begin
                Bus1_Sel = 2'b00;  // PC on Bus1
                Bus2_Sel = 2'b10;  // from_memory (branch offset) on Bus2
                ALU_Sel = 4'd0;    // ADD operation (PC + offset from memory)
                ALU_B_Sel = 1;     // Use BUS2 as ALU B input (branch offset)

                case(IR)
                    8'h20: PC_Load = 1; // BRA
                    8'h21: begin // BCC
                        if (!CCR_Result[0]) PC_Load = 1; // Carry Clear
                    end
                    8'h22: begin // BCS
                        if (CCR_Result[0]) PC_Load = 1; // Carry Set
                    end
                    8'h23: begin // BNE
                        if (!CCR_Result[2]) PC_Load = 1; // Not Equal
                    end
                    8'h24: begin // BEQ
                        if (CCR_Result[2]) begin
                            PC_Load = 1; // Equal
                            // display("[DEBUG] BEQ instruction, Z flag=%b at time %0t", 
                            // CCR_Result[2], $time);
                        end
                    end
                    8'h25: begin // BPL
                        if (!CCR_Result[3]) PC_Load = 1; // Positive
                    end
                    8'h26: begin // BMI
                        if (CCR_Result[3]) PC_Load = 1; // Negative
                    end
                    8'h27: begin // BVC
                        if (!CCR_Result[1]) PC_Load = 1; // Overflow Clear
                    end
                    8'h28: begin // BVS
                        if (CCR_Result[1]) PC_Load = 1; // Overflow Set
                    end
                    default: PC_Load = 0; // No branch
                endcase
                
                next = Fetch0;
            end

            default: next = Fetch0;
        endcase
    end
endmodule