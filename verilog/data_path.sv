module data_path(
    input clk,
    input reset,
    input IR_Load,
    output reg [7:0] IR,
    input MAR_Load,
    output reg [7:0] address,
    input PC_Load,
    input PC_Inc,
    input A_Load,
    input B_Load,
    input [2:0] ALU_Sel,
    output reg [3:0] CCR_Result,
    input CCR_Load,
    input [1:0] Bus2_Sel,
    input [1:0] Bus1_Sel,
    input [7:0] from_memory,
    output reg [7:0] to_memory
);
    
    // Internal registers
    reg [7:0] BUS2, BUS1, IR_Reg, MAR, PC, A_Reg, B_Reg;
    reg [3:0] CCR;
    wire [7:0] ALU_Result;
    wire [3:0] CCR_in;
    
    // ALU instantiation
    ALU alu1 (
        .A(BUS1),
        .B(B_Reg),
        .ALU_Sel(ALU_Sel),
        .NZVC(CCR_in),
        .Result(ALU_Result)
    );
    
    // Register updates
    always @(posedge clk, negedge reset) begin
        if (!reset) begin
            IR_Reg <= 8'b0;
            MAR <= 8'b0;
            PC <= 8'b0;
            A_Reg <= 8'b0;
            B_Reg <= 8'b0;
            CCR <= 4'b0;
        end
        else begin
            if (IR_Load) IR_Reg <= BUS2;
            if (MAR_Load) MAR <= BUS2;
            
            if (PC_Load) PC <= BUS2;
            else if (PC_Inc) PC <= PC + 1'b1;
            
            if (A_Load) A_Reg <= BUS2;
            if (B_Load) B_Reg <= BUS2;
            if (CCR_Load) CCR <= CCR_in;
        end
    end
    
    // Bus assignments (combinational)
    always @* begin
        // Bus1 selection FIRST to prevent warning
        case(Bus1_Sel)
            2'b00: BUS1 = PC;
            2'b01: BUS1 = A_Reg;
            2'b10: BUS1 = B_Reg;
            default: BUS1 = 8'b0;
        endcase
        
        // Bus2 selection
        case(Bus2_Sel)
            2'b00: BUS2 = ALU_Result;
            2'b01: BUS2 = BUS1;
            2'b10: BUS2 = from_memory;
            default: BUS2 = 8'b0;
        endcase
        
        // Output assignments
        IR = IR_Reg;
        address = MAR;
        to_memory = BUS1;
        CCR_Result = CCR;
    end
	 
endmodule
