`timescale 1ns/1ps

module tb_top();

parameter FLUSH_CYCLES = 30;   // enough to flush the last row of conv1 (24 columns)

reg                clk;
reg                rst_n;

reg [7 : 0]        pixels   [0 : 783];
reg [9 : 0]        img_idx;
reg [7 : 0]        data_in;

wire               valid_in;

wire signed [11:0] conv_out_1;
wire signed [11:0] conv_out_2; 
wire signed [11:0] conv_out_3;

wire signed [11:0] conv2_out_1; 
wire signed [11:0] conv2_out_2; 
wire signed [11:0] conv2_out_3;

wire signed [11:0] max_value_1; 
wire signed [11:0] max_value_2; 
wire signed [11:0] max_value_3;

wire signed [11:0] max2_value_1; 
wire signed [11:0] max2_value_2; 
wire signed [11:0] max2_value_3;

wire signed [11:0] fc_out_data;
wire        [3:0]  decision;

wire               valid_out_1; 
wire               valid_out_2; 
wire               valid_out_3; 
wire               valid_out_4; 
wire               valid_out_5; 
wire               valid_out_6;

// ------------------------------------------------------------------
// DUT instantiations
// ------------------------------------------------------------------
conv1_layer conv1_layer(
  .clk             (clk),
  .rst_n           (rst_n),
  .valid_in        (valid_in),
  .data_in         (data_in),
  .conv_out_1      (conv_out_1),
  .conv_out_2      (conv_out_2),
  .conv_out_3      (conv_out_3),
  .valid_out_conv  (valid_out_1)
);

maxpool_relu # (
  .CONV_BIT        (12), 
  .HALF_WIDTH      (12), 
  .HALF_HEIGHT     (12), 
  .HALF_WIDTH_BIT  (4)
) maxpool_relu_1 (
  .clk             (clk),
  .rst_n           (rst_n),
  .valid_in        (valid_out_1),
  .conv_out_1      (conv_out_1),
  .conv_out_2      (conv_out_2),
  .conv_out_3      (conv_out_3),
  .max_value_1     (max_value_1),
  .max_value_2     (max_value_2),
  .max_value_3     (max_value_3),
  .valid_out_relu  (valid_out_2)
);

conv2_layer conv2_layer (
  .clk             (clk),
  .rst_n           (rst_n),
  .valid_in        (valid_out_2),
  .max_value_1     (max_value_1),
  .max_value_2     (max_value_2),
  .max_value_3     (max_value_3),
  .conv2_out_1     (conv2_out_1),
  .conv2_out_2     (conv2_out_2),
  .conv2_out_3     (conv2_out_3),
  .valid_out_conv2 (valid_out_3)
);

maxpool_relu # (
  .CONV_BIT        (12), 
  .HALF_WIDTH      (4), 
  .HALF_HEIGHT     (4), 
  .HALF_WIDTH_BIT  (3)
) maxpool_relu_2 (
  .clk             (clk),
  .rst_n           (rst_n),
  .valid_in        (valid_out_3),
  .conv_out_1      (conv2_out_1),
  .conv_out_2      (conv2_out_2),
  .conv_out_3      (conv2_out_3),
  .max_value_1     (max2_value_1),
  .max_value_2     (max2_value_2),
  .max_value_3     (max2_value_3),
  .valid_out_relu  (valid_out_4)
);

fully_connected # (
  .INPUT_NUM       (48), 
  .OUTPUT_NUM      (10), 
  .DATA_BITS       (8)
) fully_connected (
  .clk             (clk),
  .rst_n           (rst_n),
  .valid_in        (valid_out_4),
  .data_in_1       (max2_value_1),
  .data_in_2       (max2_value_2),
  .data_in_3       (max2_value_3),
  .data_out        (fc_out_data),
  .valid_out_fc    (valid_out_5)
);

comparator comparator(
  .clk             (clk),
  .rst_n           (rst_n),
  .valid_in        (valid_out_5),
  .data_in         (fc_out_data),
  .decision        (decision),
  .valid_out       (valid_out_6)
);

// ------------------------------------------------------------------
// Clock generation
// ------------------------------------------------------------------
always #5 clk = ~clk;

// ------------------------------------------------------------------
// Test stimulus
// ------------------------------------------------------------------
initial begin
  $readmemh("3_0.txt", pixels);

  clk   = 0;
  rst_n = 0;
  #50;            // extend reset to 50 ns (5 cycles)
  rst_n = 1;

  // Timeout increased to 1 ms (1,000,000 ns) - more than enough
  #1000000;
  $display("ERROR: Timeout reached - final decision not received.");
  $finish;
end

// ------------------------------------------------------------------
// INPUT STREAM DRIVER WITH FLUSH CYCLES
// ------------------------------------------------------------------
always @(posedge clk) begin
  if (!rst_n) begin
    img_idx <= 0;
    data_in <= 0;
  end else begin
    // Send 784 pixels, then keep valid_in high for FLUSH_CYCLES more cycles
    if (img_idx < 784) begin
      data_in <= pixels[img_idx];
      img_idx <= img_idx + 1;
    end else if (img_idx < 784 + FLUSH_CYCLES) begin
      // After all pixels, send zeros to flush pipeline
      data_in <= 0;
      img_idx <= img_idx + 1;
    end
    // After flush, img_idx stays at 784+FLUSH_CYCLES, valid_in goes low
  end
end

assign valid_in = (img_idx < 784 + FLUSH_CYCLES);

// ------------------------------------------------------------------
// Debug prints
// ------------------------------------------------------------------
integer cnt_v1 = 0, cnt_v2 = 0, cnt_v3 = 0, cnt_v4 = 0, cnt_v5 = 0, cnt_v6 = 0;

always @(posedge clk) begin
  if (valid_out_1) begin
    cnt_v1 = cnt_v1 + 1;
    $display("DEBUG: conv1 valid (count=%0d)", cnt_v1);
  end
  if (valid_out_2) begin
    cnt_v2 = cnt_v2 + 1;
    $display("DEBUG: maxpool1 valid (count=%0d)", cnt_v2);
  end
  if (valid_out_3) begin
    cnt_v3 = cnt_v3 + 1;
    $display("DEBUG: conv2 valid (count=%0d)", cnt_v3);
  end
  if (valid_out_4) begin
    cnt_v4 = cnt_v4 + 1;
    $display("DEBUG: maxpool2 valid (count=%0d)", cnt_v4);
  end
  if (valid_out_5) begin
    cnt_v5 = cnt_v5 + 1;
    $display("DEBUG: FC valid (count=%0d)", cnt_v5);
  end
  if (valid_out_6) begin
    cnt_v6 = cnt_v6 + 1;
    $display("INFO: Final decision = %0d (count=%0d) at time %0t", decision, cnt_v6, $time);
    $finish;
  end
end

always @(posedge clk) begin
  if (valid_in && (img_idx % 100 == 0))
    $display("INFO: Sent pixel %0d", img_idx);
end

// Uncomment the line below for detailed tracing (may slow simulation)
// always @(posedge clk) $strobe("TRACE: idx=%0d valid_in=%0b time=%0t", img_idx, valid_in, $time);

endmodule