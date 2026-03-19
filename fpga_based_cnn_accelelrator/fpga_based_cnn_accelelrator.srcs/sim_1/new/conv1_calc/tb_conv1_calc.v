/*------------------------------------------------------------------------
 *  Testbench for conv1_calc
 *------------------------------------------------------------------------*/

module tb_conv1_calc;

  // Parameters
  localparam integer WIDTH      = 28;          // not used, kept for consistency
  localparam integer HEIGHT     = 28;
  localparam integer DATA_BITS  = 8;
  localparam integer FILTER_SIZE = 5;
  localparam integer CHANNEL_LEN = 3;
  localparam integer PIPELINE_DEPTH = 4;       // number of pipeline stages

  // Clock and reset
  reg clk;
  reg rst_n;

  // DUT inputs
  reg valid_out_buf;
  reg [DATA_BITS-1:0] data_in [0:24];          // 25 inputs as an array
  // DUT expects individual wires; we will assign them from the array
  wire [DATA_BITS-1:0] data_out_0,  data_out_1,  data_out_2,  data_out_3,  data_out_4,
                       data_out_5,  data_out_6,  data_out_7,  data_out_8,  data_out_9,
                       data_out_10, data_out_11, data_out_12, data_out_13, data_out_14,
                       data_out_15, data_out_16, data_out_17, data_out_18, data_out_19,
                       data_out_20, data_out_21, data_out_22, data_out_23, data_out_24;

  // DUT outputs
  wire signed [11:0] conv_out_1, conv_out_2, conv_out_3;
  wire               valid_out_calc;

  // Instantiate DUT
  conv1_calc #(
    .WIDTH    (WIDTH),
    .HEIGHT   (HEIGHT),
    .DATA_BITS(DATA_BITS)
  ) dut (
    .clk            (clk),
    .rst_n          (rst_n),
    .valid_out_buf  (valid_out_buf),
    .data_out_0     (data_out_0),
    .data_out_1     (data_out_1),
    .data_out_2     (data_out_2),
    .data_out_3     (data_out_3),
    .data_out_4     (data_out_4),
    .data_out_5     (data_out_5),
    .data_out_6     (data_out_6),
    .data_out_7     (data_out_7),
    .data_out_8     (data_out_8),
    .data_out_9     (data_out_9),
    .data_out_10    (data_out_10),
    .data_out_11    (data_out_11),
    .data_out_12    (data_out_12),
    .data_out_13    (data_out_13),
    .data_out_14    (data_out_14),
    .data_out_15    (data_out_15),
    .data_out_16    (data_out_16),
    .data_out_17    (data_out_17),
    .data_out_18    (data_out_18),
    .data_out_19    (data_out_19),
    .data_out_20    (data_out_20),
    .data_out_21    (data_out_21),
    .data_out_22    (data_out_22),
    .data_out_23    (data_out_23),
    .data_out_24    (data_out_24),
    .conv_out_1     (conv_out_1),
    .conv_out_2     (conv_out_2),
    .conv_out_3     (conv_out_3),
    .valid_out_calc (valid_out_calc)
  );

  // Connect the array to the individual wires
  assign data_out_0  = data_in[0];
  assign data_out_1  = data_in[1];
  assign data_out_2  = data_in[2];
  assign data_out_3  = data_in[3];
  assign data_out_4  = data_in[4];
  assign data_out_5  = data_in[5];
  assign data_out_6  = data_in[6];
  assign data_out_7  = data_in[7];
  assign data_out_8  = data_in[8];
  assign data_out_9  = data_in[9];
  assign data_out_10 = data_in[10];
  assign data_out_11 = data_in[11];
  assign data_out_12 = data_in[12];
  assign data_out_13 = data_in[13];
  assign data_out_14 = data_in[14];
  assign data_out_15 = data_in[15];
  assign data_out_16 = data_in[16];
  assign data_out_17 = data_in[17];
  assign data_out_18 = data_in[18];
  assign data_out_19 = data_in[19];
  assign data_out_20 = data_in[20];
  assign data_out_21 = data_in[21];
  assign data_out_22 = data_in[22];
  assign data_out_23 = data_in[23];
  assign data_out_24 = data_in[24];

  // -----------------------------------------------------------------
  // Reference model: same weights and bias as the DUT
  // -----------------------------------------------------------------
  reg signed [DATA_BITS-1:0] ref_weight_1 [0:FILTER_SIZE*FILTER_SIZE-1];
  reg signed [DATA_BITS-1:0] ref_weight_2 [0:FILTER_SIZE*FILTER_SIZE-1];
  reg signed [DATA_BITS-1:0] ref_weight_3 [0:FILTER_SIZE*FILTER_SIZE-1];
  reg signed [DATA_BITS-1:0] ref_bias     [0:CHANNEL_LEN-1];

  // Load the same files as the DUT
  initial begin
    $readmemh("conv1_weight_1.mem", ref_weight_1);
    $readmemh("conv1_weight_2.mem", ref_weight_2);
    $readmemh("conv1_weight_3.mem", ref_weight_3);
    $readmemh("conv1_bias.mem",     ref_bias);
  end

  // -----------------------------------------------------------------
  // Clock generation
  // -----------------------------------------------------------------
  always #5 clk = ~clk;

  // -----------------------------------------------------------------
  // Test stimulus and checking
  // -----------------------------------------------------------------
  integer i, j;
  integer error_cnt;
  integer vec_cnt;          // number of test vectors applied
  integer expected_1, expected_2, expected_3;

  // Arrays to hold delayed expected values (to align with pipeline)
  reg signed [19:0] expected_pipe_1 [0:PIPELINE_DEPTH-1];
  reg signed [19:0] expected_pipe_2 [0:PIPELINE_DEPTH-1];
  reg signed [19:0] expected_pipe_3 [0:PIPELINE_DEPTH-1];
  reg               valid_pipe      [0:PIPELINE_DEPTH-1];

  // Function to compute expected output (20‑bit accumulator)
  function automatic signed [19:0] compute_conv;
    input [DATA_BITS-1:0] pixels [0:24];
    input signed [DATA_BITS-1:0] weights [0:24];
    integer k;
    reg signed [19:0] sum;
    begin
      sum = 0;
      for (k = 0; k < 25; k = k + 1) begin
        // Convert pixel to signed (same as DUT: {1'd0, pixel})
        sum = sum + ({{12{1'b0}}, weights[k]} * {{12{1'b0}}, pixels[k]});
        // Note: We use {{12{1'b0}} to extend to 20 bits for multiplication.
        // Simulator will handle the width automatically, but explicit casting avoids warnings.
      end
      compute_conv = sum;
    end
  endfunction

  // Function to sign‑extend bias (same as DUT)
  function automatic signed [11:0] ext_bias;
    input signed [7:0] b;
    begin
      ext_bias = (b[7] == 1) ? {4'b1111, b} : {4'b0000, b};
    end
  endfunction

  initial begin
    // Initialize
    clk = 0;
    rst_n = 0;
    valid_out_buf = 0;
    for (i = 0; i < 25; i = i + 1) data_in[i] = 0;
    error_cnt = 0;
    vec_cnt = 0;

    // Initialize pipeline delay lines
    for (i = 0; i < PIPELINE_DEPTH; i = i + 1) begin
      expected_pipe_1[i] = 0;
      expected_pipe_2[i] = 0;
      expected_pipe_3[i] = 0;
      valid_pipe[i]      = 0;
    end

    // Dump waveforms
    $dumpfile("tb_conv1_calc.vcd");
    $dumpvars(0, tb_conv1_calc);

    // Apply reset
    #20 rst_n = 1;
    #10;

    // -----------------------------------------------------------------
    // Test case 1: all pixels = 0
    // -----------------------------------------------------------------
    @(posedge clk);
    valid_out_buf = 1;
    for (i = 0; i < 25; i = i + 1) data_in[i] = 0;
    vec_cnt = vec_cnt + 1;
    @(posedge clk);
    valid_out_buf = 0;   // single pulse

    // -----------------------------------------------------------------
    // Test case 2: pixels = 0..24
    // -----------------------------------------------------------------
    repeat (5) @(posedge clk);   // wait a few cycles
    @(posedge clk);
    valid_out_buf = 1;
    for (i = 0; i < 25; i = i + 1) data_in[i] = i;
    vec_cnt = vec_cnt + 1;
    @(posedge clk);
    valid_out_buf = 0;

    // -----------------------------------------------------------------
    // Test case 3: random pattern
    // -----------------------------------------------------------------
    repeat (5) @(posedge clk);
    @(posedge clk);
    valid_out_buf = 1;
    data_in[0]  = 10;  data_in[1]  = 20;  data_in[2]  = 30;  data_in[3]  = 40;  data_in[4]  = 50;
    data_in[5]  = 60;  data_in[6]  = 70;  data_in[7]  = 80;  data_in[8]  = 90;  data_in[9]  = 100;
    data_in[10] = 110; data_in[11] = 120; data_in[12] = 130; data_in[13] = 140; data_in[14] = 150;
    data_in[15] = 160; data_in[16] = 170; data_in[17] = 180; data_in[18] = 190; data_in[19] = 200;
    data_in[20] = 210; data_in[21] = 220; data_in[22] = 230; data_in[23] = 240; data_in[24] = 250;
    vec_cnt = vec_cnt + 1;
    @(posedge clk);
    valid_out_buf = 0;

    // Let the pipeline drain
    repeat (10) @(posedge clk);

    // Report summary
    $display("Test completed. %0d vectors applied, %0d errors detected.", vec_cnt, error_cnt);
    if (error_cnt == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");

    $finish;
  end

  // -----------------------------------------------------------------
  // Expected value calculation and comparison
  // This always block runs at each posedge clk, computes the expected
  // value for the current input, pushes it into a pipeline, and
  // compares the output of the DUT with the oldest expected value.
  // -----------------------------------------------------------------
  always @(posedge clk) begin
    integer k;
    reg signed [19:0] acc1, acc2, acc3;
    reg signed [11:0] exp1, exp2, exp3;

    if (rst_n) begin
      // If valid_out_buf is high, compute expected accumulator values
      if (valid_out_buf) begin
        acc1 = compute_conv(data_in, ref_weight_1);
        acc2 = compute_conv(data_in, ref_weight_2);
        acc3 = compute_conv(data_in, ref_weight_3);
      end else begin
        acc1 = 0;
        acc2 = 0;
        acc3 = 0;
      end

      // Shift the pipeline
      for (k = PIPELINE_DEPTH-1; k > 0; k = k - 1) begin
        expected_pipe_1[k] <= expected_pipe_1[k-1];
        expected_pipe_2[k] <= expected_pipe_2[k-1];
        expected_pipe_3[k] <= expected_pipe_3[k-1];
        valid_pipe[k]      <= valid_pipe[k-1];
      end
      // Insert new value at stage 0
      expected_pipe_1[0] <= acc1;
      expected_pipe_2[0] <= acc2;
      expected_pipe_3[0] <= acc3;
      valid_pipe[0]      <= valid_out_buf;
    end else begin
      // Reset: clear pipeline
      for (k = 0; k < PIPELINE_DEPTH; k = k + 1) begin
        expected_pipe_1[k] <= 0;
        expected_pipe_2[k] <= 0;
        expected_pipe_3[k] <= 0;
        valid_pipe[k]      <= 0;
      end
    end
  end

  // Compare outputs when valid_out_calc is high
  always @(posedge clk) begin
    if (rst_n && valid_out_calc) begin
      // Expected values after truncation and bias addition
      expected_1 = expected_pipe_1[PIPELINE_DEPTH-1][19:8] + ext_bias(ref_bias[0]);
      expected_2 = expected_pipe_2[PIPELINE_DEPTH-1][19:8] + ext_bias(ref_bias[1]);
      expected_3 = expected_pipe_3[PIPELINE_DEPTH-1][19:8] + ext_bias(ref_bias[2]);

      if (conv_out_1 !== expected_1) begin
        $display("ERROR at time %t: conv_out_1 = %d, expected %d", $time, conv_out_1, expected_1);
        error_cnt = error_cnt + 1;
      end
      if (conv_out_2 !== expected_2) begin
        $display("ERROR at time %t: conv_out_2 = %d, expected %d", $time, conv_out_2, expected_2);
        error_cnt = error_cnt + 1;
      end
      if (conv_out_3 !== expected_3) begin
        $display("ERROR at time %t: conv_out_3 = %d, expected %d", $time, conv_out_3, expected_3);
        error_cnt = error_cnt + 1;
      end
    end
  end

endmodule