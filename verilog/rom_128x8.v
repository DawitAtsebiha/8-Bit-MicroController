module rom_128x8_sync (
    input clk,
    input [6:0] address,
    output reg [7:0] data_out
);

    // ROM declaration with complete initialization
    reg [7:0] ROM [0:127];
    
    integer i;
    initial begin
        ROM[0] = 8'h86; ROM[1] = 8'hAA;
        ROM[2] = 8'h96; ROM[3] = 8'hF0;
        ROM[4] = 8'h20; ROM[5] = 8'hFE;
        
        // Initialize remaining locations
        for (i = 6; i < 128; i = i + 1) begin
            ROM[i] = 8'h00;
        end
    end

    always @* begin
        data_out = ROM[address];
    end
endmodule