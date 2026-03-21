`timescale 1ns/1ps

module tb_fully_connected ();

  // Parameters
  localparam INPUT_NUM  = 48;
  localparam OUTPUT_NUM = 10;
  localparam DATA_BITS  = 8;

  reg                clk;
  reg                rst_n;
  reg                valid_in;

  reg  signed [11:0] data_in_1;
  reg  signed [11:0] data_in_2;
  reg  signed [11:0] data_in_3;

  wire        [11:0] data_out;
  wire               valid_out_fc;

  // Instantiate DUT
  fully_connected dut (
    .clk          (clk),
    .rst_n        (rst_n),
    
    .valid_in     (valid_in),
    
    .data_in_1    (data_in_1),
    .data_in_2    (data_in_2),
    .data_in_3    (data_in_3),
    
    .data_out     (data_out),
    
    .valid_out_fc (valid_out_fc)
  );

  always #5 clk = ~clk;

  reg signed [13 : 0]        input_buffer [0 : INPUT_NUM - 1];
  reg signed [DATA_BITS-1:0] weight       [0 : INPUT_NUM * OUTPUT_NUM - 1];
  reg signed [DATA_BITS-1:0] bias         [0 : OUTPUT_NUM - 1];
  
  reg signed [11  :0]        expected     [0 : OUTPUT_NUM - 1];

  integer i;
  integer j;

  integer out_cnt;  

  function signed [13:0] ext12to14(input signed [11:0] val);
    ext12to14 = val[11] ? {2'b11, val} : {2'b00, val};
  endfunction

  function signed [19:0] fc_compute(input integer out_idx);
    reg signed [31:0] sum;
    integer k;
    begin
      sum = bias[out_idx];
      for (k = 0; k < INPUT_NUM; k = k + 1) begin
        sum = sum + input_buffer[k] * weight[out_idx*INPUT_NUM + k];
      end
      fc_compute = sum[19:0];   // truncate to 20 bits
    end
  endfunction

  // Main test procedure
  initial begin
    // Initial values
    clk = 0;
    rst_n = 0;
    valid_in = 0;
    data_in_1 = 0;
    data_in_2 = 0;
    data_in_3 = 0;
    out_cnt = 0;

    // Load weights and biases from the same memory files as DUT
    $readmemh("fc_weight.mem", weight);
    $readmemh("fc_bias.mem", bias);

    // Apply reset
    #20;
    rst_n = 1;
    @(posedge clk);
    #1;

    $display("=== Test started ===");

    // --------------------------------------------------------------
    // 1. Fill the input buffer (16 cycles, each with 3 inputs)
    // --------------------------------------------------------------
    valid_in = 1;
    for (i = 0; i < 16; i = i + 1) begin
      // Generate random 12-bit signed numbers
      data_in_1 = $random;
      data_in_2 = $random;
      data_in_3 = $random;

      // Store the sign-extended values in the golden buffer
      input_buffer[i]      = ext12to14(data_in_1);
      input_buffer[i+16]   = ext12to14(data_in_2);
      input_buffer[i+32]   = ext12to14(data_in_3);

      @(posedge clk);
    end
    valid_in = 0;      // stop data input after buffer is full

    // --------------------------------------------------------------
    // 2. Compute expected outputs for all neurons
    // --------------------------------------------------------------
    begin
      reg signed [19:0] full;
      for (j = 0; j < OUTPUT_NUM; j = j + 1) begin
        full = fc_compute(j);
        expected[j] = full[18:7];   // DUT outputs bits 18:7
      end
    end

    // --------------------------------------------------------------
    // 3. Send valid_in pulses to trigger the computation of 10 outputs
    // --------------------------------------------------------------
    for (j = 0; j < OUTPUT_NUM; j = j + 1) begin
      @(posedge clk);
      valid_in = 1;      // one pulse per output
      // The data inputs are don't-care during computation phase
      data_in_1 = 0;
      data_in_2 = 0;
      data_in_3 = 0;
      @(posedge clk);
      valid_in = 0;
    end

    // Wait for all outputs to be received (pipeline depth 5 cycles)
    // The self-checking block will finish the simulation when out_cnt reaches OUTPUT_NUM.
    // Add a timeout to avoid hanging.
    #1000;
    $display("Timeout: not all outputs received.");
    $finish;
  end

  // --------------------------------------------------------------
  // Self-checking: compare each valid_out_fc with expected value
  // --------------------------------------------------------------
  always @(posedge clk) begin
    if (valid_out_fc) begin
      if (out_cnt >= OUTPUT_NUM) begin
        $display("ERROR: Received more than %0d outputs.", OUTPUT_NUM);
        $finish;
      end

      if (data_out !== expected[out_cnt]) begin
        $display("MISMATCH at time %0t: output %0d, got %0d, expected %0d",
                 $time, out_cnt, data_out, expected[out_cnt]);
      end else begin
        $display("MATCH at time %0t: output %0d, value %0d",
                 $time, out_cnt, data_out);
      end

      out_cnt = out_cnt + 1;
      if (out_cnt == OUTPUT_NUM) begin
        $display("=== All %0d outputs matched. Test PASSED ===", OUTPUT_NUM);
        $finish;
      end
    end
  end

endmodule