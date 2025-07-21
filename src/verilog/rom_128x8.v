module rom_128x8_sync (
    input clk,
    input [6:0] address,
    output reg [7:0] data_out
);

    // ROM declaration with complete initialization
    reg [7:0] ROM [0:127];
    
    integer i;
    initial begin
        // Initialize all locations to 0
        for (i = 0; i < 128; i = i + 1) begin
            ROM[i] = 8'h00;
        end
        
        // Load ROM from file if it exists
        if ($test$plusargs("ROMFILE")) begin
            // File will be loaded by testbench
        end else begin
            // Default program
            ROM[0] = 8'h86; ROM[1] = 8'hAA;
            ROM[2] = 8'h96; ROM[3] = 8'hF0;
            ROM[4] = 8'h20; ROM[5] = 8'hFE;
        end
    end

    always @* begin
        data_out = ROM[address];
    end
    
    // Task to load ROM from file (called by testbench)
    task load_rom_file;
        input [200*8:1] filename;
        begin
            $readmemh(filename, ROM);
            $display("ROM loaded from file: %0s", filename);
        end
    endtask
endmodule