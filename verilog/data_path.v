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
    input [3:0] ALU_Sel,
    output reg [3:0] CCR_Result,
    input CCR_Load,
    input [1:0] Bus2_Sel,
    input [1:0] Bus1_Sel,
    input ALU_B_Sel,  // 0 = B_Reg, 1 = BUS2
    input [7:0] from_memory,
    output reg [7:0] to_memory
);
    
    // Internal registers
    reg [7:0] BUS2, BUS1, IR_Reg, MAR, PC, A_Reg, B_Reg;
    reg [3:0] CCR;
    wire [7:0] ALU_Result;
    wire [3:0] CCR_in;
    wire [7:0] ALU_B_Input;  // Multiplexed ALU B input
    
    // ALU B input selection
    assign ALU_B_Input = ALU_B_Sel ? BUS2 : B_Reg;
    
    // ALU instantiation
    ALU alu1 (
        .A(BUS1),
        .B(ALU_B_Input),
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
            
            if (A_Load) A_Reg <= BUS2;
            if (B_Load) begin
                B_Reg <= BUS2;
                // $display("[DEBUG] B_Load: B_Reg=%h, BUS2=%h, from_memory=%h at time %0t", 
                //          B_Reg, BUS2, from_memory, $time);
            end
            if (CCR_Load) begin
                CCR <= CCR_in;
                // $display("[DEBUG] Updating CCR to %b at time %0t", CCR_in, $time);
            end
        end
    end
    
    always @* begin
        case(Bus1_Sel)
            2'b00: BUS1 = PC;
            2'b01: BUS1 = A_Reg;
            2'b10: BUS1 = B_Reg;
            default: BUS1 = 8'b0;
        endcase
        
        case(Bus2_Sel)
            2'b00: BUS2 = ALU_Result;
            2'b01: BUS2 = BUS1;
            2'b10: BUS2 = from_memory;
            default: BUS2 = 8'b0;
        endcase
        
        IR = IR_Reg;
        address = MAR;
        to_memory = BUS1;
        CCR_Result = CCR;
    end
	 
endmodule
