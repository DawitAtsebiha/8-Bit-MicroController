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
    
    // Monitor for enhanced debugging
    always @(posedge clk) begin
        if (reset && debug_enable && cycles >= debug_start_cycle && 
           (debug_end_cycle == -1 || cycles <= debug_end_cycle)) begin
            
            // Build debug message
            $write("[Cycle %0d] ", cycles);
            
            if (debug_pc) $write("PC=0x%02h ", PC);
            if (debug_ir) $write("IR=0x%02h ", IR);
            if (debug_regs) $write("A=0x%02h B=0x%02h ", A_Reg, B_Reg);
            if (debug_state) $write("State=%0d ", dut.cpu1.control_unit1.state);
            
            // Always show if anything was printed
            if (debug_pc || debug_ir || debug_regs || debug_state) $write("\n");
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
    
    // Enhanced debugging parameters
    integer debug_cycles = 1000;           // Configurable cycle count
    reg     debug_enable = 0;              // Enable/disable debug output
    reg     debug_pc = 0;                  // Show Program Counter
    reg     debug_ir = 0;                  // Show Instruction Register
    reg     debug_regs = 0;                // Show A and B registers
    reg     debug_mem = 0;                 // Show memory accesses
    reg     debug_io = 1;                  // Show I/O operations (default on)
    reg     debug_state = 0;               // Show CPU state machine
    reg     debug_verbose = 0;             // Extra verbose debugging
    integer debug_start_cycle = 0;        // Start debugging from this cycle
    integer debug_end_cycle = -1;         // End debugging at this cycle (-1 = no limit)
    
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
        
        // Parse debug configuration parameters
        if ($value$plusargs("CYCLES=%d", debug_cycles)) begin
            $display("Debug cycles set to: %0d", debug_cycles);
        end
        
        if ($test$plusargs("DEBUG")) begin
            debug_enable = 1;
            $display("Debug mode enabled");
        end
        
        if ($test$plusargs("DEBUG_PC")) begin
            debug_pc = 1;
            $display("PC debugging enabled");
        end
        
        if ($test$plusargs("DEBUG_IR")) begin
            debug_ir = 1;
            $display("IR debugging enabled");
        end
        
        if ($test$plusargs("DEBUG_REGS")) begin
            debug_regs = 1;
            $display("Register debugging enabled");
        end
        
        if ($test$plusargs("DEBUG_MEM")) begin
            debug_mem = 1;
            $display("Memory debugging enabled");
        end
        
        if ($test$plusargs("DEBUG_STATE")) begin
            debug_state = 1;
            $display("State machine debugging enabled");
        end
        
        if ($test$plusargs("DEBUG_VERBOSE")) begin
            debug_verbose = 1;
            debug_enable = 1;
            debug_pc = 1;
            debug_ir = 1;
            debug_regs = 1;
            debug_mem = 1;
            debug_state = 1;
            $display("Verbose debugging enabled (all debug options on)");
        end
        
        if ($value$plusargs("DEBUG_START=%d", debug_start_cycle)) begin
            $display("Debug output starts at cycle: %0d", debug_start_cycle);
        end
        
        if ($value$plusargs("DEBUG_END=%d", debug_end_cycle)) begin
            $display("Debug output ends at cycle: %0d", debug_end_cycle);
        end
            dynamic_test_name = "Dynamic Test";
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
            
            // Enhanced I/O monitoring
            if (io_we) begin
                if (test_name == 0) 
                    $display("Catastrophic failure");
                else begin
                    if (debug_io || debug_verbose) begin
                        $display("  [Cycle %0d] I/O Write: F(%0d) = %0d (0x%02h) | PC=0x%02h", 
                                cycles, ROM_count, io_data, io_data, PC);
                    end else begin
                        $display("  [Cycle %0d] F(%0d) = %0d (0x%02h)", cycles, ROM_count, io_data, io_data);
                    end
                    ROM_output = io_data;  // Update GTKWave signal
                    ROM_sequence_count = ROM_count;  // Update sequence counter for GTKWave
                    ROM_count = ROM_count + 1;
                end
            end
            
            // Memory access debugging
            if (debug_mem && (dut.cpu1.memory1.we || dut.cpu1.memory1.oe)) begin
                if (dut.cpu1.memory1.we) begin
                    $display("  [Cycle %0d] MEM Write: Addr=0x%02h Data=0x%02h", 
                            cycles, dut.cpu1.memory1.addr, dut.cpu1.memory1.data_in);
                end else if (dut.cpu1.memory1.oe) begin
                    $display("  [Cycle %0d] MEM Read: Addr=0x%02h Data=0x%02h", 
                            cycles, dut.cpu1.memory1.addr, dut.cpu1.memory1.data_out);
                end
            end
            
            // Show progress every 100 cycles for long tests
            if (n > 0 && n % 100 == 0 && debug_verbose) begin
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
            $display("ENHANCED DYNAMIC ROM TEST");
            $display("========================================");
            $display("ROM file: %0s", dynamic_rom_file);
            $display("Test name: %0s", dynamic_test_name);
            $display("Max cycles: %0d", debug_cycles);
            $display("Clock period: 20ns (50MHz)");
            $display("Reset: Active high");
            
            // Display active debug options
            if (debug_enable || debug_verbose) begin
                $display("Debug options active:");
                if (debug_pc) $display("  - Program Counter (PC)");
                if (debug_ir) $display("  - Instruction Register (IR)");
                if (debug_regs) $display("  - A and B Registers");
                if (debug_mem) $display("  - Memory accesses");
                if (debug_io) $display("  - I/O operations");
                if (debug_state) $display("  - CPU state machine");
                if (debug_verbose) $display("  - Verbose mode");
                if (debug_start_cycle > 0) $display("  - Debug starts at cycle %0d", debug_start_cycle);
                if (debug_end_cycle != -1) $display("  - Debug ends at cycle %0d", debug_end_cycle);
            end
            $display("");
            
            run_prog(dynamic_rom_file, 0, debug_cycles, dynamic_test_name, "dynamic");
        end
    endtask
    endmodule