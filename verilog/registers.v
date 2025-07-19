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
            $display("[REG_FILE] Writing 0x%02h to register %0d at time %0t", write_data, write_addr, $time);
            registers[write_addr] <= write_data;
        end
    end

    assign read_data_A = registers[read_addr_A];
    assign read_data_B = registers[read_addr_B];   

    task debug_print_registers;
        begin
            $display("Registers: A=%02h B=%02h C=%02h D=%02h E=%02h F=%02h G=%02h H=%02h",
                     registers[0], registers[1], registers[2], registers[3],
                     registers[4], registers[5], registers[6], registers[7]);
            $display("           I=%02h J=%02h K=%02h L=%02h M=%02h N=%02h O=%02h P=%02h",
                     registers[8], registers[9], registers[10], registers[11],
                     registers[12], registers[13], registers[14], registers[15]);
        end
    endtask
endmodule