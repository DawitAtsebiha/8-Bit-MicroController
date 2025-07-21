module control_unit (
    input clk,
    input reset,
    input debug_inner,
    input [7:0] IR,
    input [7:0] from_memory,
    input [3:0] CCR_Result,
    output reg IR_Load,
    output reg MAR_Load,
    input [7:0] PC,
    output reg PC_Load,
    output reg PC_Inc,
    output reg [3:0] reg_read_addr_A,
    output reg [3:0] reg_read_addr_B,
    output reg [3:0] reg_write_addr,
    output reg reg_write_enable,
    output reg [3:0] ALU_Sel,
    output reg CCR_Load,
    output reg [2:0] Bus2_Sel,
    output reg [1:0] Bus1_Sel,
    output reg ALU_B_Sel,
    output reg write,
    output reg [7:0] immediate_out,
    output reg [7:0] address_out,
    output reg addr_sel
);

    parameter [5:0] 
        Fetch0 = 0, Fetch1 = 1, Fetch2 = 2, 
        Decode = 10, Execute = 11,
        LoadStore0 = 20, LoadStore1 = 21, LoadStore2 = 22, LoadStore3 = 23, LoadStore4 = 24, LoadStore5 = 25,
        Data0 = 30, Data1 = 31, Data2 = 32, Data3 = 33,
        Branch0 = 40, Branch1 = 41, Branch2 = 42;

    reg [5:0] state, next;
    reg LoadStoreOP, DataOP, BranchOP;
    reg [7:0] reg_operand_1, reg_operand_2; // First (destination) and Second (source) register operands
    reg [7:0] immediate_value; // Storage for immediate values
    
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            state <= Fetch0;
            reg_operand_1 <= 8'h00;
            reg_operand_2 <= 8'h00;
            immediate_value <= 8'h00;
            addr_sel <= 1'b0;  // Default to PC addressing

        end else begin
            state <= next;
            
            // Capture operands as they're fetched
            case(state)
                LoadStore2: begin
                    if (LoadStoreOP) begin
                        reg_operand_1 <= from_memory;  // Register operand for load/store
                    end else if (DataOP) begin
                        reg_operand_2 <= from_memory;  // Second operand for two-register data ops
                    end
                end
                LoadStore4: begin
                    if (LoadStoreOP && IR == 8'h80) begin
                        // Don't capture here - immediate will be read in LoadStore4
                    end else if (LoadStoreOP && (IR == 8'h81 || IR == 8'h82)) begin
                        reg_operand_2 <= from_memory;  // Capture address for LD/ST direct
                    end
                    // Remove DataOP capture here - second operand already captured in LoadStore2
                end
                Data2: begin
                    reg_operand_1 <= from_memory;  // First register for data ops
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
         ALU_Sel, CCR_Load, Bus2_Sel, Bus1_Sel, ALU_B_Sel, write} = 18'b0;
        immediate_out = immediate_value;  // Output captured immediate value
        address_out = reg_operand_2;     // Output captured address value
        addr_sel = 1'b0;                 // Default to PC addressing for instruction fetches

        {reg_read_addr_A, reg_read_addr_B, reg_write_addr} = 12'b0;

        case(state)
            Fetch0: begin
                Bus1_Sel = 2'b00;
                Bus2_Sel = 3'b001;
                MAR_Load = 1;
                next = Fetch1;
            end

            Fetch1: begin
                // Don't increment PC yet - wait until instruction is loaded
                next = Fetch2;
            end

            Fetch2: begin
                // Wait one cycle for ROM synchronization
                next = Decode;
            end

            Decode: begin 
                Bus2_Sel = 3'b010;  // Select from_memory
                IR_Load = 1;        // Load instruction after ROM has stabilized
                PC_Inc = 1;         // NOW increment PC to point to operands
                next = Execute;     // Go to Execute state for actual decode logic
            end

            Execute: begin 
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
                Bus2_Sel = 3'b001;    // Bus1
                MAR_Load = 1;
                next = Data1;
            end

            Data1: begin // Fetches first register operand
                PC_Inc = 1;
                next = Data2;
            end

            Data2: begin
                Bus2_Sel = 3'b010;         
                addr_sel = 1'b1;     // Use MAR for first operand access
                next = Data3;
            end

            Data3: begin
                Bus1_Sel = 2'b00;
                Bus2_Sel = 3'b001;  
                MAR_Load = 1;
                next = LoadStore1; // Fetches second register operand
            end

            LoadStore0: begin
                Bus1_Sel = 2'b00;    // PC on Bus1 (should now point to register operand)
                Bus2_Sel = 3'b001;   // Bus1 on Bus2
                MAR_Load = 1;        // Load PC into MAR to fetch register operand
                next = LoadStore1;
            end

            LoadStore1: begin
                // Don't increment PC yet - need to capture register operand first
                next = LoadStore2;
            end

            LoadStore2: begin
                Bus2_Sel = 3'b010;
                PC_Inc = 1;          // NOW increment PC after setting up register operand capture

                if (DataOP && IR[7:4] == 4'hA) begin // All single-register operations (INC, DEC)
                    CCR_Load = 1; 
                    Bus1_Sel = 2'b01;
                    Bus2_Sel = 3'b000;
                    addr_sel = 1'b1;     // Use MAR for operand access

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
                        8'h80: begin  // LD immediate - PC already incremented in Decode
                            next = LoadStore3;
                        end
                        8'h81: begin  // LD direct
                            next = LoadStore3;  // Need to get address
                        end
                        8'h82: begin  // ST direct
                            next = LoadStore3;  // Need to get address
                        end
                        default: next = Fetch0;
                    endcase

                end else if (DataOP && IR[7:4] == 4'h9) begin // For two-register data operations
                    addr_sel = 1'b1;     // Use MAR for second operand access
                    next = LoadStore3;
                end

                else
                    next = Fetch0;
            end

            LoadStore3: begin
                if (IR == 8'h80) begin  // LD immediate - need to set up address for immediate value
                    Bus1_Sel = 2'b00;    // PC on Bus1 (should point to immediate value)
                    Bus2_Sel = 3'b001;   // Bus1 on Bus2
                    MAR_Load = 1;        // Load PC into MAR to fetch immediate
                    next = LoadStore4;
                end else begin  // LD/ST direct - load address into MAR
                    Bus2_Sel = 3'b100;  // Select captured address value
                    MAR_Load = 1;
                    next = LoadStore4;
                end
            end

            LoadStore4: begin
                if (IR == 8'h80) begin  // LD immediate - now ROM output should be stable
                    reg_write_addr = reg_operand_1[3:0];
                    reg_write_enable = 1;
                    Bus2_Sel = 3'b010;  // Use from_memory for immediate value
                    PC_Inc = 1;         // Increment PC to point to next instruction
                    next = Fetch0;
                end else if (DataOP && IR[7:4] == 4'h9) begin // 2nd register operand captured in clocked block
                    PC_Inc = 1;
                    next = LoadStore5;
                
                end else if (LoadStoreOP) begin
                    case(IR)
                        8'h81: begin  // LD direct
                            PC_Inc = 1;  // Increment PC past address
                            next = LoadStore5;
                        end

                        8'h82: begin  // ST direct
                            reg_read_addr_A = reg_operand_1[3:0];
                            Bus1_Sel = 2'b01;
                            write = 1;
                            PC_Inc = 1;  // Increment PC past address
                            next = Fetch0;
                        end
                        default: next = Fetch0;
                    endcase

                end else next = Fetch0;
            end

            LoadStore5: begin
                if (IR == 8'h80) begin  // LD immediate - complete the load operation
                    reg_write_addr = reg_operand_1[3:0];
                    reg_write_enable = 1;
                    Bus2_Sel = 3'b010;  // Use from_memory for immediate value
                    next = Fetch0;
                end else if (DataOP && IR[7:4] == 4'h9) begin // Execute two-register data operations
                    CCR_Load = 1;
                    Bus1_Sel = 2'b01;
                    Bus2_Sel = 3'b000;

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
                    addr_sel = 1'b1;     // Use MAR for data memory access
                    Bus2_Sel = 3'b010;    // from_memory
                    reg_write_addr = reg_operand_1[3:0];
                    reg_write_enable = 1;
                end
                else if (LoadStoreOP && IR == 8'h82) begin
                    // ST direct - write register to memory address
                    addr_sel = 1'b1;     // Use MAR for data memory access
                    Bus1_Sel = 2'b01;    // reg_data_A to Bus1
                    write = 1;           // Write to memory
                end
                next = Fetch0;
            end

            Branch0: begin
                Bus1_Sel = 2'b00;  // PC (pointing to offset) on Bus1
                Bus2_Sel = 3'b001;  // Bus1 on Bus2
                MAR_Load = 1;      // Load offset address into MAR
                next = Branch1;
            end

            Branch1: begin
                PC_Inc = 1;        // Increment PC to point after instruction
                next = Branch2;
            end

            Branch2: begin
                Bus1_Sel = 2'b00;  // PC on Bus1
                Bus2_Sel = 3'b010;  // from_memory (branch offset) on Bus2
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

        if (debug_inner) begin
            case (state)
                Fetch0: $display("[FETCH] PC=0x%02h", PC);
                Decode: $display("[DECODE] IR=0x%02h", IR);
                Execute: $display("[EXEC] IR=0x%02h → %s", IR, 
                                LoadStoreOP ? "LOAD" : DataOP ? "ALU" : BranchOP ? "BRANCH" : "None");
                LoadStore2: $display("[LD/ST] Captured operand=0x%02h", from_memory);
                LoadStore4: $display("[LD] Writing 0x%02h to reg %0d", from_memory, reg_operand_1[3:0]);
                LoadStore5: begin
                    if (DataOP && IR[7:4] == 4'h9) // Two-register ALU
                        $display("[ALU] %s: reg%0d %s reg%0d", 
                                IR == 8'h90 ? "ADD" : IR == 8'h91 ? "SUB" : "ALU",
                                reg_operand_1[3:0], 
                                IR == 8'h90 ? "+" : IR == 8'h91 ? "-" : "op",
                                reg_operand_2[3:0]);
                end
                Branch2: $display("[BRANCH] PC=%0d → %0d", PC, PC + from_memory);
            endcase
        end
    end
endmodule
