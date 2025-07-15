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
            integer          fd, idx;
        begin
            fd = $fopen(filename, "rb");
            if (fd == 0) begin
                $display("ERROR: could not open ROM file %0s", filename);
                $finish;
            end
            idx = 0;
            while (!$feof(fd)) begin
                $fread(data_byte, fd);
                dut.memory1.rom1.ROM[idx] = data_byte;
                idx = idx + 1;
            end
            $fclose(fd);
        end
        endtask

    parameter integer NUM_TESTS = 3;

    parameter [8*64-1:0] ROM_FILE0   = "ROM Programs/build/blink.bin";
    parameter [8*64-1:0] ROM_FILE1   = "ROM Programs/build/fibo.bin";
    parameter [8*64-1:0] ROM_FILE2   = "ROM Programs/build/counter.bin";

    // each test name max 32 chars
    parameter [8*32-1:0] TEST_NAME0  = "Blink LED Test";
    parameter [8*32-1:0] TEST_NAME1  = "Fibonacci Sequence Test";
    parameter [8*32-1:0] TEST_NAME2  = "Counter Test";

    // each test type max 16 chars
    parameter [8*16-1:0] TEST_TYPE0  = "blink";
    parameter [8*16-1:0] TEST_TYPE1  = "fibonacci";
parameter [8*16-1:0] TEST_TYPE2  = "counter";

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
            reg [8*64-1:0] romfile;
            reg [8*32-1:0] test_name;
            reg [8*16-1:0] test_type;

        begin
            $display("\n========================================");
            $display("DYNAMIC ROM TEST SUITE");
            $display("========================================");
            $display("Found %0d ROM configurations", NUM_TESTS);
            $display("Clock period: 20ns (50MHz)");
            $display("Reset: Active high");
            $display("");
        end
            // Loop through all configured ROMs
        for (i = 0; i < NUM_TESTS; i = i + 1) begin

            case (i)
            0: begin
                romfile    = ROM_FILE0;   test_name = TEST_NAME0;  test_type = TEST_TYPE0;         
            end
            1: begin
                romfile    = ROM_FILE1;   test_name = TEST_NAME1;  test_type = TEST_TYPE1;
            end
            2: begin
                romfile    = ROM_FILE2;   test_name = TEST_NAME2;  test_type = TEST_TYPE2;
                end

            default: begin
                romfile    = {8*64{1'b0}};
                test_name  = {8*32{1'b0}};
                test_type  = {8*16{1'b0}};
                ROM_valid  = 1;
                end
            endcase

            $display("Running test %0d/%0d: %0s", i+1, NUM_TESTS, test_name);
            run_prog(romfile, 0, 1000, test_name, test_type);
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