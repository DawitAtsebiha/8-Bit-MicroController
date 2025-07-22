module data_path (
    input  logic        clk,
    input  logic        reset,

    // control
    input  logic        IR_Load,
    input  logic        MAR_Load,
    input  logic        PC_Load,
    input  logic        PC_Inc,
    input  logic        CCR_Load,
    input  logic [1:0]  Bus1_Sel,
    input  logic [2:0]  Bus2_Sel,
    input  logic        addr_sel,        // 0=PC  1=MAR

	 input  logic [3:0]  ALU_Sel,
    input  logic [7:0]  from_memory,
    input  logic [7:0]  alu_result,
    input  logic [7:0]  reg_data_A,
    input  logic [7:0]  reg_data_B,
    input  logic [3:0]  NZVC,
    input  logic [7:0]  immediate_value, 
    input  logic [7:0]  address_value, 

    output logic [7:0]  address,
    output logic [7:0]  to_memory,
    output logic [7:0]  bus2_data,       // -> RF write_data
    output logic [3:0]  CCR_Result,
    output logic [7:0]  IR               // instruction register
);

    logic [7:0] PC, MAR, IR_reg;
    logic [3:0] CCR;
	 
	 logic [7:0] BUS1;
	 logic [7:0] BUS2;

    // Bus 1 Mux (combinational)
    // Selects data for PC, MAR, or register file read
    assign BUS1 = (Bus1_Sel == 2'd0) ? PC         :
                       (Bus1_Sel == 2'd1) ? reg_data_A :
                                           reg_data_B;

    // Bus 2 Mux (combinational)
    // Selects data for MAR, IR, or ALU input
    assign BUS2 = (Bus2_Sel == 3'd0) ? alu_result     :
                       (Bus2_Sel == 3'd1) ? BUS1           :
                       (Bus2_Sel == 3'd2) ? from_memory    :
                       (Bus2_Sel == 3'd3) ? immediate_value: // ← LD imm
                       (Bus2_Sel == 3'd4) ? address_value  : 8'h00;

    assign bus2_data = BUS2; // For register file writes

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            PC      <= 8'h00;
            MAR     <= 8'h00;
            IR_reg  <= 8'h00;
            CCR     <= 4'h0;
        end
        else begin
            if (IR_Load) IR_reg <= BUS2;
            if (MAR_Load) MAR   <= BUS2;

            if (PC_Load)        PC <= BUS2;
            else if (PC_Inc)    PC <= PC + 1;

            if (CCR_Load)       CCR <= NZVC;
        end
    end

    assign IR       = IR_reg;
    assign address  = (addr_sel) ? MAR : PC;  // fetch vs. data cycle
    assign to_memory= BUS1;
    assign CCR_Result = CCR;

endmodule
