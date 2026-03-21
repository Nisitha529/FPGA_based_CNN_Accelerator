`timescale 1ns/1ps

module tb_conv2_buf;

  // ============================================================
  // Parameters
  // ============================================================
  parameter WIDTH     = 12;
  parameter HEIGHT    = 12;
  parameter DATA_BITS = 12;

  localparam OUT_W = WIDTH  - 4;
  localparam OUT_H = HEIGHT - 4;
  localparam TOTAL_OUT = OUT_W * OUT_H;

  // ============================================================
  // DUT Signals
  // ============================================================
  reg clk;
  reg rst_n;
  reg valid_in;
  reg [DATA_BITS-1:0] data_in;

  wire valid_out_buf;

  wire [DATA_BITS-1:0] data_out [0:24];

  // Flatten connections
  assign data_out[0]  = dut.data_out_0;
  assign data_out[1]  = dut.data_out_1;
  assign data_out[2]  = dut.data_out_2;
  assign data_out[3]  = dut.data_out_3;
  assign data_out[4]  = dut.data_out_4;
  assign data_out[5]  = dut.data_out_5;
  assign data_out[6]  = dut.data_out_6;
  assign data_out[7]  = dut.data_out_7;
  assign data_out[8]  = dut.data_out_8;
  assign data_out[9]  = dut.data_out_9;
  assign data_out[10] = dut.data_out_10;
  assign data_out[11] = dut.data_out_11;
  assign data_out[12] = dut.data_out_12;
  assign data_out[13] = dut.data_out_13;
  assign data_out[14] = dut.data_out_14;
  assign data_out[15] = dut.data_out_15;
  assign data_out[16] = dut.data_out_16;
  assign data_out[17] = dut.data_out_17;
  assign data_out[18] = dut.data_out_18;
  assign data_out[19] = dut.data_out_19;
  assign data_out[20] = dut.data_out_20;
  assign data_out[21] = dut.data_out_21;
  assign data_out[22] = dut.data_out_22;
  assign data_out[23] = dut.data_out_23;
  assign data_out[24] = dut.data_out_24;

  // ============================================================
  // DUT
  // ============================================================
  conv2_buf #(
    .WIDTH(WIDTH),
    .HEIGHT(HEIGHT),
    .DATA_BITS(DATA_BITS)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(valid_in),
    .data_in(data_in),
    .valid_out_buf(valid_out_buf)
  );

  // ============================================================
  // Clock
  // ============================================================
  always #5 clk = ~clk;

  // ============================================================
  // Reference Model
  // ============================================================
  reg [DATA_BITS-1:0] input_image [0:HEIGHT-1][0:WIDTH-1];
  reg [DATA_BITS-1:0] expected     [0:OUT_H-1][0:OUT_W-1][0:24];

  integer r, c, i, j;

  task generate_input_and_expected;
    begin
      // Random input
      for (r = 0; r < HEIGHT; r++) begin
        for (c = 0; c < WIDTH; c++) begin
          input_image[r][c] = $random & 12'hFFF;
        end
      end

      // Sliding window
      for (r = 0; r < OUT_H; r++) begin
        for (c = 0; c < OUT_W; c++) begin
          for (i = 0; i < 5; i++) begin
            for (j = 0; j < 5; j++) begin
              expected[r][c][i*5 + j] = input_image[r+i][c+j];
            end
          end
        end
      end
    end
  endtask

  // ============================================================
  // Stimulus
  // ============================================================
  task send_image;
    begin
      for (r = 0; r < HEIGHT; r++) begin
        for (c = 0; c < WIDTH; c++) begin
          @(posedge clk);
          valid_in = 1;
          data_in  = input_image[r][c];
        end
      end
      @(posedge clk);
      valid_in = 0;
      data_in  = 0;
    end
  endtask

  // ============================================================
  // Checker
  // ============================================================
  integer out_cnt;
  integer out_row, out_col;
  integer errors;

  always @(posedge clk) begin
    if (!rst_n) begin
      out_cnt <= 0;
    end
    else if (valid_out_buf) begin
      out_row = out_cnt / OUT_W;
      out_col = out_cnt % OUT_W;

      if (out_cnt >= TOTAL_OUT) begin
        $display("ERROR: extra output at time %0t", $time);
        errors++;
      end else begin
        for (i = 0; i < 25; i++) begin
          if (data_out[i] !== expected[out_row][out_col][i]) begin
            $display("Mismatch at [%0d,%0d] idx=%0d DUT=%0d EXP=%0d",
                     out_row, out_col, i,
                     data_out[i], expected[out_row][out_col][i]);
            errors++;
          end
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
    data_in  = 0;
    errors   = 0;
    out_cnt  = 0;

    // Reset
    repeat (5) @(posedge clk);
    rst_n = 1;
    @(posedge clk);
    $display("Reset completed.");

    // ----------------------------------------------------------
    // Test 1: Normal
    // ----------------------------------------------------------
    $display("\n=== Test 1: Normal operation ===");

    generate_input_and_expected();
    send_image();

    wait(out_cnt == TOTAL_OUT);

    if (errors == 0)
      $display("Test 1 PASS");
    else
      $display("Test 1 FAIL");

    // ----------------------------------------------------------
    // Test 2: Reset mid-stream
    // ----------------------------------------------------------
    $display("\n=== Test 2: Reset during operation ===");

    generate_input_and_expected();

    // Partial send
    for (r = 0; r < 4; r++) begin
      for (c = 0; c < WIDTH; c++) begin
        @(posedge clk);
        valid_in = 1;
        data_in  = input_image[r][c];
      end
    end

    // Reset
    @(posedge clk);
    rst_n = 0;
    @(posedge clk);
    rst_n = 1;

    // IMPORTANT: allow DUT to settle
    repeat (5) @(posedge clk);

    // Restart stream cleanly
    out_cnt = 0;
    send_image();

    wait(out_cnt == TOTAL_OUT);

    if (errors == 0)
      $display("Test 2 PASS");
    else
      $display("Test 2 FAIL");

    // ----------------------------------------------------------
    $display("\n=== TEST COMPLETE ===");
    $display("Total errors: %0d", errors);

    $finish;
  end

endmodule