`timescale 1ns / 1ps

module axis_cnn_mnist(
  input               aclk,
  input               aresetn,

  output wire         s_axis_tready,
  input  wire [7 : 0] s_axis_tdata,
  input  wire         s_axis_tvalid,
  // input  wire         s_axis_tlast,

  input  wire         m_axis_tready,
  output wire [7 : 0] m_axis_tdata,
  output wire         m_axis_tvalid,
  output wire         m_axis_tlast
);

  reg         [7 : 0]  s_axis_tdata_reg;
  reg                  s_axis_tvalid_reg;

  reg         [10 : 0] cnt_sequencer_reg;

  wire signed [11 : 0] conv_out_1;
  wire signed [11 : 0] conv_out_2;
  wire signed [11 : 0] conv_out_3;

  wire signed [11 : 0] conv2_out_1;
  wire signed [11 : 0] conv2_out_2;
  wire signed [11 : 0] conv2_out_3;

  wire signed [11 : 0] max_value_1;
  wire signed [11 : 0] max_value_2;
  wire signed [11 : 0] max_value_3;

  wire signed [11 : 0] max2_value_1;
  wire signed [11 : 0] max2_value_2;
  wire signed [11 : 0] max2_value_3;

  wire signed [11 : 0] fc_out_data;

  wire                 valid_out_1;
  wire                 valid_out_2;
  wire                 valid_out_3;
  wire                 valid_out_4;
  wire                 valid_out_5;
  wire                 valid_out_6;

  wire        [3 : 0]  decision;

  wire                 s_axis_tvalid_tick;

  wire                 valid_in;
  wire                 clr;

  conv1_layer conv1_layer_01 (
    .clk             (aclk),
    .rst_n           (aresetn & clr),

    .valid_in        (valid_in),
    .data_in         (s_axis_tdata_reg),

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
  ) maxpool_relu_01 (
    .clk             (aclk),
    .rst_n           (aresetn & clr),

    .valid_in        (valid_out_1),

    .conv_out_1      (conv_out_1),
    .conv_out_2      (conv_out_2),
    .conv_out_3      (conv_out_3),

    .max_value_1     (max_value_1),
    .max_value_2     (max_value_2),
    .max_value_3     (max_value_3),

    .valid_out_relu  (valid_out_2)
  );

  conv2_layer conv2_layer_01 (
    .clk             (aclk),
    .rst_n           (aresetn & clr),

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
  ) maxpool_relu_02 (
    .clk             (aclk),
    .rst_n           (aresetn & clr),

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
  ) fully_connected_01 (
    .clk             (aclk),
    .rst_n           (aresetn & clr),

    .valid_in        (valid_out_4),

    .data_in_1       (max2_value_1),
    .data_in_2       (max2_value_2),
    .data_in_3       (max2_value_3),

    .data_out        (fc_out_data),
    
    .valid_out_fc    (valid_out_5)
  );

  comparator comparator_01 (
    .clk             (aclk),
    .rst_n           (aresetn & clr),

    .valid_in        (valid_out_5),
    .data_in         (fc_out_data),

    .decision        (decision),
    .valid_out       (valid_out_6)
  );

  // Pipelining the input
  always @ (posedge aclk) begin
    if (!aresetn) begin
      s_axis_tdata_reg <= 0;
    end else begin
      s_axis_tdata_reg <= s_axis_tdata;
    end
  end

  // Rising edge detector
  always @ (posedge aclk) begin
    if (!aresetn) begin
      s_axis_tvalid_reg <= 0;
    end else begin
      s_axis_tvalid_reg <= s_axis_tvalid;
    end
  end

  assign s_axis_tvalid_tick = s_axis_tvalid & ~s_axis_tvalid_reg;

  // Counter sequencer as a global FSM
  always @ (posedge aclk) begin
    if (!aresetn) begin
      cnt_sequencer_reg <= 0;
    end else if (s_axis_tvalid_tick) begin
      cnt_sequencer_reg <= cnt_sequencer_reg + 1;
    end else if (cnt_sequencer_reg >= 1 && cnt_sequencer_reg <= 1280) begin
      cnt_sequencer_reg <= cnt_sequencer_reg + 1;
    end else if (cnt_sequencer_reg >= 1281) begin
      cnt_sequencer_reg <= 0;
    end
  end

  assign s_axis_tready = !((cnt_sequencer_reg >= 784) && (cnt_sequencer_reg <= 1281));
  assign valid_in      = (cnt_sequencer_reg >= 1) && (cnt_sequencer_reg <= 841);
  assign m_axis_tdata  = {4'b0000, decision};
  assign m_axis_tvalid = (valid_out_6) && (cnt_sequencer_reg == 1279);
  assign m_axis_tlast  = (valid_out_6) && (cnt_sequencer_reg == 1279);
  assign clr           = (cnt_sequencer_reg != 1280);  

endmodule
