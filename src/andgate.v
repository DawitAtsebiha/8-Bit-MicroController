module andgate #(parameter W = 4) (
    input  [1:0] in,
    output out       // one extra bit for carry
);
    assign out = in[0] & in[1];
endmodule