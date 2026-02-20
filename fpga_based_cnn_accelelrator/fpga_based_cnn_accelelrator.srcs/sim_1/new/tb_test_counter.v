module tb_test_counter;
    reg clk;
    reg reset;
    wire [3:0] count;

    // Instantiate the counter
    test_counter uut (
        .clk(clk),
        .reset(reset),
        .count(count)
    );

    // Generate clock (10 ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Apply stimulus
    initial begin
        reset = 1;
        #15 reset = 0;
        #100 $finish;
    end

    // Dump waveform data
    initial begin
        $dumpfile("tb_test_counter.vcd");
        $dumpvars(0, tb_test_counter);
    end
endmodule
