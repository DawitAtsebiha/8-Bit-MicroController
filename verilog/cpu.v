module cpu(
    input clk,
    input reset,
    output [7:0] address,
    input [7:0] from_memory,
    output write,
    output [7:0] to_memory
);

    // Internal control signals
    wire        IR_Load;
    wire [7:0]  IR;
    wire        MAR_Load;
    wire        PC_Load;
    wire        PC_Inc;
    wire        A_Load;
    wire        B_Load;
    wire [3:0]  ALU_Sel;
    wire [3:0]  CCR_Result;
    wire        CCR_Load;
    wire [1:0]  Bus2_Sel;
    wire [1:0]  Bus1_Sel;
    wire        ALU_B_Sel;

    // Instantiate Control Unit
    control_unit control_unit1 (
        .clk(clk),
        .reset(reset),
        .IR_Load(IR_Load),
        .IR(IR),
        .MAR_Load(MAR_Load),
        .PC_Load(PC_Load),
        .PC_Inc(PC_Inc),
        .A_Load(A_Load),
        .B_Load(B_Load),
        .ALU_Sel(ALU_Sel),
        .CCR_Result(CCR_Result),
        .CCR_Load(CCR_Load),
        .Bus2_Sel(Bus2_Sel),
        .Bus1_Sel(Bus1_Sel),
        .ALU_B_Sel(ALU_B_Sel),
        .write(write)
    );

    // Instantiate Data Path
    data_path data_path1 (
        .clk(clk),
        .reset(reset),
        .IR_Load(IR_Load),
        .IR(IR),
        .MAR_Load(MAR_Load),
        .address(address),
        .PC_Load(PC_Load),
        .PC_Inc(PC_Inc),
        .A_Load(A_Load),
        .B_Load(B_Load),
        .ALU_Sel(ALU_Sel),
        .CCR_Result(CCR_Result),
        .CCR_Load(CCR_Load),
        .Bus2_Sel(Bus2_Sel),
        .Bus1_Sel(Bus1_Sel),
        .ALU_B_Sel(ALU_B_Sel),
        .from_memory(from_memory),
        .to_memory(to_memory)
    );

endmodule
