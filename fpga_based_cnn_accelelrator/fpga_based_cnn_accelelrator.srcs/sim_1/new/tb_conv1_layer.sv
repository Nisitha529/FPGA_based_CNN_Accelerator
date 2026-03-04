/*------------------------------------------------------------------------
 *  Testbench for conv1_layer
 *------------------------------------------------------------------------*/

module tb_conv1_layer;

  // Parameters
  localparam integer WIDTH       = 28;
  localparam integer HEIGHT      = 28;
  localparam integer DATA_BITS   = 8;
  localparam integer FILTER_SIZE = 5;
  localparam integer CHANNEL_LEN = 3;

  // Clock and reset
  reg clk;
  reg rst_n;

  // DUT inputs
  reg valid_in;
  reg [7:0] data_in;

  // DUT outputs
  wire signed [11:0] conv_out_1;
  wire signed [11:0] conv_out_2;
  wire signed [11:0] conv_out_3;
  wire               valid_out_conv;

  // Instantiate DUT
  conv1_layer dut (
    .clk            (clk),
    .rst_n          (rst_n),
    .valid_in       (valid_in),
    .data_in        (data_in),
    .conv_out_1     (conv_out_1),
    .conv_out_2     (conv_out_2),
    .conv_out_3     (conv_out_3),
    .valid_out_conv (valid_out_conv)
  );

  // Clock generation
  always #5 clk = ~clk;

  // -----------------------------------------------------------------
  // Reference model: same weights and bias as the DUT's submodules
  // -----------------------------------------------------------------
  reg signed [7:0] ref_weight_1 [0:FILTER_SIZE*FILTER_SIZE-1];
  reg signed [7:0] ref_weight_2 [0:FILTER_SIZE*FILTER_SIZE-1];
  reg signed [7:0] ref_weight_3 [0:FILTER_SIZE*FILTER_SIZE-1];
  reg signed [7:0] ref_bias     [0:CHANNEL_LEN-1];

  // Load the same files as conv1_calc
  initial begin
    $readmemh("conv1_weight_1.mem", ref_weight_1);
    $readmemh("conv1_weight_2.mem", ref_weight_2);
    $readmemh("conv1_weight_3.mem", ref_weight_3);
    $readmemh("conv1_bias.mem",     ref_bias);
  end

  // -----------------------------------------------------------------
  // Image storage and test control
  // -----------------------------------------------------------------
  reg [7:0] image [0:HEIGHT-1][0:WIDTH-1];   // stored image
  integer row, col;
  integer pixel_cnt;        // number of pixels sent
  integer valid_cnt;        // number of valid_out_conv pulses seen
  integer error_cnt;        // total errors
  integer window_idx;       // index of current window (0..575)

  // Expected accumulator values before truncation/bias
  reg signed [19:0] exp_acc1, exp_acc2, exp_acc3;

  // Pipeline delay for expected values (matching conv1_calc's 4 cycles
  // plus the line buffer's latency). The line buffer introduces a delay:
  // first valid_out_buf appears after the first 140 pixels + 1.
  // We'll use a simple counter to know when a window is expected.

  // Function to compute expected accumulator (20‑bit signed)
  function automatic signed [19:0] compute_conv;
    input [7:0] pixels [0:24];
    input signed [7:0] weights [0:24];
    integer k;
    reg signed [19:0] sum;
    begin
      sum = 0;
      for (k = 0; k < 25; k = k + 1) begin
        // Pixel is unsigned, extend with 0 to 9 bits signed
        sum = sum + ({{12{weights[k][7]}}, weights[k]} * {{12{1'b0}}, pixels[k]});
      end
      compute_conv = sum;
    end
  endfunction

  // Bias extension
  function automatic signed [11:0] ext_bias;
    input signed [7:0] b;
    begin
      ext_bias = (b[7] == 1) ? {4'b1111, b} : {4'b0000, b};
    end
  endfunction

  initial begin
    clk = 0;
    rst_n = 0;
    valid_in = 0;
    data_in = 0;
    pixel_cnt = 0;
    valid_cnt = 0;
    error_cnt = 0;

    $dumpfile("tb_conv1_layer.vcd");
    $dumpvars(0, tb_conv1_layer);

    #20 rst_n = 1;
    #10;

    // Feed entire 28x28 image
    for (row = 0; row < HEIGHT; row = row + 1) begin
      for (col = 0; col < WIDTH; col = col + 1) begin
        @(posedge clk);
        valid_in = 1;
        data_in = row * WIDTH + col;   // predictable pattern
        image[row][col] = data_in;
        pixel_cnt = pixel_cnt + 1;
      end
    end

    @(posedge clk);
    valid_in = 0;
    repeat (30) @(posedge clk);   // wait for pipeline to empty

    $display("Total valid outputs: %0d", valid_cnt);
    if (valid_cnt == (HEIGHT - FILTER_SIZE + 1) * (WIDTH - FILTER_SIZE + 1))
      $display("Valid count OK");
    else
      $display("ERROR: Expected %0d valid outputs",
               (HEIGHT - FILTER_SIZE + 1) * (WIDTH - FILTER_SIZE + 1));

    if (error_cnt == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED with %0d errors", error_cnt);

    $finish;
  end

  // -----------------------------------------------------------------
  // Check outputs when valid_out_conv is high
  // -----------------------------------------------------------------
  always @(posedge clk) begin
    if (rst_n && valid_out_conv) begin
      integer w, h;
      reg [7:0] window [0:24];   // pixels in current window

      valid_cnt = valid_cnt + 1;

      // Determine window position (top-left row and column)
      // First valid output appears after the buffer is full and pipeline settled.
      // The first window is at row=0, col=0. It occurs when pixel_cnt has reached:
      //   pixels to fill buffer: WIDTH * FILTER_SIZE = 140
      //   plus 1 to start streaming? Actually first window is output when the
      //   pixel at row=4, col=4 (index 4*28+4=116) is written? Need to derive.
      // A simpler approach: after the first 140 pixels, the line buffer is full,
      // and subsequent pixels produce windows. So window 0 corresponds to pixel_cnt = 141?
      // We'll compute using the known pattern: the window's top-left pixel (h,w) is
      // the pixel at (h,w) that was sent earlier. We can reconstruct from stored image.
      // We'll use a counter that increments each time we get a valid output.
      // The first valid output (valid_cnt=1) should be the window at (0,0).
      // We'll compute expected window from stored image.

      // For a given valid_cnt (starting at 1), the window (h,w) is:
      //   h = (valid_cnt-1) / (WIDTH - FILTER_SIZE + 1)
      //   w = (valid_cnt-1) % (WIDTH - FILTER_SIZE + 1)
      // Because there are (WIDTH-5+1)=24 columns per row of windows.

      h = (valid_cnt - 1) / (WIDTH - FILTER_SIZE + 1);
      w = (valid_cnt - 1) % (WIDTH - FILTER_SIZE + 1);

      // Extract window from stored image (row‑major order)
      for (int i = 0; i < FILTER_SIZE; i = i + 1) begin
        for (int j = 0; j < FILTER_SIZE; j = j + 1) begin
          window[i * FILTER_SIZE + j] = image[h + i][w + j];
        end
      end

      // Compute expected outputs
      exp_acc1 = compute_conv(window, ref_weight_1);
      exp_acc2 = compute_conv(window, ref_weight_2);
      exp_acc3 = compute_conv(window, ref_weight_3);

      // Compare with DUT outputs (after truncation and bias)
      if (conv_out_1 !== (exp_acc1[19:8] + ext_bias(ref_bias[0]))) begin
        $display("ERROR at window %0d (h=%0d, w=%0d): conv_out_1 = %d, expected %d",
                 valid_cnt, h, w, conv_out_1, (exp_acc1[19:8] + ext_bias(ref_bias[0])));
        error_cnt = error_cnt + 1;
      end
      if (conv_out_2 !== (exp_acc2[19:8] + ext_bias(ref_bias[1]))) begin
        $display("ERROR at window %0d (h=%0d, w=%0d): conv_out_2 = %d, expected %d",
                 valid_cnt, h, w, conv_out_2, (exp_acc2[19:8] + ext_bias(ref_bias[1])));
        error_cnt = error_cnt + 1;
      end
      if (conv_out_3 !== (exp_acc3[19:8] + ext_bias(ref_bias[2]))) begin
        $display("ERROR at window %0d (h=%0d, w=%0d): conv_out_3 = %d, expected %d",
                 valid_cnt, h, w, conv_out_3, (exp_acc3[19:8] + ext_bias(ref_bias[2])));
        error_cnt = error_cnt + 1;
      end
    end
  end

endmodule