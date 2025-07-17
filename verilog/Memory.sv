module memory (
    input clk,
    input reset,
    input write,
    input [7:0] address,
    input [7:0] data_in,
    output reg [7:0] data_out,
    inout [7:0] io_data,   // Bidirectional I/O data
    output [3:0] io_addr,   // I/O port address
    output io_oe,           // Output enable
    output io_we            // Write enable
);
    // Internal signals
    wire [7:0] rom_out, ram_out;
    wire [6:0] rom_address = address[6:0];
    wire [6:0] ram_address = address - 8'h80;
    
    // Address range detection
    wire in_rom_range  = (address < 8'h80);
    wire in_ram_range  = (address >= 8'h80 && address < 8'hE0);
    wire in_port_range = (address >= 8'hF0);
    
    // I/O control signals
    assign io_addr = address[3:0];
    assign io_oe = in_port_range;       // Always enable during port access
    assign io_we = write && in_port_range; // Write enable for ports
    
    // Output port registers
    reg [7:0] output_ports [0:15];
    
    // Initialize output ports
    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1)
            output_ports[i] = 8'h00;
    end
    
    // Write to output ports
    always @(posedge clk, negedge reset) begin
		  integer i;
        if (!reset) begin
            for (i = 0; i < 16; i = i + 1)
                output_ports[i] <= 8'h00;
        end
        else if (write && in_port_range) begin
            output_ports[io_addr] <= data_in;
        end
    end
    
    // Drive I/O bus during writes
    assign io_data = (io_we) ? data_in : 8'bz;
    
    // ROM and RAM instances
    rom_128x8_sync rom1 (
        .address(rom_address),
        .clk(clk),
        .data_out(rom_out)
    );
    
    rw_96x8_sync ram1 (
        .address(ram_address[6:0]),
        .data_in(data_in),
        .write(write && in_ram_range),
        .clk(clk),
        .data_out(ram_out)
    );
    
    // Memory read multiplexer
    always @* begin
        case(1'b1)
            in_rom_range:  data_out = rom_out;
            in_ram_range:  data_out = ram_out;
            in_port_range: data_out = io_data; // Read from external bus
            default:       data_out = 8'h00;
        endcase
        
        // Debug output for critical addresses
        if (address == 8'h44 || address == 8'h45 || address == 8'h46) begin
            $display("[DEBUG] Memory access: address=%h, data_out=%h, rom_out=%h at time %0t", 
                    address, data_out, rom_out, $time);
        end
    end
endmodule