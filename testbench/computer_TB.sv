`timescale 1ns/1ps

module computer_TB;

    tri  [7:0] io_data;
    wire [3:0] io_addr;
    wire       io_oe, io_we;

    reg clk = 0;  always #10 clk = ~clk;
    reg reset = 0;

    parameter ROM0 = "ROM Programs/build/blink.bin";
    parameter ROM1 = "ROM Programs/build/fibo.bin";

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
    reg [7:0] fibonacci_output;
    reg [7:0] blink_output;
    reg fibonacci_valid;
    reg blink_valid;
    integer fib_sequence_count;
    integer blink_sequence_count;
    
    initial begin
        fibonacci_output = 0;
        blink_output = 0;
        fibonacci_valid = 0;
        blink_valid = 0;
        fib_sequence_count = 0;
        blink_sequence_count = 0;
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

    task run_prog;
        input romfile;
        input base_addr;
        input max_cycles;
        input [255:0] test_name;

        reg [1023:0] romfile;
        integer      base_addr, max_cycles;
        reg [255:0] test_name;

        integer n, start_cycles, fib_count, blink_count;
        reg done;
    begin
        $display("\n=== Starting Test: %0s ===", test_name);
        $display("Loading ROM: %0s at base address %0d", romfile, base_addr);
        
        load_rom(romfile, base_addr);
        
        // Set PC to start execution from the base address
        reset = 0; repeat (2) @(posedge clk); 
        dut.cpu1.data_path1.PC = base_addr;  // Set PC to program start address
        reset = 1;
        
        start_cycles = cycles;
        done = 0;
        fib_count = 0;
        blink_count = 0;
        
        // Reset output monitoring signals
        fibonacci_valid = 0;
        blink_valid = 0;
        
        // Set the active test type
        if (test_name == "Fibonacci Sequence Test") begin
            fibonacci_valid = 1;
            blink_valid = 0;
        end else begin
            fibonacci_valid = 0;
            blink_valid = 1;
        end
        
        $display("Program execution started at cycle %0d, PC set to 0x%02h", cycles, base_addr);
        
        for (n = 0; n < max_cycles && !done; n = n + 1) begin
            @(posedge clk); cycles = cycles + 1;
            
            // Monitor I/O activity
            if (io_we) begin
                if (test_name == "Fibonacci Sequence Test") begin
                    $display("  [Cycle %0d] F(%0d) = %0d (0x%02h)", cycles, fib_count, io_data, io_data);
                    fibonacci_output = io_data;  // Update GTKWave signal
                    fib_sequence_count = fib_count;  // Update sequence counter for GTKWave
                    fib_count = fib_count + 1;
                end else begin
                    $display("  [Cycle %0d] BLINK #%0d: Port[0x%h] = 0x%02h %s", cycles, blink_count, io_addr, io_data, (io_data == 8'h01) ? "(LED ON)" : "(LED OFF)");
                    blink_output = io_data;  // Update GTKWave signal
                    blink_sequence_count = blink_count;  // Update blink counter for GTKWave
                    blink_count = blink_count + 1;
                end
            end
            
            // Check for program halt condition
            if (test_name == "Fibonacci Sequence Test" && IR == 8'h20 && dut.memory1.rom1.ROM[PC+1] == 8'hFE) begin
                $display("  [Cycle %0d] HALT detected: BRA $FE instruction", cycles);
                done = 1;
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



    initial begin
        
        $dumpfile("waves.vcd");
        $dumpvars(clk, reset, cycles);
        // CPU signals
        $dumpvars(PC, IR, A_Reg, B_Reg, fibonacci_output, blink_output);
        // I/O signals
        $dumpvars(io_addr, io_data, io_we);
        // Program monitoring signals
        $dumpvars(fibonacci_valid, blink_valid, fib_sequence_count, blink_sequence_count);
        
        $display("VCD Dump Info - Limited signal set:");
        $display("- Clock and reset signals");
        $display("- CPU state: PC, IR, A and B Registers, Fibonacci and Blink outputs");
        $display("- I/O signals: io_addr, io_data, io_we");
        $display("- Program outputs: fibonacci_output, blink_output");
        $display("- Program indicators: fibonacci_valid, blink_valid, fib_sequence_count, blink_sequence_count");
        
        $display("========================================");
        $display("8-Bit MightyController Testbench Suite");
        $display("========================================");
        $display("Clock period: 20ns (50MHz)");
        $display("Reset: Active high");
        $display("");

        // Test Case 1: Blink Program (LED Toggle) - Extended for more cycles to show looping
        run_prog(ROM0, 0, 1000, "Blink LED Test");
        
        // Test Case 2: Fibonacci Sequence  
        run_prog(ROM1, 0, 1000, "Fibonacci Sequence Test");

        // Final Summary
        $display("\n========================================");
        $display("TESTBENCH SUMMARY");
        $display("========================================");
        $display("Total simulation cycles: %0d", cycles);
        $display("Simulation time: %0dns", $time);
        $display("All tests completed successfully!");
        $display("========================================");
        
        $finish;
    end
endmodule
