module control_unit (
    input clk,
    input reset,
    input [7:0] IR,
    input [7:0] from_memory,
    input [3:0] CCR_Result,
    output reg IR_Load,
    output reg MAR_Load,
    output reg PC_Load,
    output reg PC_Inc,
    output reg [3:0] reg_read_addr_A,
    output reg [3:0] reg_read_addr_B,
    output reg [3:0] reg_write_addr,
    output reg reg_write_enable,
    output reg [3:0] ALU_Sel,
    output reg CCR_Load,
    output reg [1:0] Bus2_Sel,
    output reg [1:0] Bus1_Sel,
    output reg ALU_B_Sel,
    output reg write
);

    parameter [4:0] 
        Fetch0 = 0, Fetch1 = 1, Fetch2 = 2, Decode = 3,
        LoadStore0 = 4, LoadStore1 = 5, LoadStore2 = 6, LoadStore3 = 7, LoadStore4 = 8, LoadStore5 = 9,
        Data0 = 10, Data1 = 11, Data2 = 12, Data3 = 13, 
        Branch0 = 14, Branch1 = 15, Branch2 = 16;

    reg [4:0] state, next;
    reg LoadStoreOP, DataOP, BranchOP;
    reg [7:0] reg_operand_1, reg_operand_2; // First (destination) and Second (source) register operands
    
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            state <= Fetch0;
            reg_operand_1 <= 8'h00;
            reg_operand_2 <= 8'h00;

        end else begin
            state <= next;
            
            // Capture operands as they're fetched
            case(state)
                LoadStore2: begin
                    reg_operand_1 <= from_memory;  // First operand (register for load/store)
                end
                Data2: begin
                    reg_operand_1 <= from_memory;  // First register for data ops
                end
                LoadStore4: begin
                    if (DataOP) begin
                        reg_operand_2 <= from_memory;  // Second register for data ops
                    end
                end
            endcase
        end
    end

    // Instruction decoding logic - moved outside the main state machine
    always @* begin
        LoadStoreOP = 0;
        DataOP = 0;
        BranchOP = 0;

        case(IR[7:4]) // The upper 4 bits define the operation type
            4'h8: LoadStoreOP = 1;  // 0x80-0x8F: Load/Store operations
            4'h9: DataOP = 1;       // 0x90-0x9F: Data operations  
            4'hA: DataOP = 1;       // 0xA0-0xAF: Single register operations
            4'h2: BranchOP = 1;     // 0x20-0x2F: Branch operations
            default: LoadStoreOP = 0;
        endcase
    end

    always @* begin
        // Defaults
        next = state;
        {IR_Load, MAR_Load, PC_Load, PC_Inc, reg_write_enable, 
         ALU_Sel, CCR_Load, Bus2_Sel, Bus1_Sel, ALU_B_Sel, write} = 15'b0;

        {reg_read_addr_A, reg_read_addr_B, reg_write_addr} = 12'b0;

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
                if (LoadStoreOP)       
                    next = LoadStore0;

                else if (DataOP) begin
                    case(IR[7:4])
                        4'h9: next = Data0;        // Two-register ops need 2 operands
                        4'hA: next = LoadStore0;   // Single-register ops only need 1 operand
                        default: next = Fetch0;
                    endcase
                end

                else if (BranchOP)     
                    next = Branch0;

                else                  
                    next = Fetch0;
            end

            Data0: begin
                Bus1_Sel = 2'b00;    // PC
                Bus2_Sel = 2'b01;    // Bus1
                MAR_Load = 1;
                next = Data1;
            end

            Data1: begin // Fetches first register operand
                PC_Inc = 1;
                next = Data2;
            end

            Data2: begin
                Bus2_Sel = 2'b10;         
                next = Data3;
            end

            Data3: begin
                Bus1_Sel = 2'b00;
                Bus2_Sel = 2'b01;  
                MAR_Load = 1;
                next = LoadStore1; // Fetches second register operand
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
                Bus2_Sel = 2'b10;

                if (DataOP && IR[7:4] == 4'hA) begin // All single-register operations (INC, DEC)
                    CCR_Load = 1; 
                    Bus1_Sel = 2'b01;
                    Bus2_Sel = 2'b00;

                    case(IR)
                        8'hA0: begin  // INC reg
                            reg_read_addr_A = reg_operand_1[3:0];
                            reg_read_addr_B = reg_operand_2[3:0];
                            reg_write_addr = reg_operand_1[3:0];
                            reg_write_enable = 1;
                            ALU_Sel = 4'd7; 
                        end

                        8'hA1: begin  // DEC reg
                            reg_read_addr_A = reg_operand_1[3:0];
                            reg_write_addr = reg_operand_1[3:0];
                            reg_write_enable = 1;
                            ALU_Sel = 4'd8;  // DEC
                        end
                        default: ALU_Sel = 4'd8;
                    endcase
                    next = Fetch0;
                
                end else if (LoadStoreOP) begin // For Load and Store operations
                    case(IR)
                        8'h80: begin  // LD immediate
                            next = LoadStore3;  // Need to get immediate value
                        end
                        8'h81: begin  // LD direct
                            next = LoadStore3;  // Need to get address
                        end
                        8'h82: begin  // ST direct
                            next = LoadStore3;  // Need to get address
                        end
                        default: next = Fetch0;
                    endcase

                end else if (DataOP && IR[7:4] == 4'h9) // For two-register data operations
                    next = LoadStore3;

                else
                    next = Fetch0;
            end

            LoadStore3: begin
                Bus1_Sel = 2'b00;
                Bus2_Sel = 2'b01;
                MAR_Load = 1;
                next = LoadStore4;
            end

            LoadStore4: begin
                PC_Inc = 1;
                Bus2_Sel = 2'b10;

                if (DataOP && IR[7:4] == 4'h9) begin // 2nd register operand captured in clocked block
                    next = LoadStore5;
                
                end else if (LoadStoreOP) begin
                    case(IR)
                        8'h80: begin  // LD immediate
                            reg_write_addr = reg_operand_1[3:0];
                            reg_write_enable = 1;
                            next = Fetch0;
                        end

                        8'h81: begin  // LD direct
                            MAR_Load = 1;  
                            next = LoadStore5;
                        end

                        8'h82: begin  // ST direct
                            MAR_Load = 1;  
                            reg_read_addr_A = reg_operand_1[3:0];
                            Bus1_Sel = 2'b01;
                            write = 1;
                            next = Fetch0;
                        end
                        default: next = Fetch0;
                    endcase

                end else if (LoadStoreOP) begin
                    case(IR)
                        8'h80: begin  // LD immediate
                            reg_write_addr = reg_operand_1[3:0];
                            reg_write_enable = 1;
                            next = Fetch0;
                        end
                        8'h81: begin  // LD direct
                            MAR_Load = 1;    // Load address
                            next = LoadStore5;
                        end
                        8'h82: begin  // ST direct
                            MAR_Load = 1;  
                            reg_read_addr_A = reg_operand_1[3:0];
                            next = LoadStore5;  // Go to next state to complete the write
                        end
                        default: next = Fetch0;
                    endcase
                end else next = Fetch0;
            end

            LoadStore5: begin
                if (DataOP && IR[7:4] == 4'h9) begin // Execute two-register data operations
                    CCR_Load = 1;
                    Bus1_Sel = 2'b01;
                    Bus2_Sel = 2'b00;

                    case(IR)
                        8'h90: begin  // ADD reg1, reg2
                            reg_read_addr_A = reg_operand_1[3:0];
                            reg_read_addr_B = reg_operand_2[3:0];
                            reg_write_addr = reg_operand_1[3:0];
                            reg_write_enable = 1;
                            ALU_Sel = 4'd0;  // ADD
                        end
                        8'h91: begin  // SUB reg1, reg2
                            reg_read_addr_A = reg_operand_1[3:0];
                            reg_read_addr_B = reg_operand_2[3:0];
                            reg_write_addr = reg_operand_1[3:0];
                            reg_write_enable = 1;
                            ALU_Sel = 4'd1;  // SUB
                        end
                        8'h92: begin  // AND reg1, reg2
                            reg_read_addr_A = reg_operand_1[3:0];
                            reg_read_addr_B = reg_operand_2[3:0];
                            reg_write_addr = reg_operand_1[3:0];
                            reg_write_enable = 1;
                            ALU_Sel = 4'd4;  // AND
                        end
                        8'h93: begin  // OR reg1, reg2
                            reg_read_addr_A = reg_operand_1[3:0];
                            reg_read_addr_B = reg_operand_2[3:0];
                            reg_write_addr = reg_operand_1[3:0];
                            reg_write_enable = 1;
                            ALU_Sel = 4'd5;  // OR
                        end
                        8'h94: begin  // XOR reg1, reg2
                            reg_read_addr_A = reg_operand_1[3:0];
                            reg_read_addr_B = reg_operand_2[3:0];
                            reg_write_addr = reg_operand_1[3:0];
                            reg_write_enable = 1;
                            ALU_Sel = 4'd6;  // XOR
                        end
                        default: ALU_Sel = 4'd0;
                    endcase
                end
                else if (LoadStoreOP && IR == 8'h81) begin
                    // LD direct - read from memory address
                    Bus2_Sel = 2'b10;    // from_memory
                    reg_write_addr = reg_operand_1[3:0];
                    reg_write_enable = 1;
                end
                else if (LoadStoreOP && IR == 8'h82) begin
                    // ST direct - write register to memory address
                    Bus1_Sel = 2'b01;    // reg_data_A to Bus1
                    write = 1;           // Write to memory
                end
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
                    8'h21: if (!CCR_Result[0]) PC_Load = 1; // BCC
                    8'h22: if (CCR_Result[0]) PC_Load = 1;  // BCS
                    8'h23: if (!CCR_Result[2]) PC_Load = 1; // BNE
                    8'h24: if (CCR_Result[2]) PC_Load = 1;  // BEQ
                    8'h25: if (!CCR_Result[3]) PC_Load = 1; // BPL
                    8'h26: if (CCR_Result[3]) PC_Load = 1;  // BMI
                    8'h27: if (!CCR_Result[1]) PC_Load = 1; // BVC
                    8'h28: if (CCR_Result[1]) PC_Load = 1;  // BVS
                    default: PC_Load = 0;
                endcase
                
                next = Fetch0;
            end

            default: next = Fetch0;
        endcase
    end
endmodule