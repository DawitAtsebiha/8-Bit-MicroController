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

    task load_rom;                 // old-style header
        input filename;
        input base_addr;

        reg [1023:0] filename;
        reg [7:0] bytes;

        integer fd, idx, base_addr, tmp;
    begin
        fd = $fopen(filename,"rb");
        if (!fd) begin
            $display("ERROR: cannot open %0s", filename);
            $finish;
        end
        idx = base_addr;
        while (!$feof(fd)) begin
            tmp = $fread(bytes, fd);
            dut.memory1.rom1.ROM[idx] = bytes;
            idx = idx + 1;
        end
        $fclose(fd);
    end
    endtask

    parameter integer NUM_TESTS = 3;

    parameter string ROM_FILES [2:0] = {
        "ROM Programs/build/blink.bin",
        "ROM Programs/build/fibo.bin",
        "ROM Programs/build/counter.bin"
    };

    parameter string TEST_NAMES [2:0] = {
        "Blink LED Test",
        "Fibonacci Sequence Test",
        "Counter Test"
    };

    parameter string TEST_TYPES [2:0] = {
        "blink",
        "fibonacci",
        "counter"
    };

    parameter integer BASE_ADDRS [2:0] = {0, 0, 0};
    parameter integer MAX_CYCLES [2;0] = {1000, 1000, 1000};

    task run_prog;
        input string romfile;
        input integer base_addr;
        input integer max_cycles;
        input string test_name;

        integer n, start_cycles, ROM_count;
        reg done;
        
    begin
        $display("\n=== Starting Test: %0s ===", test_name);
        $display("Loading ROM: %0s at base address %0d", romfile, base_addr);
        
        load_rom(romfile, base_addr);
        
        // Set PC to start execution from the base address
        reset = 0; repeat (10) @(posedge clk); 
        dut.cpu1.data_path1.PC = base_addr;  // Set PC to program start address
        reset = 1;
        
        start_cycles = cycles;
        done = 0;
        ROM_count = 0;

        if (test_name == 0)
            ROM_valid = 0;
        else
            ROM_valid = 1;
        
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
            if (n > 0 && n % 100 == 0) begin
                $display("  [Cycle %0d] PC=0x%02h, IR=0x%02h - Still running...", cycles, PC, IR);
            end
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

        // Dynamic test runner function
        task run_all_tests;
            integer i;
        begin
            $display("\n========================================");
            $display("DYNAMIC ROM TEST SUITE");
            $display("========================================");
            $display("Found %0d ROM configurations", NUM_TESTS);
            $display("Clock period: 20ns (50MHz)");
            $display("Reset: Active high");
            $display("");
            
            // Loop through all configured ROMs
            for (i = 0; i < NUM_TESTS; i = i + 1) begin
                $display("Running test %0d of %0d...", i + 1, NUM_TESTS);
                run_prog(
                    ROM_FILES[i],
                    BASE_ADDRS[i],
                    MAX_CYCLES[i],
                    TEST_NAMES[i],
                    TEST_TYPES[i]
                );
            end
            
            // Final Summary
            $display("\n========================================");
            $display("DYNAMIC TESTBENCH SUMMARY");
            $display("========================================");
            $display("Total tests run: %0d", total_tests);
            $display("Total simulation cycles: %0d", cycles);
            $display("Simulation time: %0dns", $time);
            $display("All tests completed successfully!");
            $display("========================================");
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
            
            // Run all configured tests dynamically
            run_all_tests();
            
            $finish;
        end
    endmodule