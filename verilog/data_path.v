module data_path(
    input clk,
    input reset,
    input IR_Load,
    output reg [7:0] IR,
    input MAR_Load,
    output reg [7:0] address,
    input PC_Load,
    input PC_Inc,
    input [3:0] ALU_Sel,
    output reg [3:0] CCR_Result,
    input CCR_Load,
    input [1:0] Bus2_Sel,
    input [1:0] Bus1_Sel,
    input [7:0] from_memory,
    output reg [7:0] to_memory,
    output reg [7:0] bus2_data,        // BUS2 data for register file writes
    input [7:0] alu_result,        // ALU result from CPU level
    input [7:0] reg_data_A,        // Register data for Bus1
    input [7:0] reg_data_B,        // Additional register data if needed
    input [3:0] NZVC               // CCR flags from ALU
);
    
    // Internal registers
    reg [7:0] BUS2, BUS1, IR_Reg, MAR, PC;
    reg [3:0] CCR;
    
    // Remove ALU - now handled at CPU level with register file
    
    // Register updates
    always @(posedge clk, negedge reset) begin
        if (!reset) begin
            IR_Reg <= 8'b0;
            MAR <= 8'b0;
            PC <= 8'b0;
            CCR <= 4'b0;
        end
        else begin
            if (IR_Load) IR_Reg <= BUS2;
            if (MAR_Load) begin
                MAR <= BUS2;
                // $display("[DEBUG] MAR_Load: MAR=%h, BUS2=%h at time %0t", MAR, BUS2, $time);
            end
            
            if (PC_Load) begin 
                if (Bus2_Sel == 2'b10)
                    PC <= PC + from_memory;
                else begin
                    PC <= BUS2;
                    // $display("[DEBUG] PC_Load: PC=%h, BUS2=%h, ALU_Result=%h, BUS1=%h, B_Reg=%h at time %0t", 
                    //          PC, BUS2, ALU_Result, BUS1, B_Reg, $time);
                end
            end
            else if (PC_Inc) PC <= PC + 1'b1;
            
            if (CCR_Load) begin
                CCR <= NZVC;  // Get CCR from ALU
                // $display("[DEBUG] Updating CCR to %b at time %0t", NZVC, $time);
            end
        end
    end
    
    always @* begin
        case(Bus1_Sel)
            2'b00: BUS1 = PC;
            2'b01: BUS1 = reg_data_A;    // Register data from register file
            2'b10: BUS1 = reg_data_B;    // Additional register data
            default: BUS1 = 8'b0;
        endcase
        
        case(Bus2_Sel)
            2'b00: BUS2 = alu_result;    // ALU result from CPU level
            2'b01: BUS2 = BUS1;
            2'b10: BUS2 = from_memory;
            default: BUS2 = 8'b0;
        endcase
        
        IR = IR_Reg;
        address = MAR;
        to_memory = BUS1;
        bus2_data = BUS2;    // Provide BUS2 data for register writes
        CCR_Result = CCR;
    end
	 
endmodule
