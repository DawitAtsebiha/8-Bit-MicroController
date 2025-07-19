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
    wire [3:0]  ALU_Sel;
    wire [3:0]  CCR_Result;
    wire        CCR_Load;
    wire [2:0]  Bus2_Sel;
    wire [1:0]  Bus1_Sel;
    wire [7:0]  immediate_value;
    wire [7:0]  address_value;
    wire        ALU_B_Sel;
    wire        addr_sel;       // Address selection: 0=PC, 1=MAR

    // Register file control signals  
    wire [3:0] reg_read_addr_A, reg_read_addr_B, reg_write_addr;
    wire [7:0] reg_read_data_A, reg_read_data_B, reg_write_data;
    wire reg_write_enable;

    // ALU signals
    wire [7:0] alu_result;
    wire [3:0] NZVC;

    // Instantiate Control Unit
    control_unit control_unit1 (
        .clk(clk),
        .reset(reset),
        .IR_Load(IR_Load),
        .IR(IR),
        .MAR_Load(MAR_Load),
        .PC_Load(PC_Load),
        .PC_Inc(PC_Inc),
        .reg_read_addr_A(reg_read_addr_A),
        .reg_read_addr_B(reg_read_addr_B),
        .reg_write_addr(reg_write_addr),
        .reg_write_enable(reg_write_enable),
        .ALU_Sel(ALU_Sel),
        .CCR_Result(CCR_Result),
        .CCR_Load(CCR_Load),
        .Bus2_Sel(Bus2_Sel),
        .Bus1_Sel(Bus1_Sel),
        .ALU_B_Sel(ALU_B_Sel),
        .write(write),
        .from_memory(from_memory),
        .immediate_out(immediate_value),
        .address_out(address_value),
        .addr_sel(addr_sel)
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
        .ALU_Sel(ALU_Sel),
        .CCR_Result(CCR_Result),
        .CCR_Load(CCR_Load),
        .Bus2_Sel(Bus2_Sel),
        .Bus1_Sel(Bus1_Sel),
        .from_memory(from_memory),
        .to_memory(to_memory),
        .bus2_data(reg_write_data),
        .alu_result(alu_result),
        .reg_data_A(reg_read_data_A),
        .reg_data_B(reg_read_data_B),
        .NZVC(NZVC),
        .immediate_value(immediate_value),
        .address_value(address_value),
        .addr_sel(addr_sel)
    );

    register_file reg_file (
        .clk(clk),
        .reset(reset),
        .read_addr_A(reg_read_addr_A),
        .read_addr_B(reg_read_addr_B),
        .write_addr(reg_write_addr),
        .write_data(reg_write_data),
        .write_enable(reg_write_enable),
        .read_data_A(reg_read_data_A),
        .read_data_B(reg_read_data_B)
    );

    ALU alu1 (
        .reg_data_A(reg_read_data_A),
        .reg_data_B(reg_read_data_B),
        .ALU_Sel(ALU_Sel),
        .NZVC(NZVC),
        .Result(alu_result)
    );

endmodule
