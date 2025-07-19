module register_file(
    input clk,
    input reset,
    input [3:0] read_addr_A,
    input [3:0] read_addr_B,
    input [3:0] write_addr,
    input [7:0] write_data,
    input write_enable,
    output [7:0] read_data_A,
    output [7:0] read_data_B
);

    reg [7:0] registers [0:15];

    integer i;
    always @(posedge clk) begin
        if (!reset) begin
            for (i = 0; i < 16; i = i + 1) begin
                registers[i] <= 8'h00;
            end
        end else if (write_enable) begin
            registers[write_addr] <= write_data;
        end
    end

    assign read_data_A = registers[read_addr_A];
    assign read_data_B = registers[read_addr_B];   
endmodule