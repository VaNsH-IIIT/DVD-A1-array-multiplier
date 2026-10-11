`timescale 1ns/1ps
// Exhaustive self-checking testbench for mult_array.
// Inputs are applied on the falling edge; the product is checked after
// two rising edges (2-cycle latency: edge 1 -> input regs, edge 2 -> output reg).
module tb_mult;

    reg        clk;
    reg        rst_n;
    reg  [3:0] a, b;
    wire [7:0] p;

    integer i, j;
    integer vectors, errors;
    reg [7:0] expected;

    mult_array dut (
        .clk  (clk),
        .rst_n(rst_n),
        .a    (a),
        .b    (b),
        .p    (p)
    );

    // 10 ns clock period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        $timeformat(-9, 0, " ns", 8);
        $dumpfile("mult.vcd");
        $dumpvars(0, tb_mult);

        vectors = 0;
        errors  = 0;
        a       = 4'd0;
        b       = 4'd0;

        // hold reset low for the first 2 clock cycles
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                @(negedge clk);
                a = i;
                b = j;
                expected = i * j;          // '*' allowed in the testbench only

                @(posedge clk);            // edge 1: a, b captured into input regs
                @(posedge clk);            // edge 2: product captured into p
                #1;

                vectors = vectors + 1;
                if (p !== expected) begin
                    errors = errors + 1;
                    $display("MISMATCH at t=%0t: a=%0d b=%0d p=%0d expected=%0d",
                             $time, a, b, p, expected);
                end
            end
        end

        if (errors == 0)
            $display("PASS: %0d vectors checked, %0d errors", vectors, errors);
        else
            $display("FAIL: %0d vectors checked, %0d errors", vectors, errors);

        $finish;
    end

endmodule
