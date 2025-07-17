module computer(
    input clk,
    input reset,
    inout [7:0] io_data,   // 8-bit bidirectional data bus
    output [3:0] io_addr,   // 4-bit I/O port address
    output io_oe,           // Output enable (1 = computer driving bus)
    output io_we            // Write enable (1 = write operation)
);
    wire [7:0] address;
    wire [7:0] data_in;
    wire [7:0] data_out;
    wire write;
    
    cpu cpu1 (
        .clk(clk),
        .reset(reset),
        .address(address),
        .write(write),
        .to_memory(data_in),
        .from_memory(data_out)
    );
    
    memory memory1 (
        .clk(clk),
        .reset(reset),
        .write(write),
        .address(address),
        .data_in(data_in),
        .data_out(data_out),
        .io_data(io_data),
        .io_addr(io_addr),
        .io_oe(io_oe),
        .io_we(io_we)
    );
endmodule