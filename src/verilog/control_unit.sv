module control_unit (
    input logic clk,
    input logic reset,
    input logic debug_inner,
    input logic [7:0] IR,
    input logic [7:0] from_memory,
    input logic [3:0] CCR_Result,
    output logic IR_Load,
    output logic MAR_Load,
    output logic PC_Load,
    output logic PC_Inc,
    output logic [3:0] reg_read_addr_A,
    output logic [3:0] reg_read_addr_B,
    output logic [3:0] reg_write_addr,
    output logic reg_write_enable,
    output logic [3:0] ALU_Sel,
    output logic CCR_Load,
    output logic [2:0] Bus2_Sel,
    output logic [1:0] Bus1_Sel,
    output logic ALU_B_Sel,
    output logic write,
    output logic [7:0] immediate_out,
    output logic [7:0] address_out,
    output logic addr_sel
);

    // Simplified states that match your original timing
    typedef enum logic [3:0] {
        FETCH0, FETCH1, FETCH2, DECODE, EXECUTE,
        LOADSTORE0, LOADSTORE1, LOADSTORE2, LOADSTORE3, LOADSTORE4, LOADSTORE5,
        DATA0, DATA1, DATA2, DATA3,
        BRANCH0, BRANCH1, BRANCH2
    } state_t;

    state_t state;
    logic [7:0] reg_operand_1, reg_operand_2;
    logic [7:0] immediate_value;
    logic LoadStoreOP, DataOP, BranchOP;

    // Instruction decode (matches your original logic)
    always_comb begin
        LoadStoreOP = (IR[7:4] == 4'h8);
        DataOP = (IR[7:4] == 4'h9) || (IR[7:4] == 4'hA);
        BranchOP = (IR[7:4] == 4'h2);
    end

    // State machine with proper timing
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            state <= FETCH0;
            reg_operand_1 <= '0;
            reg_operand_2 <= '0;
            immediate_value <= '0;
            addr_sel <= 1'b0;
        end else begin
            case (state)
                FETCH0: state <= FETCH1;
                FETCH1: state <= FETCH2;
                FETCH2: state <= DECODE;
                DECODE: state <= EXECUTE;
                
                EXECUTE: begin
                    if (LoadStoreOP)       
                        state <= LOADSTORE0;
                    else if (DataOP) begin
                        case (IR[7:4])
                            4'h9: state <= DATA0;      // Two-register ALU
                            4'hA: state <= LOADSTORE0; // Single-register ALU
                            default: state <= FETCH0;
                        endcase
                    end
                    else if (BranchOP)     
                        state <= BRANCH0;
                    else                  
                        state <= FETCH0;
                end

                // Data operations (two-register ALU)
                DATA0: state <= DATA1;
                DATA1: state <= DATA2;
                DATA2: begin
                    reg_operand_1 <= from_memory;
                    if (debug_inner) $display("[DEBUG] DATA2: Captured first operand=0x%02h", from_memory);
                    state <= DATA3;
                end
                DATA3: state <= LOADSTORE1;

                // Load/Store and single-register operations
                LOADSTORE0: state <= LOADSTORE1;
                LOADSTORE1: state <= LOADSTORE2;
                LOADSTORE2: begin
                    if (LoadStoreOP) begin
                        reg_operand_1 <= from_memory;
                        if (debug_inner) $display("[DEBUG] LOADSTORE2: Captured register operand=0x%02h for IR=0x%02h", from_memory, IR);
                    end else if (DataOP) begin
                        reg_operand_2 <= from_memory;
                        if (debug_inner) $display("[DEBUG] LOADSTORE2: Captured second operand=0x%02h", from_memory);
                    end
                    state <= LOADSTORE3;
                end
                
                LOADSTORE3: begin
                    if (IR == 8'h80 || (DataOP && IR[7:4] == 4'hA)) // LD immediate or single-reg ALU
                        state <= LOADSTORE4;
                    else
                        state <= LOADSTORE5;
                end
                
                LOADSTORE4: begin
                    if (LoadStoreOP) begin
                        reg_operand_2 <= from_memory;
                        if (debug_inner) $display("[DEBUG] LOADSTORE4: Captured immediate/address=0x%02h", from_memory);
                    end
                    state <= LOADSTORE5;
                end
                
                LOADSTORE5: state <= FETCH0;

                // Branch operations
                BRANCH0: state <= BRANCH1;
                BRANCH1: state <= BRANCH2;
                BRANCH2: state <= FETCH0;

                default: state <= FETCH0;
            endcase
        end
    end

    // Control signal generation (matches your original CPU expectations)
    always_comb begin
        // Defaults
        {IR_Load, MAR_Load, PC_Load, PC_Inc, reg_write_enable, CCR_Load, write, ALU_B_Sel, addr_sel} = '0;
        {reg_read_addr_A, reg_read_addr_B, reg_write_addr, ALU_Sel} = '0;
        {Bus2_Sel, Bus1_Sel} = '0;
        immediate_out = immediate_value;
        address_out = reg_operand_2;

        case (state)
            FETCH0: begin
                {Bus1_Sel, Bus2_Sel, MAR_Load} = {2'b00, 3'b001, 1'b1};
            end
            
            FETCH2: begin
                {Bus2_Sel, IR_Load, PC_Inc} = {3'b010, 1'b1, 1'b1};
            end
            
            // Two-register data operations
            DATA0: begin
                {Bus1_Sel, Bus2_Sel, MAR_Load} = {2'b00, 3'b001, 1'b1};
            end
            DATA1: begin
                PC_Inc = 1'b1;
            end
            DATA3: begin
                {Bus1_Sel, Bus2_Sel, MAR_Load} = {2'b00, 3'b001, 1'b1};
            end

            // Load/Store operations
            LOADSTORE0: begin
                {Bus1_Sel, Bus2_Sel, MAR_Load} = {2'b00, 3'b001, 1'b1};
            end
            LOADSTORE2: begin
                {Bus2_Sel, PC_Inc} = {3'b010, 1'b1};
                if (DataOP && IR[7:4] == 4'hA) begin // Single-register operations
                    addr_sel = 1'b1;
                end
            end
            LOADSTORE3: begin
                if (IR == 8'h80) begin // LD immediate
                    {Bus1_Sel, Bus2_Sel, MAR_Load} = {2'b00, 3'b001, 1'b1};
                end else if (LoadStoreOP) begin // LD/ST direct
                    {Bus2_Sel, MAR_Load} = {3'b100, 1'b1};
                end
            end
            LOADSTORE4: begin
                if (IR == 8'h80) begin // LD immediate
                    {Bus2_Sel, PC_Inc} = {3'b010, 1'b1};
                end else if (DataOP && IR[7:4] == 4'h9) begin
                    PC_Inc = 1'b1;
                end
            end

            LOADSTORE5: begin
                if (IR == 8'h80) begin // LD immediate - FIXED
                    {reg_write_addr, reg_write_enable, Bus2_Sel} = 
                        {reg_operand_1[3:0], 1'b1, 3'b010};
                    if (debug_inner) $display("[FIXED] LD immediate: writing 0x%02h to reg %0d", from_memory, reg_operand_1[3:0]);
                    
                end else if (DataOP && IR[7:4] == 4'h9) begin // Two-register ALU
                    {CCR_Load, Bus1_Sel, Bus2_Sel} = {1'b1, 2'b01, 3'b000};
                    case (IR)
                        8'h90: begin // ADD
                            {reg_read_addr_A, reg_read_addr_B, reg_write_addr, reg_write_enable, ALU_Sel} = 
                                {reg_operand_1[3:0], reg_operand_2[3:0], reg_operand_1[3:0], 1'b1, 4'd0};
                            if (debug_inner) $display("[FIXED] ADD: reg%0d + reg%0d", reg_operand_1[3:0], reg_operand_2[3:0]);
                        end
                        8'h91: begin // SUB
                            {reg_read_addr_A, reg_read_addr_B, reg_write_addr, reg_write_enable, ALU_Sel} = 
                                {reg_operand_1[3:0], reg_operand_2[3:0], reg_operand_1[3:0], 1'b1, 4'd1};
                        end
                        8'h92: begin // AND
                            {reg_read_addr_A, reg_read_addr_B, reg_write_addr, reg_write_enable, ALU_Sel} = 
                                {reg_operand_1[3:0], reg_operand_2[3:0], reg_operand_1[3:0], 1'b1, 4'd4};
                        end
                        8'h93: begin // OR
                            {reg_read_addr_A, reg_read_addr_B, reg_write_addr, reg_write_enable, ALU_Sel} = 
                                {reg_operand_1[3:0], reg_operand_2[3:0], reg_operand_1[3:0], 1'b1, 4'd5};
                        end
                        8'h94: begin // XOR
                            {reg_read_addr_A, reg_read_addr_B, reg_write_addr, reg_write_enable, ALU_Sel} = 
                                {reg_operand_1[3:0], reg_operand_2[3:0], reg_operand_1[3:0], 1'b1, 4'd6};
                        end
                    endcase
                    
                end else if (DataOP && IR[7:4] == 4'hA) begin // Single-register ALU
                    {CCR_Load, Bus1_Sel, Bus2_Sel, addr_sel} = {1'b1, 2'b01, 3'b000, 1'b1};
                    case (IR)
                        8'hA0: begin // INC
                            {reg_read_addr_A, reg_write_addr, reg_write_enable, ALU_Sel} = 
                                {reg_operand_1[3:0], reg_operand_1[3:0], 1'b1, 4'd7};
                            if (debug_inner) $display("[FIXED] INC: reg%0d", reg_operand_1[3:0]);
                        end
                        8'hA1: begin // DEC
                            {reg_read_addr_A, reg_write_addr, reg_write_enable, ALU_Sel} = 
                                {reg_operand_1[3:0], reg_operand_1[3:0], 1'b1, 4'd8};
                            if (debug_inner) $display("[FIXED] DEC: reg%0d", reg_operand_1[3:0]);
                        end
                    endcase
                end
            end

            // Branch operations
            BRANCH0: begin
                {Bus1_Sel, Bus2_Sel, MAR_Load} = {2'b00, 3'b001, 1'b1};
            end
            BRANCH1: begin
                PC_Inc = 1'b1;
            end
            BRANCH2: begin
                {Bus1_Sel, Bus2_Sel, ALU_Sel, ALU_B_Sel} = {2'b00, 3'b010, 4'd0, 1'b1};
                case (IR)
                    8'h20: PC_Load = 1'b1; // BRA
                    8'h21: PC_Load = !CCR_Result[0]; // BCC
                    8'h22: PC_Load = CCR_Result[0];  // BCS
                    8'h23: PC_Load = !CCR_Result[2]; // BNE
                    8'h24: PC_Load = CCR_Result[2];  // BEQ
                    8'h25: PC_Load = !CCR_Result[3]; // BPL
                    8'h26: PC_Load = CCR_Result[3];  // BMI
                    8'h27: PC_Load = !CCR_Result[1]; // BVC
                    8'h28: PC_Load = CCR_Result[1];  // BVS
                    default: PC_Load = 1'b0;
                endcase
            end
        endcase
        
        if (debug_inner && state == FETCH0) 
            $display("[CTRL] Starting new instruction cycle");
    end

endmodule