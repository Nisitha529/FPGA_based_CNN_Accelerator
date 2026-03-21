// Self-checking testbench for comparator module
module tb_comparator;

  // Parameters
  localparam CLK_PERIOD = 10;  // ns

  // Signals
  reg         clk;
  reg         rst_n;
  reg         valid_in;
  reg  [11:0] data_in;
  wire [3:0]  decision;
  wire        valid_out;

  // DUT instantiation
  comparator dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .valid_in (valid_in),
    .data_in  (data_in),
    .decision (decision),
    .valid_out(valid_out)
  );

  // Clock generation
  initial clk = 0;
  always #(CLK_PERIOD/2) clk = ~clk;

  // Test procedure
  initial begin
    // Monitor
    $display("=== Comparator Testbench Started ===");

    // Reset DUT
    rst_n = 0;
    valid_in = 0;
    data_in = 12'h000;
    repeat (5) @(posedge clk);
    rst_n = 1;
    @(posedge clk);
    $display("Reset completed");

    // Test 1: All values equal (0..9 all 100) -> decision should be 0 (first occurrence)
    test_case("All equal", '{100,100,100,100,100,100,100,100,100,100}, 4'd0);

    // Test 2: Maximum at the end (position 9)
    test_case("Max at end", '{10,20,30,40,50,60,70,80,90,100}, 4'd9);

    // Test 3: Maximum at the beginning (position 0)
    test_case("Max at start", '{100,90,80,70,60,50,40,30,20,10}, 4'd0);

    // Test 4: Maximum in the middle (position 4)
    test_case("Max at middle", '{1,2,3,4,100,99,98,97,96,95}, 4'd4);

    // Test 5: Random positive values
    test_case("Random positive", '{55, 23, 87, 12, 99, 34, 76, 45, 68, 31}, 4'd4); // max=99 at index 4

    // Test 6: Values with negative interpretation (signed 12-bit)
    // Use two's complement numbers: e.g., 0x800 = -2048, 0x7FF = 2047
    // Max among these: 0x7FF (2047) at index 1
    test_case("Signed values", '{12'h800, 12'h7FF, 12'h000, 12'hFFF, 12'h001, 12'h002, 12'h003, 12'h004, 12'h005, 12'h006}, 4'd1);

    // Test 7: Random values with duplicates (max appears at multiple positions)
    // First occurrence of max (value 100) is at index 2
    test_case("Duplicate max", '{50, 60, 100, 80, 100, 70, 90, 40, 30, 20}, 4'd2);

    // Test 8: Reset during operation
    $display("\n=== Test 8: Reset during operation ===");
    reset_during_operation();

    $display("\n=== All tests completed ===");
    $finish;
  end

  // Task to run one test case
  task automatic test_case(input string name,
                           input logic [11:0] values [9:0],
                           input logic [3:0] expected);
    logic [3:0] captured_decision;
    integer i;
    bit timeout;

    $display("\n--- Test: %s ---", name);
    $display("Input values: %p", values);

    // Prepare to fill buffer
    rst_n = 0;
    @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // Send 10 valid data samples
    for (i = 0; i < 10; i++) begin
      valid_in = 1;
      data_in = values[i];
      @(posedge clk);
    end
    valid_in = 0;  // Stop sending data

    // Wait for valid_out (max 50 cycles)
    timeout = 0;
    fork
      begin
        @(posedge valid_out);
        captured_decision = decision;
      end
      begin
        repeat (50) @(posedge clk);
        timeout = 1;
      end
    join_any
    disable fork;

    if (timeout) begin
      $error("Test %s: Timeout waiting for valid_out", name);
    end else begin
      $display("Decision = %0d (expected %0d)", captured_decision, expected);
      if (captured_decision == expected)
        $display("PASS");
      else
        $error("Test %s: FAIL - got %0d, expected %0d", name, captured_decision, expected);
    end

    // Wait a few cycles before next test to avoid interference
    repeat (5) @(posedge clk);
  endtask

  // Task to test reset while the module is processing
  task automatic reset_during_operation;
    logic [11:0] values [9:0];
    integer i;

    // Generate 10 values
    for (i = 0; i < 10; i++) values[i] = i * 10;

    // Start filling buffer
    rst_n = 1;
    @(posedge clk);
    for (i = 0; i < 5; i++) begin
      valid_in = 1;
      data_in = values[i];
      @(posedge clk);
    end

    // Assert reset in the middle
    rst_n = 0;
    @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // Continue filling the remaining 5 values
    for (i = 5; i < 10; i++) begin
      valid_in = 1;
      data_in = values[i];
      @(posedge clk);
    end
    valid_in = 0;

    // Wait for valid_out (should be 0 after reset, so must not appear)
    #200;
    if (valid_out === 1'b1) begin
      $error("Reset test: valid_out asserted after reset, but should not");
    end else begin
      $display("Reset test PASS: valid_out remains low");
    end

    // Clean up
    repeat (5) @(posedge clk);
  endtask

  // Optional: Monitor for unexpected valid_out
  always @(posedge valid_out) begin
    $display("INFO: valid_out asserted at time %t, decision = %d", $time, decision);
  end

endmodule