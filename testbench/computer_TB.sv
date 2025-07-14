`timescale 1ns/1ps

module computer_TB;

    // ▸ DUT I/O wires (inside the module, not global)
    tri  [7:0] io_data;
    wire [3:0] io_addr;
    wire       io_oe,  io_we;

    // ------------ clock & reset -------------------------------------------
    reg clk = 1'b0;             // start low
    always #10 clk = ~clk;      // 50 MHz
    reg rst = 1'b0;

    // ------------ list of ROM binaries (compile-time constants) -----------
    parameter ROM0 = "build/blink.bin";
    parameter ROM1 = "build/fibo.bin";

    // ------------ Device-Under-Test ---------------------------------------
    computer dut ( .clk     (clk),
                   .reset   (rst),
                   .io_data (io_data),
                   .io_addr (io_addr),
                   .io_oe   (io_oe),
                   .io_we   (io_we) );

    // internal shortcuts
    wire [7:0] PC  = dut.cpu1.data_path1.PC;
    wire [7:0] IR  = dut.cpu1.data_path1.IR;
    wire [7:0] ACC = dut.cpu1.data_path1.A_Reg;

    // ------------ scoreboard / counters -----------------------------------
    integer error_cnt = 0;
    integer cycle_cnt = 0;

    // ----------------------------------------------------------------------
    // 1.  Reference check – verify every I/O write
    // ----------------------------------------------------------------------
    task check_write;
        reg [7:0] exp;
        begin
            if (io_we && io_oe) begin
                golden_model(io_addr, exp);
                if (io_data !== exp) begin
                    $display("ERROR  @%0t  PC=%0h  wrote=%0h  exp=%0h",
                             $time, PC, io_data, exp);
                    error_cnt = error_cnt + 1;
                end
            end
        end
    endtask

    // tiny “golden” model
    task golden_model;
        input  [3:0] addr;
        output [7:0] exp;
        begin
            exp = ACC;          // demo programmes only write A-reg
        end
    endtask

    // -----------------------------------------------------------------------------------------------------------------------------------------
    // 2.  Main sequence – run the two demo ROM images (still working on a way to automatically load assembled ROMs into MicroController)
    // -----------------------------------------------------------------------------------------------------------------------------------------
    integer rom_sel;
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, computer_TB);

        for (rom_sel = 0; rom_sel < 2; rom_sel = rom_sel + 1) begin
            if (rom_sel == 0) load_rom(ROM0);
            else               load_rom(ROM1);

            rst = 1'b0;  repeat (2) @(posedge clk);  rst = 1'b1;
            run_until_halt(2000);          // 2 µs watchdog
            $display("--- finished ROM %0d ---", rom_sel);
        end

        $display("### ALL TESTS %s  (%0d cycles, %0d errors)",
                 (error_cnt==0) ? "PASS" : "FAIL",
                 cycle_cnt, error_cnt);
        $finish;
    end

    // ----------------------------------------------------------------------
    // 3.  Cycle-by-cycle monitor
    // ----------------------------------------------------------------------
    reg prev_rst = 0;                        // remembers previous rst value
    always @(posedge clk) begin
        prev_rst <= rst;                     // update every cycle

        cycle_cnt = cycle_cnt + 1;
        check_write();

        // ---------- safe-to-check window  ----------
        // prev_rst = 1  AND  rst = 1   ⇒  we are at least one full clock
        //                                after reset was released.
        if (prev_rst & rst) begin
            if (^PC === 1'bx)
                $fatal(1, "PC became X at %0t", $time);
        end
    end


    // ----------------------------------------------------------------------
    // 4.  helpers
    // ----------------------------------------------------------------------
    task load_rom;                       
        input [1023:0] filename;         // wide reg holds ASCII name
        integer fd;
        integer idx;
        reg [7:0] byte_buf;
        integer dummy_int;               // ▸ to swallow $fread return
        begin
            fd = $fopen(filename, "rb");
            if (fd == 0) begin
                $display(1, "FATAL: cannot open %0s", filename);
                $finish;
            end
            idx = 0;
            while (!$feof(fd)) begin
                dummy_int = $fread(byte_buf, fd);   // read one byte
                dut.memory1.rom1.ROM[idx] = byte_buf;
                idx = idx + 1;
            end
            $fclose(fd);
        end
    endtask

    task run_until_halt;
        input integer max_cycles;
        integer n;
        begin
            for (n = 0; n < max_cycles; n = n + 1) begin
                @(posedge clk);
                // halt pattern = BRA *  (opcode 20, operand FE)
                if (IR == 8'h20 && dut.memory1.rom1.ROM[PC+1] == 8'hFE)
                    disable run_until_halt;
            end
            $fatal(1, "Watchdog expired after %0d cycles", max_cycles);
            $finish;
        end
    endtask
endmodule
