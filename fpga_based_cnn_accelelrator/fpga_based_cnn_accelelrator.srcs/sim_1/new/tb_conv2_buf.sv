module tb_conv2_buf;

  parameter integer WIDTH      = 12;
  parameter integer HEIGHT     = 12;
  parameter integer DATA_BITS  = 12;
  parameter integer FILTERSIZE = 5;

  reg clk;
  reg rst_n;

  reg valid_in;
  reg [DATA_BITS-1:0] data_in;

  wire [DATA_BITS-1:0] data_out_0;
  wire [DATA_BITS-1:0] data_out_1;
  wire [DATA_BITS-1:0] data_out_2;
  wire [DATA_BITS-1:0] data_out_3;
  wire [DATA_BITS-1:0] data_out_4;
  wire [DATA_BITS-1:0] data_out_5;
  wire [DATA_BITS-1:0] data_out_6;
  wire [DATA_BITS-1:0] data_out_7;
  wire [DATA_BITS-1:0] data_out_8;
  wire [DATA_BITS-1:0] data_out_9;
  wire [DATA_BITS-1:0] data_out_10;
  wire [DATA_BITS-1:0] data_out_11;
  wire [DATA_BITS-1:0] data_out_12;
  wire [DATA_BITS-1:0] data_out_13;
  wire [DATA_BITS-1:0] data_out_14;
  wire [DATA_BITS-1:0] data_out_15;
  wire [DATA_BITS-1:0] data_out_16;
  wire [DATA_BITS-1:0] data_out_17;
  wire [DATA_BITS-1:0] data_out_18;
  wire [DATA_BITS-1:0] data_out_19;
  wire [DATA_BITS-1:0] data_out_20;
  wire [DATA_BITS-1:0] data_out_21;
  wire [DATA_BITS-1:0] data_out_22;
  wire [DATA_BITS-1:0] data_out_23;
  wire [DATA_BITS-1:0] data_out_24;
  wire valid_out_buf;

  conv2_buf #(
    .WIDTH    (WIDTH),
    .HEIGHT   (HEIGHT),
    .DATA_BITS(DATA_BITS)
  ) dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .valid_in     (valid_in),
    .data_in      (data_in),
    .data_out_0   (data_out_0),
    .data_out_1   (data_out_1),
    .data_out_2   (data_out_2),
    .data_out_3   (data_out_3),
    .data_out_4   (data_out_4),
    .data_out_5   (data_out_5),
    .data_out_6   (data_out_6),
    .data_out_7   (data_out_7),
    .data_out_8   (data_out_8),
    .data_out_9   (data_out_9),
    .data_out_10  (data_out_10),
    .data_out_11  (data_out_11),
    .data_out_12  (data_out_12),
    .data_out_13  (data_out_13),
    .data_out_14  (data_out_14),
    .data_out_15  (data_out_15),
    .data_out_16  (data_out_16),
    .data_out_17  (data_out_17),
    .data_out_18  (data_out_18),
    .data_out_19  (data_out_19),
    .data_out_20  (data_out_20),
    .data_out_21  (data_out_21),
    .data_out_22  (data_out_22),
    .data_out_23  (data_out_23),
    .data_out_24  (data_out_24),
    .valid_out_buf(valid_out_buf)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Image storage
  reg [DATA_BITS-1:0] image [0:HEIGHT-1][0:WIDTH-1];
  integer row, col;
  integer pixel_cnt;   // number of pixels sent so far
  integer valid_cnt;   // number of valid_out_buf pulses seen
  integer error_cnt;   // number of mismatches

  // Expected window (row‑major order)
  reg [DATA_BITS-1:0] expected [0:FILTERSIZE*FILTERSIZE-1];

  initial begin
    clk = 0;
    rst_n = 0;
    valid_in = 0;
    data_in = 0;
    pixel_cnt = 0;
    valid_cnt = 0;
    error_cnt = 0;

    // Dump waveform
    $dumpfile("tb_conv2_buf.vcd");
    $dumpvars(0, tb_conv2_buf);

    #20 rst_n = 1;
    #10;

    // Feed entire 12x12 image
    for (row = 0; row < HEIGHT; row = row + 1) begin
      for (col = 0; col < WIDTH; col = col + 1) begin
        @(posedge clk);
        valid_in = 1;
        data_in = row * WIDTH + col;   // simple pattern
        image[row][col] = data_in;
        pixel_cnt = pixel_cnt + 1;
      end
    end

    @(posedge clk);
    valid_in = 0;
    repeat (20) @(posedge clk);   // wait for any remaining outputs

    $display("Total valid outputs: %0d", valid_cnt);
    if (valid_cnt == (HEIGHT - FILTERSIZE + 1) * (WIDTH - FILTERSIZE + 1))
      $display("Valid count OK");
    else
      $display("ERROR: Expected %0d valid outputs",
               (HEIGHT - FILTERSIZE + 1) * (WIDTH - FILTERSIZE + 1));

    if (error_cnt == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED with %0d errors", error_cnt);

    $finish;
  end

  // Check outputs on the falling edge to avoid race conditions
  always @(negedge clk) begin
    if (rst_n && valid_out_buf) begin
      valid_cnt = valid_cnt + 1;

      // Determine window position (top‑left row and column)
      // First valid output occurs after the buffer is full:
      // pixel_cnt counts total pixels sent. The first streaming pixel is
      // pixel_cnt = WIDTH*FILTERSIZE + 1 (when the first pixel of the 6th row arrives)
      if (pixel_cnt >= WIDTH * FILTERSIZE + 1) begin
        integer m, w, h;
        m = pixel_cnt - (WIDTH * FILTERSIZE + 1);   // 0 at first streaming pixel
        w = m % WIDTH;
        h = m / WIDTH;

        // Build expected window from stored image
        for (int i = 0; i < FILTERSIZE; i = i + 1) begin
          for (int j = 0; j < FILTERSIZE; j = j + 1) begin
            expected[i * FILTERSIZE + j] = image[h + i][w + j];
          end
        end

        compare_outputs;
      end
    end
  end

  task compare_outputs;
    begin
      if (data_out_0  !== expected[ 0]) error( 0, expected[ 0], data_out_0 );
      if (data_out_1  !== expected[ 1]) error( 1, expected[ 1], data_out_1 );
      if (data_out_2  !== expected[ 2]) error( 2, expected[ 2], data_out_2 );
      if (data_out_3  !== expected[ 3]) error( 3, expected[ 3], data_out_3 );
      if (data_out_4  !== expected[ 4]) error( 4, expected[ 4], data_out_4 );
      if (data_out_5  !== expected[ 5]) error( 5, expected[ 5], data_out_5 );
      if (data_out_6  !== expected[ 6]) error( 6, expected[ 6], data_out_6 );
      if (data_out_7  !== expected[ 7]) error( 7, expected[ 7], data_out_7 );
      if (data_out_8  !== expected[ 8]) error( 8, expected[ 8], data_out_8 );
      if (data_out_9  !== expected[ 9]) error( 9, expected[ 9], data_out_9 );
      if (data_out_10 !== expected[10]) error(10, expected[10], data_out_10);
      if (data_out_11 !== expected[11]) error(11, expected[11], data_out_11);
      if (data_out_12 !== expected[12]) error(12, expected[12], data_out_12);
      if (data_out_13 !== expected[13]) error(13, expected[13], data_out_13);
      if (data_out_14 !== expected[14]) error(14, expected[14], data_out_14);
      if (data_out_15 !== expected[15]) error(15, expected[15], data_out_15);
      if (data_out_16 !== expected[16]) error(16, expected[16], data_out_16);
      if (data_out_17 !== expected[17]) error(17, expected[17], data_out_17);
      if (data_out_18 !== expected[18]) error(18, expected[18], data_out_18);
      if (data_out_19 !== expected[19]) error(19, expected[19], data_out_19);
      if (data_out_20 !== expected[20]) error(20, expected[20], data_out_20);
      if (data_out_21 !== expected[21]) error(21, expected[21], data_out_21);
      if (data_out_22 !== expected[22]) error(22, expected[22], data_out_22);
      if (data_out_23 !== expected[23]) error(23, expected[23], data_out_23);
      if (data_out_24 !== expected[24]) error(24, expected[24], data_out_24);
    end
  endtask

  task error(input integer idx, input [DATA_BITS-1:0] exp, act);
    begin
      $display("ERROR at valid_out %0d, output %0d: expected %0d, got %0d",
               valid_cnt, idx, exp, act);
      error_cnt = error_cnt + 1;
    end
  endtask

endmodule