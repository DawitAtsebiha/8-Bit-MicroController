`timescale 1ns/1ps

module computer_TB;

    tri  [7:0] io_data;
    wire [3:0] io_addr;
    wire       io_oe, io_we;

    reg clk = 0;  always #10 clk = ~clk;
    reg reset = 0;

    computer dut (
        .clk     (clk),
        .reset   (reset),
        .io_data (io_data),
        .io_addr (io_addr),
        .io_oe   (io_oe),
        .io_we   (io_we)
    );

    wire [7:0] PC = dut.cpu1.data_path1.PC;
    wire [7:0] IR = dut.cpu1.data_path1.IR_Reg;
    wire [7:0] A_Reg = dut.cpu1.data_path1.A_Reg;
    wire [7:0] B_Reg = dut.cpu1.data_path1.B_Reg;

    // Output monitoring signals for GTKWave
    reg [7:0] ROM_output;
    reg ROM_valid;
    integer ROM_sequence_count;
    
    initial begin
        ROM_output = 0;
        ROM_valid = 0;
        ROM_sequence_count = 0;
    end
    
    integer cycles = 0;
    
    // Monitor for debugging
    always @(posedge clk) begin
        if (reset) begin
            // Optional: uncomment for detailed instruction tracing
            // $display("[Cycle %0d] PC=0x%02h IR=0x%02h A=0x%02h B=0x%02h", 
            //          cycles, PC, IR, A_Reg, B_Reg);
        end
    end

        task load_rom;
            input [8*64-1:0] filename;
            reg   [7:0]      data_byte;
            integer          fd, idx, bytes_read;
        begin
            fd = $fopen(filename, "rb");
            if (fd == 0) begin
                $display("ERROR: could not open ROM file %0s", filename);
                $finish;
            end
            idx = 0;
            while (!$feof(fd)) begin
                bytes_read = $fread(data_byte, fd);
                if (bytes_read > 0) begin
                    dut.memory1.rom1.ROM[idx] = data_byte;
                    idx = idx + 1;
                end
            end
            $fclose(fd);
        end
        endtask

    // Dynamic ROM file loading
    reg [8*128-1:0] dynamic_rom_file;
    reg [8*64-1:0] dynamic_test_name;
    
    // Default to a simple test if no file specified
    initial begin
        if ($value$plusargs("ROMFILE=%s", dynamic_rom_file)) begin
            $display("Loading dynamic ROM file: %0s", dynamic_rom_file);
        end else begin
            dynamic_rom_file = "ROM Programs/build/counter.bin";
            $display("No ROM file specified, using default: %0s", dynamic_rom_file);
        end
        
        if ($value$plusargs("TESTNAME=%s", dynamic_test_name)) begin
            $display("Test name: %0s", dynamic_test_name);
        end else begin
            dynamic_test_name = "Dynamic Test";
        end
    end

    task run_prog;
        input [8*64-1:0] romfile;
        input integer    base_addr;
        input integer    max_cycles;
        input [8*32-1:0] test_name;
        input [8*16-1:0] test_type;
        integer          n, start_cycles, ROM_count;
        reg              done;
    begin
        $display("\n=== Starting Test: %0s ===", test_name);
        $display("Loading ROM: %0s", romfile);

        load_rom(romfile);

        reset = 0; repeat (10) @(posedge clk);
        dut.cpu1.data_path1.PC = base_addr;
        reset = 1;

        start_cycles = cycles;
        done = 0;
        ROM_count = 0;
        ROM_valid = (test_name != {8*32{1'b0}});
        
        $display("Program execution started at cycle %0d, PC set to 0x%02h", cycles, base_addr);
        
        for (n = 0; n < max_cycles && !done; n = n + 1) begin
            @(posedge clk); cycles = cycles + 1;
            
            // Monitor I/O activity
            if (io_we) begin
                if (test_name == 0) 
                    $display("Catastrophic failure");
                else begin
                    $display("  [Cycle %0d] F(%0d) = %0d (0x%02h)", cycles, ROM_count, io_data, io_data);
                    ROM_output = io_data;  // Update GTKWave signal
                    ROM_sequence_count = ROM_count;  // Update sequence counter for GTKWave
                    ROM_count = ROM_count + 1;
                end
            end
            
            // Show progress every 100 cycles for long tests
           // if (n > 0 && n % 100 == 0) begin
           //     $display("  [Cycle %0d] PC=0x%02h, IR=0x%02h - Still running...", cycles, PC, IR);
           // end
        end
        
        if (done) begin
                $display("=== Test '%0s' COMPLETED successfully ===", test_name);
                $display("Execution time: %0d cycles", cycles - start_cycles);
            end else begin
                $display("=== Test '%0s' TIMEOUT after %0d cycles ===", test_name, max_cycles);
                $display("Final state: PC=0x%02h, IR=0x%02h", PC, IR);
            end
            $display("Total cycles so far: %0d\n", cycles);
    end
    endtask

        // Simplified initial block
        initial begin
            $dumpfile("waves.vcd");
            $dumpvars(clk, reset, cycles);
            $dumpvars(PC, IR, A_Reg, B_Reg, ROM_output);
            $dumpvars(io_addr, io_data, io_we);
            $dumpvars(ROM_valid, ROM_sequence_count);
            
            $display("VCD Dump Info - Limited signal set:");
            $display("- Clock and reset signals");
            $display("- CPU state: PC, IR, A and B Registers");
            $display("- I/O signals: io_addr, io_data, io_we");
            $display("- Program monitoring signals");
            
            // Run the dynamic test
            run_dynamic_test();
            
            $finish;
        end
        
    // Dynamic test runner
    task run_dynamic_test;
        begin
            $display("\n========================================");
            $display("DYNAMIC ROM TEST");
            $display("========================================");
            $display("ROM file: %0s", dynamic_rom_file);
            $display("Test name: %0s", dynamic_test_name);
            $display("Clock period: 20ns (50MHz)");
            $display("Reset: Active high");
            $display("");
            
            run_prog(dynamic_rom_file, 0, 1000, dynamic_test_name, "dynamic");
        end
    endtask
    endmodule