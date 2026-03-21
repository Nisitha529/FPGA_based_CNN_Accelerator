`timescale 1ns/1ps

module tb_maxpool_relu;

  // ============================================================
  // Parameters (must match DUT)
  // ============================================================
  localparam CONV_BIT       = 12;
  localparam HALF_WIDTH     = 12;
  localparam HALF_HEIGHT    = 12;
  localparam HALF_WIDTH_BIT = 4;

  localparam IN_WIDTH   = 2 * HALF_WIDTH;
  localparam IN_HEIGHT  = 2 * HALF_HEIGHT;
  localparam OUT_WIDTH  = HALF_WIDTH;
  localparam OUT_HEIGHT = HALF_HEIGHT;
  localparam TOTAL_OUT  = OUT_WIDTH * OUT_HEIGHT;

  // ============================================================
  // DUT Signals
  // ============================================================
  reg clk;
  reg rst_n;
  reg valid_in;

  reg signed [CONV_BIT-1:0] conv_out_1;
  reg signed [CONV_BIT-1:0] conv_out_2;
  reg signed [CONV_BIT-1:0] conv_out_3;

  wire [CONV_BIT-1:0] max_value_1;
  wire [CONV_BIT-1:0] max_value_2;
  wire [CONV_BIT-1:0] max_value_3;
  wire valid_out_relu;

  // ============================================================
  // DUT Instance
  // ============================================================
  maxpool_relu #(
    .CONV_BIT       (CONV_BIT),
    .HALF_WIDTH     (HALF_WIDTH),
    .HALF_HEIGHT    (HALF_HEIGHT),
    .HALF_WIDTH_BIT (HALF_WIDTH_BIT)
  ) dut (
    .clk           (clk),
    .rst_n         (rst_n),
    .valid_in      (valid_in),
    .conv_out_1    (conv_out_1),
    .conv_out_2    (conv_out_2),
    .conv_out_3    (conv_out_3),
    .max_value_1   (max_value_1),
    .max_value_2   (max_value_2),
    .max_value_3   (max_value_3),
    .valid_out_relu(valid_out_relu)
  );

  // ============================================================
  // Clock Generation
  // ============================================================
  always #5 clk = ~clk;

  // ============================================================
  // Reference Model Storage
  // ============================================================
  reg signed [CONV_BIT-1:0] input_img1 [0:IN_HEIGHT-1][0:IN_WIDTH-1];
  reg signed [CONV_BIT-1:0] input_img2 [0:IN_HEIGHT-1][0:IN_WIDTH-1];
  reg signed [CONV_BIT-1:0] input_img3 [0:IN_HEIGHT-1][0:IN_WIDTH-1];

  reg signed [CONV_BIT-1:0] expected1 [0:OUT_HEIGHT-1][0:OUT_WIDTH-1];
  reg signed [CONV_BIT-1:0] expected2 [0:OUT_HEIGHT-1][0:OUT_WIDTH-1];
  reg signed [CONV_BIT-1:0] expected3 [0:OUT_HEIGHT-1][0:OUT_WIDTH-1];

  // ============================================================
  // Control / Scoreboard
  // ============================================================
  integer errors;
  integer out_cnt;
  integer out_row, out_col;

  integer r, c;

  // Frame tracking
  reg checking_enabled;
  reg valid_in_d;

  // ============================================================
  // ReLU Function
  // ============================================================
  function signed [CONV_BIT-1:0] relu;
    input signed [CONV_BIT-1:0] x;
    relu = (x > 0) ? x : 0;
  endfunction

  // ============================================================
  // Generate Input + Expected Output
  // ============================================================
  task generate_input_and_expected;
    reg signed [CONV_BIT-1:0] max1, max2, max3;
    begin
      for (r = 0; r < IN_HEIGHT; r++) begin
        for (c = 0; c < IN_WIDTH; c++) begin
          input_img1[r][c] = $random % 4096 - 2048;
          input_img2[r][c] = $random % 4096 - 2048;
          input_img3[r][c] = $random % 4096 - 2048;
        end
      end

      for (r = 0; r < OUT_HEIGHT; r++) begin
        for (c = 0; c < OUT_WIDTH; c++) begin
          max1 = input_img1[2*r][2*c];
          if (input_img1[2*r][2*c+1] > max1) max1 = input_img1[2*r][2*c+1];
          if (input_img1[2*r+1][2*c] > max1) max1 = input_img1[2*r+1][2*c];
          if (input_img1[2*r+1][2*c+1] > max1) max1 = input_img1[2*r+1][2*c+1];
          expected1[r][c] = relu(max1);

          max2 = input_img2[2*r][2*c];
          if (input_img2[2*r][2*c+1] > max2) max2 = input_img2[2*r][2*c+1];
          if (input_img2[2*r+1][2*c] > max2) max2 = input_img2[2*r+1][2*c];
          if (input_img2[2*r+1][2*c+1] > max2) max2 = input_img2[2*r+1][2*c+1];
          expected2[r][c] = relu(max2);

          max3 = input_img3[2*r][2*c];
          if (input_img3[2*r][2*c+1] > max3) max3 = input_img3[2*r][2*c+1];
          if (input_img3[2*r+1][2*c] > max3) max3 = input_img3[2*r+1][2*c];
          if (input_img3[2*r+1][2*c+1] > max3) max3 = input_img3[2*r+1][2*c+1];
          expected3[r][c] = relu(max3);
        end
      end
    end
  endtask

  // ============================================================
  // Send Full Image
  // ============================================================
  task send_full_image;
    begin
      for (r = 0; r < IN_HEIGHT; r++) begin
        for (c = 0; c < IN_WIDTH; c++) begin
          @(posedge clk);
          valid_in   <= 1;
          conv_out_1 <= input_img1[r][c];
          conv_out_2 <= input_img2[r][c];
          conv_out_3 <= input_img3[r][c];
        end
      end

      @(posedge clk);
      valid_in   <= 0;
      conv_out_1 <= 0;
      conv_out_2 <= 0;
      conv_out_3 <= 0;
    end
  endtask

  // ============================================================
  // Frame detection (for clean checking)
  // ============================================================
  always @(posedge clk) begin
    valid_in_d <= valid_in;

    // Enable checking only on fresh frame start
    if (valid_in & ~valid_in_d) begin
      checking_enabled <= 1;
      out_cnt <= 0;
    end

    if (~rst_n) begin
      checking_enabled <= 0;
      out_cnt <= 0;
    end
  end

  // ============================================================
  // Scoreboard
  // ============================================================
  always @(posedge clk) begin
    if (valid_out_relu && checking_enabled) begin

      if (out_cnt < TOTAL_OUT) begin
        out_row = out_cnt / OUT_WIDTH;
        out_col = out_cnt % OUT_WIDTH;

        if (max_value_1 !== expected1[out_row][out_col]) begin
          $display("MISMATCH [%0d,%0d] ch1: DUT=%0d EXP=%0d",
                   out_row, out_col, max_value_1, expected1[out_row][out_col]);
          errors++;
        end

        if (max_value_2 !== expected2[out_row][out_col]) begin
          $display("MISMATCH [%0d,%0d] ch2: DUT=%0d EXP=%0d",
                   out_row, out_col, max_value_2, expected2[out_row][out_col]);
          errors++;
        end

        if (max_value_3 !== expected3[out_row][out_col]) begin
          $display("MISMATCH [%0d,%0d] ch3: DUT=%0d EXP=%0d",
                   out_row, out_col, max_value_3, expected3[out_row][out_col]);
          errors++;
        end

      end

      out_cnt++;
    end
  end

  // ============================================================
  // Test Sequence
  // ============================================================
  initial begin
    clk = 0;
    rst_n = 0;
    valid_in = 0;
    conv_out_1 = 0;
    conv_out_2 = 0;
    conv_out_3 = 0;
    errors = 0;
    out_cnt = 0;
    checking_enabled = 0;

    // Reset
    repeat (5) @(posedge clk);
    rst_n = 1;
    @(posedge clk);
    $display("Reset completed.");

    // =========================
    // Test 1
    // =========================
    $display("\n=== Test 1: Normal ===");
    generate_input_and_expected();
    send_full_image();

    #10000;

    if (out_cnt == TOTAL_OUT)
      $display("Test 1 PASS");
    else begin
      $display("Test 1 FAIL: got %0d outputs", out_cnt);
      errors++;
    end

    // =========================
    // Test 2
    // =========================
    $display("\n=== Test 2: Reset mid-stream ===");

    generate_input_and_expected();

    // Partial send
    for (r = 0; r < 2; r++) begin
      for (c = 0; c < IN_WIDTH; c++) begin
        @(posedge clk);
        valid_in   <= 1;
        conv_out_1 <= input_img1[r][c];
        conv_out_2 <= input_img2[r][c];
        conv_out_3 <= input_img3[r][c];
      end
    end

    // Reset mid-stream
    rst_n <= 0;
    @(posedge clk);
    rst_n <= 1;
    valid_in <= 0;

    @(posedge clk);

    // Send fresh frame
    send_full_image();

    #10000;

    if (out_cnt == TOTAL_OUT)
      $display("Test 2 PASS");
    else begin
      $display("Test 2 FAIL: got %0d outputs", out_cnt);
      errors++;
    end

    // ============================================================
    // Summary
    // ============================================================
    $display("\n=== SUMMARY ===");
    if (errors == 0)
      $display("ALL TESTS PASSED");
    else
      $display("FAILED with %0d errors", errors);

    $finish;
  end

endmodule