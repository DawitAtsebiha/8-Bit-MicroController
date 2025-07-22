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

    typedef enum logic [2:0] {
        FETCH, DECODE, EXECUTE, LOADSTORE, DATA, BRANCH
    } state_t;

    state_t state, next;
    logic [7:0] reg_operand_1, reg_operand_2;
    logic LoadStoreOP, DataOP, BranchOP;
    logic [3:0] cycle_count;

    localparam int FETCH_CYCLES      = 6;  // 3 bytes × 2 bus cycles/byte
    localparam int LDIMM_CYCLES      = 6;  // LD  rX,#imm   (same as today)
    localparam int SINGLE_ALU_CYCLES = 3;  // INC/DEC
    localparam int TWO_REG_CYCLES    = 1;  // ADD/SUB/AND/OR/XOR (now just 1 cycle)
    localparam int BRANCH_CYCLES     = 2;  // BRA, BNE, BEQ need 2 cycles for calculation

    // Instruction decode
    always_comb begin
        LoadStoreOP = (IR[7:4] == 4'h8);
        DataOP = (IR[7:4] == 4'h9) || (IR[7:4] == 4'hA);
        BranchOP = (IR[7:4] == 4'h2);
    end

    // State register with cycle counter
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            state <= FETCH;
            cycle_count <= 4'd0;
        end else if (state != next) begin
				 state <= next;
				 cycle_count <= 4'd0;
			end else
				 cycle_count <= cycle_count + 4'd1;
	 end

    // Capture operands at the right time
    always_ff @(posedge clk) begin            
        case (state)
            FETCH: begin
                if (cycle_count == 3) reg_operand_1 <= from_memory; // byte‑1 (register or first operand)
                if (cycle_count == 5) reg_operand_2 <= from_memory; // byte‑2 (immediate or second operand)
            end
            // Branch instructions use reg_operand_1 (byte 1) as the offset
            // No need to re-read during BRANCH state
        endcase
    end

    // Next state logic
    always_comb begin
        next = state;

        unique case (state)
            FETCH: if (cycle_count >= FETCH_CYCLES-1)  next = DECODE;

            DECODE: next = EXECUTE;
            
            EXECUTE: begin
                if (LoadStoreOP)                  next = LOADSTORE;
                else if (DataOP && IR[7:4]==4'h9) next = DATA;
                else if (DataOP && IR[7:4]==4'hA) next = LOADSTORE; // single‑reg ALU re‑uses LS stage
                else if (BranchOP)                next = BRANCH;
                else                              next = FETCH;
            end
            
            LOADSTORE: begin
					if (IR == 8'h80) begin
						if (cycle_count >= 4'd0)         
							next = FETCH;
					end 
					else if (cycle_count >= SINGLE_ALU_CYCLES-1)
						next = FETCH;
			   end

            DATA:      if (cycle_count >= TWO_REG_CYCLES-1)    next = FETCH;
            BRANCH:    if (cycle_count >= BRANCH_CYCLES-1)     next = FETCH;
            default:   next = FETCH;
        endcase
    end

	always_comb begin
		 {IR_Load, MAR_Load, PC_Load, PC_Inc,
		  reg_write_enable, CCR_Load, write,
		  ALU_B_Sel, addr_sel}                   = 9'b0;

		 {reg_read_addr_A, reg_read_addr_B,
		  reg_write_addr,  ALU_Sel}              = 16'b0;

		 {Bus2_Sel,  Bus1_Sel}                   = 5'b0;

		 // Branch instructions use reg_operand_1 as offset, others use reg_operand_2
		 immediate_out = BranchOP ? reg_operand_1 : reg_operand_2;
		 address_out   = reg_operand_2;

		 unique case (state)
            FETCH: begin
                case (cycle_count)
                    4'd0: {Bus1_Sel, Bus2_Sel, MAR_Load}         = {2'b00, 3'b001, 1'b1};
                    4'd1: {Bus2_Sel, IR_Load,  PC_Inc}           = {3'b010, 1'b1,  1'b1};
                    4'd2: {Bus1_Sel, Bus2_Sel, MAR_Load}         = {2'b00, 3'b001, 1'b1};
                    4'd3: {Bus2_Sel,            PC_Inc}          = {3'b010,          1'b1};
                    4'd4: {Bus1_Sel, Bus2_Sel, MAR_Load}         = {2'b00, 3'b001, 1'b1};
                    4'd5: {Bus2_Sel,            PC_Inc}          = {3'b010,          1'b1};
                endcase
            end

            LOADSTORE: begin
                // --- LD rX,#imm (IR == 0x80) ---
                if (IR == 8'h80) begin
                        if (cycle_count == 4'd0) begin
                            Bus2_Sel         = 3'b011;              // immediate already latched
                            reg_write_addr   = reg_operand_1[3:0];
                            reg_write_enable = 1'b1;
                        end
                end
                // --- INC / DEC (single‑register ALU) ---
                else if (DataOP && IR[7:4] == 4'hA) begin
                        if (cycle_count == 4'd0)
                            {Bus1_Sel, Bus2_Sel, MAR_Load} = {2'b00, 3'b001, 1'b1};
                        if (cycle_count == 4'd2) begin
                            CCR_Load = 1'b1;
                            Bus1_Sel = 2'b01;   // reg data → ALU A
                            addr_sel = 1'b1;
                            case (IR)
                                8'hA0: begin // INC
                                        {reg_read_addr_A, reg_write_addr,
                                        reg_write_enable, ALU_Sel}
                                            = {reg_operand_1[3:0], reg_operand_1[3:0],
                                                1'b1,              4'd7};
                                end
                                8'hA1: begin // DEC
                                        {reg_read_addr_A, reg_write_addr,
                                        reg_write_enable, ALU_Sel}
                                            = {reg_operand_1[3:0], reg_operand_1[3:0],
                                                1'b1,              4'd8};
                                end
                            endcase
                        end
                end
            end

            DATA: begin
                if (cycle_count == 4'd0) begin
                        {CCR_Load, Bus1_Sel, Bus2_Sel} = {1'b1, 2'b01, 3'b000};
                        unique case (IR)
                            8'h90: begin // ADD
                                {reg_read_addr_A, reg_read_addr_B,
                                    reg_write_addr,   reg_write_enable, ALU_Sel}
                                        = {reg_operand_1[3:0], reg_operand_2[3:0],
                                            reg_operand_1[3:0], 1'b1,           4'd0};
                            end
                            8'h91: begin // SUB
                                {reg_read_addr_A, reg_read_addr_B,
                                    reg_write_addr,   reg_write_enable, ALU_Sel}
                                        = {reg_operand_1[3:0], reg_operand_2[3:0],
                                            reg_operand_1[3:0], 1'b1,           4'd1};
                            end
                            8'h92: begin // AND
                                {reg_read_addr_A, reg_read_addr_B,
                                    reg_write_addr,   reg_write_enable, ALU_Sel}
                                        = {reg_operand_1[3:0], reg_operand_2[3:0],
                                            reg_operand_1[3:0], 1'b1,           4'd4};
                            end
                            8'h93: begin // OR
                                {reg_read_addr_A, reg_read_addr_B,
                                    reg_write_addr,   reg_write_enable, ALU_Sel}
                                        = {reg_operand_1[3:0], reg_operand_2[3:0],
                                            reg_operand_1[3:0], 1'b1,           4'd5};
                            end
                            8'h94: begin // XOR
                                {reg_read_addr_A, reg_read_addr_B,
                                    reg_write_addr,   reg_write_enable, ALU_Sel}
                                        = {reg_operand_1[3:0], reg_operand_2[3:0],
                                            reg_operand_1[3:0], 1'b1,           4'd6};
                            end
                            default: ;
                        endcase
                end
            end

            BRANCH: begin
                if (cycle_count == 4'd0) begin
                        // Set up ALU to calculate PC + branch offset  
                        {Bus1_Sel, ALU_Sel, ALU_B_Sel} = {2'b00, 4'd0, 1'b1};
                end
                if (cycle_count == 4'd1) begin
                        // Load ALU result (PC + offset) into PC if branch condition is met
                        Bus2_Sel = 3'b000;  // ALU result to BUS2
                        case (IR)
                            8'h20: PC_Load = 1'b1;                 // BRA           TO-DO: BNE and BEQ both work fine, however when BRA
                            8'h23: PC_Load = !CCR_Result[2];       // BNE                  is used it keeps iterating over the ENTIRE program, 
                            8'h24: PC_Load =  CCR_Result[2];       // BEQ                  so making the operations pointless as it putting in the original values.
                            default: ;
                        endcase
                end
            end

            default: ;
        endcase
    end
endmodule
