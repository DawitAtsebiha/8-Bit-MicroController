module rw_96x8_sync (
    input clk,
    input write,
    input [6:0] address,
    input [7:0] data_in,
    output [7:0] data_out
);

    // RAM declaration
    reg [7:0] RAM [0:95];
    
    // Initialize RAM
    initial begin
        RAM[0] = 8'h33;
        RAM[1] = 8'h22;
        for (int i = 2; i < 96; i++) begin
            RAM[i] = 8'h00;
        end
    end

    // Combinational read
    assign data_out = RAM[address];
    
    // Synchronous write
    always @(posedge clk) begin
        if (write) begin
            RAM[address] <= data_in;
        end
    end
endmodule