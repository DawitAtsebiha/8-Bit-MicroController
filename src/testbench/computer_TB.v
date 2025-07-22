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
        .debug_inner (debug_inner),
        .io_data (io_data),
        .io_addr (io_addr),
        .io_oe   (io_oe),
        .io_we   (io_we)
    );

    wire [7:0] PC = dut.cpu1.data_path1.PC;
    wire [7:0] IR = dut.cpu1.data_path1.IR_reg;
    
    // Access register file contents (A=register 0, B=register 1, etc.)
    wire [7:0] Reg_A = dut.cpu1.reg_file.registers[0];  // Register A
    wire [7:0] Reg_B = dut.cpu1.reg_file.registers[1];  // Register B
    wire [7:0] Reg_C = dut.cpu1.reg_file.registers[2];  // Register C
    wire [7:0] Reg_D = dut.cpu1.reg_file.registers[3];  // Register D

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
    
    // Function to convert state number to state name
    function [8*12-1:0] state_name;
        input [5:0] state_val;
        begin
            case(state_val)
                0:  state_name = "Fetch";
                1: state_name = "Decode";
                2: state_name = "Execute";
                3: state_name = "LoadStore";
                4: state_name = "Data";
                5: state_name = "Branch";
                default: state_name = "UNKNOWN";
            endcase
        end
    endfunction

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
                //  $display("Loading ROM[%0d] = 0x%02h", idx, data_byte);  Shows loading progress of bytes into ROM
                    dut.memory1.rom1.ROM[idx] = data_byte;
                    idx = idx + 1;
                end
            end
            $fclose(fd);
        //  $display("ROM loading complete, loaded %0d bytes", idx);
        end
        endtask

    // Dynamic ROM file loading
    reg [8*128-1:0] dynamic_rom_file;
    reg [8*64-1:0] dynamic_test_name;
    reg integer debug_cycles = 1000;      // Default to 1000 cycles if not specified
    
    // Enhanced debugging parameters
    reg     debug_enable = 0;              // Enable/disable debug output (disabled by default - GUI controls this)
    reg     debug_pc = 0;                  // Show Program Counter
    reg     debug_ir = 0;                  // Show Instruction Register
    reg     debug_regs = 0;                // Show A and B registers
    reg     debug_mem = 0;                 // Show memory accesses (disabled by default)
    reg     debug_io = 1;                  // Show I/O operations (always on for program output)
    reg     debug_state = 0;               // Show CPU state machine
    reg     debug_inner = 0;               // Show inner workings (register writes, detailed state info)
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
        end else begin
            $display("Using default cycles: %0d", debug_cycles);
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
            debug_mem = 1;  // Force enable memory debugging
        end
        
        if ($test$plusargs("DEBUG_IO")) begin
            debug_io = 1;
            $display("I/O debugging enabled");
        end
        
        if ($test$plusargs("DEBUG_INNER")) begin
            debug_inner = 1;
            $display("Inner workings debugging enabled");
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
            debug_inner = 1;
            debug_state = 1;
            $display("Verbose debugging enabled (all debug options on)");
        end
        
        if ($value$plusargs("DEBUG_START=%d", debug_start_cycle)) begin
            $display("Debug output starts at cycle: %0d", debug_start_cycle);
        end
        
        if ($value$plusargs("DEBUG_END=%d", debug_end_cycle)) begin
            $display("Debug output ends at cycle: %0d", debug_end_cycle);
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
            
            // Monitor register changes - show values when registers are written (only if inner workings enabled)
            if (dut.cpu1.reg_write_enable && debug_enable && debug_inner) begin
                $display("  [Cycle %0d] REG_WRITE: R%0d = 0x%02h", 
                         cycles, dut.cpu1.reg_write_addr, dut.cpu1.reg_write_data);
                $display("                Current register values: A=0x%02h B=0x%02h C=0x%02h D=0x%02h", 
                         Reg_A, Reg_B, Reg_C, Reg_D);
            end
            
            // Debug monitoring for PC, IR, Registers, State
            if (debug_enable && cycles >= debug_start_cycle && 
               (debug_end_cycle == -1 || cycles <= debug_end_cycle)) begin
                
                if (debug_pc || debug_ir || debug_regs || debug_state) begin
                    if (debug_inner) begin
                        // Show detailed register display with cycle info (inner workings)
                        $write("  [Cycle %0d] ", cycles);
                        if (debug_pc) $write("PC=0x%02h ", PC);
                        if (debug_ir) $write("IR=0x%02h ", IR);
                        if (debug_state) $write("State=%s ", state_name(dut.cpu1.control_unit1.state));
                        $write("\n");
                        dut.cpu1.reg_file.debug_print_registers();
                    end else begin
                        // Show compact display without detailed registers
                        $write("  [Cycle %0d] ", cycles);
                        if (debug_pc) $write("PC=0x%02h ", PC);
                        if (debug_ir) $write("IR=0x%02h ", IR);
                        if (debug_state) $write("State=%s ", state_name(dut.cpu1.control_unit1.state));
                        $write("\n");
                    end
                end
            end
            
            // Enhanced I/O monitoring
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
            
            // Memory access debugging
            if (debug_mem && dut.memory1.write) begin
                $display("  [Cycle %0d] MEM Write: Addr=0x%02h Data=0x%02h", 
                        cycles, dut.memory1.address, dut.memory1.data_in);
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
                $display("Full register file contents:");
                dut.cpu1.reg_file.debug_print_registers();
            end
            $display("Total cycles so far: %0d\n", cycles);
    end
    endtask

        // Simplified initial block
        initial begin
            $dumpfile("waves.vcd");
            $dumpvars(clk, reset, cycles);
            $dumpvars(PC, IR, Reg_A, Reg_B, ROM_output);
            $dumpvars(io_addr, io_data, io_we);
            $dumpvars(ROM_valid, ROM_sequence_count);

            
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
                if (debug_inner) $display("  - Inner workings (detailed CPU operations)");
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