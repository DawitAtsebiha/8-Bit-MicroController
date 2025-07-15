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
    output reg [2:0] ALU_Sel,
    output reg CCR_Load,
    output reg [1:0] Bus2_Sel,
    output reg [1:0] Bus1_Sel,
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
        LoadStoreOP = (IR == 8'h86) || (IR == 8'h87) || (IR == 8'h88) || 
                      (IR == 8'h89) || (IR == 8'h96) || (IR == 8'h97);
        
        DataOP = (IR == 8'h42) || (IR == 8'h43) || (IR == 8'h44) || (IR == 8'h45) || 
                 (IR == 8'h46) || (IR == 8'h47) || (IR == 8'h48) || (IR == 8'h49);
        
        BranchOP = (IR == 8'h20) || (IR == 8'h21) || (IR == 8'h22) || (IR == 8'h23) || 
                   (IR == 8'h24) || (IR == 8'h25) || (IR == 8'h26) || (IR == 8'h27) || 
                   (IR == 8'h28);
    end

    always @* begin
        // Defaults
        next = state;
        {IR_Load, MAR_Load, PC_Load, PC_Inc, A_Load, B_Load, 
         ALU_Sel, CCR_Load, Bus2_Sel, Bus1_Sel, write} = 11'b0;

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
                else if ((IR == 8'h87) || (IR == 8'h89) || (IR == 8'h96) || (IR == 8'h97)) begin
                    Bus2_Sel = 2'b10;
                    MAR_Load = 1;
                    next = LoadStore3;
                end
                else begin
                    next = Fetch0;
                end
            end

			LoadStore3 : begin          // put data on BUS1, no write yet
				if (IR==8'h96)      
					Bus1_Sel = 2'b01;   // A-reg
				else                
                Bus1_Sel = 2'b10;       // B-reg
				
                next = LoadStore4;     // wait one clk
			end

			LoadStore4 : begin         // data/address already stable
				if (IR==8'h96)      
			    	Bus1_Sel = 2'b01;  // KEEP SAME SOURCE
				else
					Bus1_Sel = 2'b10;
				
                write = 1;             // pulse write
				next  = Fetch0;
			end

            Data: begin
                CCR_Load = 1;
                Bus1_Sel = 2'b01;
                Bus2_Sel = 2'b00;
                A_Load = 1;
                B_Load = 0;

                case(IR)
                    8'h42: ALU_Sel = 3'b000; // ADD
                    8'h43: ALU_Sel = 3'b001; // SUB
                    8'h44: ALU_Sel = 3'b010; // AND
                    8'h45: ALU_Sel = 3'b011; // OR
                    8'h46: ALU_Sel = 3'b100; // INCA

                    8'h47: begin
                        ALU_Sel = 3'b100; // INCB
                        Bus1_Sel = 2'b10; 
                        A_Load = 0;
                        B_Load = 1;       
                    end

                    8'h48: ALU_Sel = 3'b101; // DECA

                    8'h49: begin
                        ALU_Sel = 3'b101; // DECB
                        Bus1_Sel = 2'b10;  
                        A_Load = 0;
                        B_Load = 1;       
                    end
                    default: ALU_Sel = 3'b000; // Default to ADD
                endcase

                next = Fetch0;
            end

            Branch0: begin
                Bus1_Sel = 2'b00;
                Bus2_Sel = 2'b01;
                MAR_Load = 1;
                next = Branch1;
            end

            Branch1: begin
                PC_Inc = 1;
                next = Branch2;
            end

            Branch2: begin
                Bus2_Sel = 2'b10;

                case(IR)
                    8'h20: begin // BRA
                        PC_Load = 1;
                    end
                    8'h21: begin // BCC
                        if (CCR_Result[3]) PC_Load = 1; // Carry Clear
                    end
                    8'h22: begin // BCS
                        if (!CCR_Result[3]) PC_Load = 1; // Carry Set
                    end
                    8'h23: begin // BNE
                        if (CCR_Result[2]) PC_Load = 1; // Not Equal
                    end
                    8'h24: begin // BEQ
                        if (!CCR_Result[2]) PC_Load = 1; // Equal
                    end
                    8'h25: begin // BPL
                        if (CCR_Result[1]) PC_Load = 1; // Positive
                    end
                    8'h26: begin // BMI
                        if (!CCR_Result[1]) PC_Load = 1; // Negative
                    end
                    8'h27: begin // BVC
                        if (CCR_Result[0]) PC_Load = 1; // Overflow Clear
                    end
                    8'h28: begin // BVS
                        if (!CCR_Result[0]) PC_Load = 1; // Overflow Set
                    end
                    default: begin
                        PC_Load = 0; // No branch
                    end
                endcase
                
                next = Fetch0;
            end

            default: next = Fetch0;
        endcase
    end
endmodule