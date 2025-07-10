module `include ".v"
`default_nettype none

module tb_;
reg clk;
reg rst_n;

 
(
    .rst_n (rst_n),
    .clk (clk),
);

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk=~clk;

initial begin
    $dumpfile("tb_.vcd");
    $dumpvars(0, tb_);
end

initial begin
    #1 rst_n<=1'bx;clk<=1'bx;
    #(CLK_PERIOD*3) rst_n<=1;
    #(CLK_PERIOD*3) rst_n<=0;clk<=0;
    repeat(5) @(posedge clk);
    rst_n<=1;
    @(posedge clk);
    repeat(2) @(posedge clk);
    $finish(2);
end

endmodule
`default_nettype wire();

    reg  [1:0] in;            
    wire       out;              

    andgate dut ( .in(in), .out(out) );

    initial begin
        in = 2'b00;              // time 0
        #10 in = 2'b01;          // time 10
        #10 in = 2'b10;          // time 20
        #10 in = 2'b11;          // time 30
    end

endmodule   