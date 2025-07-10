`timescale 1ns/1ps
module computer_TB;
   //----------------------------------------
   // Adjustable Test parameters
   //----------------------------------------
   parameter  CLK_PERIOD        = 20;      // 50 MHz
   parameter  NUM_BRANCH_LOOPS  = 800;       // how many BRA iterations to watch
   parameter  POST_TEST_DELAY   = 200;     // ns after final check before finish
   //----------------------------------------

   // Test-bench signals
   reg        clk_tb  = 0;
   reg        reset_tb= 0;
   wire [7:0] io_data;
   wire [3:0] io_addr;
   wire       io_oe, io_we;

   // External I/O stub
   reg  [7:0] ext_io_data = 8'h00;
   reg        ext_drive_bus=0;
   assign io_data = ext_drive_bus ? ext_io_data : 8'bz;

   // DUT
   computer uut ( .clk(clk_tb), .reset(reset_tb),
                  .io_data(io_data), .io_addr(io_addr),
                  .io_oe(io_oe), .io_we(io_we) );

   wire [7:0] PC  = uut.cpu1.data_path1.PC;
   wire [7:0] IR  = uut.cpu1.data_path1.IR;
   wire [7:0] A   = uut.cpu1.data_path1.A_Reg;
   wire [4:0] ST  = uut.cpu1.control_unit1.state;

   // Clock
   always #(CLK_PERIOD/2) clk_tb = ~clk_tb;

   // Test sequence
   integer branch_count = 0;
   initial begin
      //-------------------------------------
      // Dump-file setup
      //-------------------------------------
      $dumpfile("waves.vcd");
      $dumpvars(0,computer_TB);

      //-------------------------------------
      // Power-on reset
      //-------------------------------------
      #100  reset_tb = 1;                   // de-assert reset
      $display("[%0t] Reset released", $time);

      //-------------------------------------
      // 1. Wait for LDA #$AA to execute
      //-------------------------------------
      wait (IR == 8'h86);                   // opcode fetch
      wait (A  == 8'hAA);                   // value loaded
      $display("[%0t] LDA complete, A=%h", $time, A);

      //-------------------------------------
      // 2. Wait for STAA $F0 and confirm data on bus
      //-------------------------------------
      wait (IR == 8'h96 && io_we);          // STAA opcode & write pulse
      if (io_data !== 8'hAA)
           $fatal(1,"STAA wrote %h (expected AA)",io_data);
      $display("[%0t] STAA OK, data=%h", $time, io_data);

      //-------------------------------------
      // 3. Observe BRA loop NUM_BRANCH_LOOPS times
      //-------------------------------------
      wait (IR == 8'h20);                   // first BRA seen
      repeat (NUM_BRANCH_LOOPS-1) begin
         @(posedge clk_tb);
         wait (IR == 8'h20);
         branch_count = branch_count + 1;
      end
      $display("[%0t] Completed %0d BRA iterations",
               $time, NUM_BRANCH_LOOPS);

      //-------------------------------------
      // 4. Extra settle time, then quit
      //-------------------------------------
      #(POST_TEST_DELAY);
      $display("[%0t] Test-bench finished OK", $time);
      $finish;
   end

   // Optional live trace (comment out if wave dump is enough)
   always @(posedge clk_tb)
      $display("T=%0t  PC=%h IR=%h A=%h ST=%0d IO_WE=%b IO_ADDR=%h",
               $time, PC, IR, A, ST, io_we, io_addr);

endmodule
