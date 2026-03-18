module conv2_layer (
	input  wire        clk,              
	input  wire        rst_n,             
	input  wire        valid_in,          
	
	input  wire [11:0] max_value_1,
	input  wire [11:0] max_value_2,
	input  wire [11:0] max_value_3,

	output wire [11:0] conv2_out_1,
	output wire [11:0] conv2_out_2,
	output wire [11:0] conv2_out_3,
	output wire        valid_out_conv2    
);

	localparam CHANNEL_LEN = 3;   

	wire [11:0] data_out1_0; 
	wire [11:0] data_out1_1; 
	wire [11:0] data_out1_2; 
	wire [11:0] data_out1_3; 
	wire [11:0] data_out1_4;
    wire [11:0] data_out1_5; 
	wire [11:0] data_out1_6; 
	wire [11:0] data_out1_7; 
	wire [11:0] data_out1_8; 
	wire [11:0] data_out1_9;
	wire [11:0] data_out1_10; 
	wire [11:0] data_out1_11; 
	wire [11:0] data_out1_12; 
	wire [11:0] data_out1_13; 
	wire [11:0] data_out1_14;
	wire [11:0] data_out1_15; 
	wire [11:0] data_out1_16; 
	wire [11:0] data_out1_17; 
	wire [11:0] data_out1_18; 
	wire [11:0] data_out1_19;
	wire [11:0] data_out1_20; 
	wire [11:0] data_out1_21; 
	wire [11:0] data_out1_22; 
	wire [11:0] data_out1_23; 
	wire [11:0] data_out1_24;

	// Valid signal from channel 1 buffer
	wire        valid_out1_buf;   

	wire [11:0] data_out2_0; 
	wire [11:0] data_out2_1; 
	wire [11:0] data_out2_2; 
	wire [11:0] data_out2_3; 
	wire [11:0] data_out2_4;
	wire [11:0] data_out2_5; 
	wire [11:0] data_out2_6; 
	wire [11:0] data_out2_7; 
	wire [11:0] data_out2_8; 
	wire [11:0] data_out2_9;
  wire [11:0] data_out2_10; 
	wire [11:0] data_out2_11; 
	wire [11:0] data_out2_12; 
	wire [11:0] data_out2_13; 
	wire [11:0] data_out2_14;
  wire [11:0] data_out2_15; 
	wire [11:0] data_out2_16; 
	wire [11:0] data_out2_17; 
	wire [11:0] data_out2_18; 
	wire [11:0] data_out2_19;
  wire [11:0] data_out2_20; 
	wire [11:0] data_out2_21; 
	wire [11:0] data_out2_22; 
	wire [11:0] data_out2_23; 
	wire [11:0] data_out2_24;

	// Valid signal from channel 2 buffer
	wire        valid_out2_buf;

	// Channel 3 buffer outputs
	wire [11:0] data_out3_0; 
	wire [11:0] data_out3_1; 
	wire [11:0] data_out3_2; 
	wire [11:0] data_out3_3; 
	wire [11:0] data_out3_4;
  wire [11:0] data_out3_5; 
	wire [11:0] data_out3_6; 
	wire [11:0] data_out3_7; 
	wire [11:0] data_out3_8; 
	wire [11:0] data_out3_9;
  wire [11:0] data_out3_10; 
	wire [11:0] data_out3_11; 
	wire [11:0] data_out3_12; 
	wire [11:0] data_out3_13; 
	wire [11:0] data_out3_14;
  wire [11:0] data_out3_15;
	wire [11:0] data_out3_16; 
	wire [11:0] data_out3_17; 
	wire [11:0] data_out3_18; 
	wire [11:0] data_out3_19;
	wire [11:0] data_out3_20; 
	wire [11:0] data_out3_21; 
	wire [11:0] data_out3_22; 
	wire [11:0] data_out3_23; 
	wire [11:0] data_out3_24;

	// Valid signal from channel 3 buffer
	wire        valid_out3_buf;

	// Internal wires from the three convolution calculators
	wire signed [13:0] conv_out_1;       
	wire signed [13:0] conv_out_2;       
	wire signed [13:0] conv_out_3;        

	// Combined valid signals
	wire               valid_out_buf;      
	wire               valid_out_calc_1;  
	wire               valid_out_calc_2;   
	wire               valid_out_calc_3; 

	// Bias storage and sign extension
	reg  signed [7:0]  bias     [0:CHANNEL_LEN-1];   
	wire signed [11:0] exp_bias [0:CHANNEL_LEN-1];  

	// Bias loading and extension
	initial
	begin
			$readmemh("conv2_bias.mem", bias);   // load 3 biases from file
	end

	// Sign‑extend 8‑bit bias to 12 bits
	assign exp_bias[0]     = (bias[0][7] == 1) ? {4'b1111, bias[0]} : {4'b0000, bias[0]};
	assign exp_bias[1]     = (bias[1][7] == 1) ? {4'b1111, bias[1]} : {4'b0000, bias[1]};
	assign exp_bias[2]     = (bias[2][7] == 1) ? {4'b1111, bias[2]} : {4'b0000, bias[2]};

	// Final output: truncate the 14‑bit accumulator to 12 bits (bits 13:1) and add the bias.
	assign conv2_out_1     = conv_out_1[13:1] + exp_bias[0];
	assign conv2_out_2     = conv_out_2[13:1] + exp_bias[1];
	assign conv2_out_3     = conv_out_3[13:1] + exp_bias[2];

	// Combined valid signals 
	assign valid_out_buf   = valid_out1_buf & valid_out2_buf & valid_out3_buf;

	// Combined convolutional output valid
	assign valid_out_conv2 = valid_out_calc_1 & valid_out_calc_2 & valid_out_calc_3;

	// Line buffer for input channel 1
	conv2_buf #(
	  .WIDTH          (12),
		.HEIGHT         (12),
		.DATA_BITS      (12),
		.FILTERSIZE     (5)
	) conv2_buf_1 (
		.clk            (clk),
		.rst_n          (rst_n),
		.valid_in       (valid_in),
		.data_in        (max_value_1), 

		.data_out_0     (data_out1_0),
		.data_out_1     (data_out1_1),
		.data_out_2     (data_out1_2),
		.data_out_3     (data_out1_3),
		.data_out_4     (data_out1_4),
		.data_out_5     (data_out1_5),
		.data_out_6     (data_out1_6),
		.data_out_7     (data_out1_7),
		.data_out_8     (data_out1_8),
		.data_out_9     (data_out1_9),
		.data_out_10    (data_out1_10),
		.data_out_11    (data_out1_11),
		.data_out_12    (data_out1_12),
		.data_out_13    (data_out1_13),
		.data_out_14    (data_out1_14),
		.data_out_15    (data_out1_15),
		.data_out_16    (data_out1_16),
		.data_out_17    (data_out1_17),
		.data_out_18    (data_out1_18),
		.data_out_19    (data_out1_19),
		.data_out_20    (data_out1_20),
		.data_out_21    (data_out1_21),
		.data_out_22    (data_out1_22),
		.data_out_23    (data_out1_23),
		.data_out_24    (data_out1_24),

		.valid_out_buf  (valid_out1_buf)
	);

	// Line buffer for input channel 2
	conv2_buf #(
	  .WIDTH          (12),
	  .HEIGHT         (12),
	  .DATA_BITS      (12),
		.FILTERSIZE     (5)
	) conv2_buf_2 (
		.clk            (clk),
		.rst_n          (rst_n),
		.valid_in       (valid_in),
		.data_in        (max_value_2),

		.data_out_0     (data_out2_0),
		.data_out_1     (data_out2_1),
		.data_out_2     (data_out2_2),
		.data_out_3     (data_out2_3),
		.data_out_4     (data_out2_4),
		.data_out_5     (data_out2_5),
		.data_out_6     (data_out2_6),
		.data_out_7     (data_out2_7),
		.data_out_8     (data_out2_8),
		.data_out_9     (data_out2_9),
		.data_out_10    (data_out2_10),
		.data_out_11    (data_out2_11),
		.data_out_12    (data_out2_12),
		.data_out_13    (data_out2_13),
		.data_out_14    (data_out2_14),
		.data_out_15    (data_out2_15),
		.data_out_16    (data_out2_16),
		.data_out_17    (data_out2_17),
		.data_out_18    (data_out2_18),
		.data_out_19    (data_out2_19),
		.data_out_20    (data_out2_20),
		.data_out_21    (data_out2_21),
		.data_out_22    (data_out2_22),
		.data_out_23    (data_out2_23),
		.data_out_24    (data_out2_24),

		.valid_out_buf  (valid_out2_buf)
	);

	// Line buffer for input channel 3
	conv2_buf #(
		.WIDTH          (12),
		.HEIGHT         (12),
		.DATA_BITS      (12),
		.FILTERSIZE     (5)
	) conv2_buf_3 (
		.clk            (clk),
		.rst_n          (rst_n),
		.valid_in       (valid_in),
		.data_in        (max_value_3),

		.data_out_0     (data_out3_0),
		.data_out_1     (data_out3_1),
		.data_out_2     (data_out3_2),
		.data_out_3     (data_out3_3),
		.data_out_4     (data_out3_4),
		.data_out_5     (data_out3_5),
		.data_out_6     (data_out3_6),
		.data_out_7     (data_out3_7),
		.data_out_8     (data_out3_8),
		.data_out_9     (data_out3_9),
		.data_out_10    (data_out3_10),
		.data_out_11    (data_out3_11),
		.data_out_12    (data_out3_12),
		.data_out_13    (data_out3_13),
		.data_out_14    (data_out3_14),
		.data_out_15    (data_out3_15),
		.data_out_16    (data_out3_16),
		.data_out_17    (data_out3_17),
		.data_out_18    (data_out3_18),
		.data_out_19    (data_out3_19),
		.data_out_20    (data_out3_20),
		.data_out_21    (data_out3_21),
		.data_out_22    (data_out3_22),
		.data_out_23    (data_out3_23),
		.data_out_24    (data_out3_24),

		.valid_out_buf  (valid_out3_buf)
	);

	// Convolution calculator for output channel 1

	conv2_calc #(
		.WIDTH          (28),
		.HEIGHT         (28),
		.DATA_BITS      (12),

		.WEIGHT_1       ("conv2_weight_11.mem"),
		.WEIGHT_2       ("conv2_weight_12.mem"),
		.WEIGHT_3       ("conv2_weight_13.mem")
	) conv2_calc_1 (
		.clk            (clk),
		.rst_n          (rst_n),

		.valid_out_buf  (valid_out_buf),          

		.data_out1_0    (data_out1_0),
		.data_out1_1    (data_out1_1),
		.data_out1_2    (data_out1_2),
		.data_out1_3    (data_out1_3),
		.data_out1_4    (data_out1_4),
		.data_out1_5    (data_out1_5),
		.data_out1_6    (data_out1_6),
		.data_out1_7    (data_out1_7),
		.data_out1_8    (data_out1_8),
		.data_out1_9    (data_out1_9),
		.data_out1_10   (data_out1_10),
		.data_out1_11   (data_out1_11),
		.data_out1_12   (data_out1_12),
		.data_out1_13   (data_out1_13),
		.data_out1_14   (data_out1_14),
		.data_out1_15   (data_out1_15),
		.data_out1_16   (data_out1_16),
		.data_out1_17   (data_out1_17),
		.data_out1_18   (data_out1_18),
		.data_out1_19   (data_out1_19),
		.data_out1_20   (data_out1_20),
		.data_out1_21   (data_out1_21),
		.data_out1_22   (data_out1_22),
		.data_out1_23   (data_out1_23),
		.data_out1_24   (data_out1_24),

		.data_out2_0    (data_out2_0),
		.data_out2_1    (data_out2_1),
		.data_out2_2    (data_out2_2),
		.data_out2_3    (data_out2_3),
		.data_out2_4    (data_out2_4),
		.data_out2_5    (data_out2_5),
		.data_out2_6    (data_out2_6),
		.data_out2_7    (data_out2_7),
		.data_out2_8    (data_out2_8),
		.data_out2_9    (data_out2_9),
		.data_out2_10   (data_out2_10),
		.data_out2_11   (data_out2_11),
		.data_out2_12   (data_out2_12),
		.data_out2_13   (data_out2_13),
		.data_out2_14   (data_out2_14),
		.data_out2_15   (data_out2_15),
		.data_out2_16   (data_out2_16),
		.data_out2_17   (data_out2_17),
		.data_out2_18   (data_out2_18),
		.data_out2_19   (data_out2_19),
		.data_out2_20   (data_out2_20),
		.data_out2_21   (data_out2_21),
		.data_out2_22   (data_out2_22),
		.data_out2_23   (data_out2_23),
		.data_out2_24   (data_out2_24),

		.data_out3_0    (data_out3_0),
		.data_out3_1    (data_out3_1),
		.data_out3_2    (data_out3_2),
		.data_out3_3    (data_out3_3),
		.data_out3_4    (data_out3_4),
		.data_out3_5    (data_out3_5),
		.data_out3_6    (data_out3_6),
		.data_out3_7    (data_out3_7),
		.data_out3_8    (data_out3_8),
		.data_out3_9    (data_out3_9),
		.data_out3_10   (data_out3_10),
		.data_out3_11   (data_out3_11),
		.data_out3_12   (data_out3_12),
		.data_out3_13   (data_out3_13),
		.data_out3_14   (data_out3_14),
		.data_out3_15   (data_out3_15),
		.data_out3_16   (data_out3_16),
		.data_out3_17   (data_out3_17),
		.data_out3_18   (data_out3_18),
		.data_out3_19   (data_out3_19),
		.data_out3_20   (data_out3_20),
		.data_out3_21   (data_out3_21),
		.data_out3_22   (data_out3_22),
		.data_out3_23   (data_out3_23),
		.data_out3_24   (data_out3_24),

		.conv_out_calc  (conv_out_1),    

		.valid_out_calc (valid_out_calc_1)
	);

	// Convolution calculator for output channel 2

	conv2_calc #(
		.WIDTH          (28),
		.HEIGHT         (28),
		.DATA_BITS      (12),
		
		.WEIGHT_1       ("conv2_weight_21.mem"),
		.WEIGHT_2       ("conv2_weight_22.mem"),
		.WEIGHT_3       ("conv2_weight_23.mem")
	) conv2_calc_2 (
		.clk            (clk),
		.rst_n          (rst_n),

		.valid_out_buf  (valid_out_buf),

		.data_out1_0    (data_out1_0),
		.data_out1_1    (data_out1_1),
		.data_out1_2    (data_out1_2),
		.data_out1_3    (data_out1_3),
		.data_out1_4    (data_out1_4),
		.data_out1_5    (data_out1_5),
		.data_out1_6    (data_out1_6),
		.data_out1_7    (data_out1_7),
		.data_out1_8    (data_out1_8),
		.data_out1_9    (data_out1_9),
		.data_out1_10   (data_out1_10),
		.data_out1_11   (data_out1_11),
		.data_out1_12   (data_out1_12),
		.data_out1_13   (data_out1_13),
		.data_out1_14   (data_out1_14),
		.data_out1_15   (data_out1_15),
		.data_out1_16   (data_out1_16),
		.data_out1_17   (data_out1_17),
		.data_out1_18   (data_out1_18),
		.data_out1_19   (data_out1_19),
		.data_out1_20   (data_out1_20),
		.data_out1_21   (data_out1_21),
		.data_out1_22   (data_out1_22),
		.data_out1_23   (data_out1_23),
		.data_out1_24   (data_out1_24),

		.data_out2_0    (data_out2_0),
		.data_out2_1    (data_out2_1),
		.data_out2_2    (data_out2_2),
		.data_out2_3    (data_out2_3),
		.data_out2_4    (data_out2_4),
		.data_out2_5    (data_out2_5),
		.data_out2_6    (data_out2_6),
		.data_out2_7    (data_out2_7),
		.data_out2_8    (data_out2_8),
		.data_out2_9    (data_out2_9),
		.data_out2_10   (data_out2_10),
		.data_out2_11   (data_out2_11),
		.data_out2_12   (data_out2_12),
		.data_out2_13   (data_out2_13),
		.data_out2_14   (data_out2_14),
		.data_out2_15   (data_out2_15),
		.data_out2_16   (data_out2_16),
		.data_out2_17   (data_out2_17),
		.data_out2_18   (data_out2_18),
		.data_out2_19   (data_out2_19),
		.data_out2_20   (data_out2_20),
		.data_out2_21   (data_out2_21),
		.data_out2_22   (data_out2_22),
		.data_out2_23   (data_out2_23),
		.data_out2_24   (data_out2_24),

		.data_out3_0    (data_out3_0),
		.data_out3_1    (data_out3_1),
		.data_out3_2    (data_out3_2),
		.data_out3_3    (data_out3_3),
		.data_out3_4    (data_out3_4),
		.data_out3_5    (data_out3_5),
		.data_out3_6    (data_out3_6),
		.data_out3_7    (data_out3_7),
		.data_out3_8    (data_out3_8),
		.data_out3_9    (data_out3_9),
		.data_out3_10   (data_out3_10),
		.data_out3_11   (data_out3_11),
		.data_out3_12   (data_out3_12),
		.data_out3_13   (data_out3_13),
		.data_out3_14   (data_out3_14),
		.data_out3_15   (data_out3_15),
		.data_out3_16   (data_out3_16),
		.data_out3_17   (data_out3_17),
		.data_out3_18   (data_out3_18),
		.data_out3_19   (data_out3_19),
		.data_out3_20   (data_out3_20),
		.data_out3_21   (data_out3_21),
		.data_out3_22   (data_out3_22),
		.data_out3_23   (data_out3_23),
		.data_out3_24   (data_out3_24),

		.conv_out_calc  (conv_out_2),

		.valid_out_calc (valid_out_calc_2)
	);

	// Convolution calculator for output channel 3

	conv2_calc #(
		.WIDTH          (28),
		.HEIGHT         (28),
		.DATA_BITS      (12),

		.WEIGHT_1       ("conv2_weight_31.mem"),
		.WEIGHT_2       ("conv2_weight_32.mem"),
		.WEIGHT_3       ("conv2_weight_33.mem")
	) conv2_calc_3 (
		.clk            (clk),
		.rst_n          (rst_n),

		.valid_out_buf  (valid_out_buf),

		.data_out1_0    (data_out1_0),
		.data_out1_1    (data_out1_1),
		.data_out1_2    (data_out1_2),
		.data_out1_3    (data_out1_3),
		.data_out1_4    (data_out1_4),
		.data_out1_5    (data_out1_5),
		.data_out1_6    (data_out1_6),
		.data_out1_7    (data_out1_7),
		.data_out1_8    (data_out1_8),
		.data_out1_9    (data_out1_9),
		.data_out1_10   (data_out1_10),
		.data_out1_11   (data_out1_11),
		.data_out1_12   (data_out1_12),
		.data_out1_13   (data_out1_13),
		.data_out1_14   (data_out1_14),
		.data_out1_15   (data_out1_15),
		.data_out1_16   (data_out1_16),
		.data_out1_17   (data_out1_17),
		.data_out1_18   (data_out1_18),
		.data_out1_19   (data_out1_19),
		.data_out1_20   (data_out1_20),
		.data_out1_21   (data_out1_21),
		.data_out1_22   (data_out1_22),
		.data_out1_23   (data_out1_23),
		.data_out1_24   (data_out1_24),

		.data_out2_0    (data_out2_0),
		.data_out2_1    (data_out2_1),
		.data_out2_2    (data_out2_2),
		.data_out2_3    (data_out2_3),
		.data_out2_4    (data_out2_4),
		.data_out2_5    (data_out2_5),
		.data_out2_6    (data_out2_6),
		.data_out2_7    (data_out2_7),
		.data_out2_8    (data_out2_8),
		.data_out2_9    (data_out2_9),
		.data_out2_10   (data_out2_10),
		.data_out2_11   (data_out2_11),
		.data_out2_12   (data_out2_12),
		.data_out2_13   (data_out2_13),
		.data_out2_14   (data_out2_14),
		.data_out2_15   (data_out2_15),
		.data_out2_16   (data_out2_16),
		.data_out2_17   (data_out2_17),
		.data_out2_18   (data_out2_18),
		.data_out2_19   (data_out2_19),
		.data_out2_20   (data_out2_20),
		.data_out2_21   (data_out2_21),
		.data_out2_22   (data_out2_22),
		.data_out2_23   (data_out2_23),
		.data_out2_24   (data_out2_24),

		.data_out3_0    (data_out3_0),
		.data_out3_1    (data_out3_1),
		.data_out3_2    (data_out3_2),
		.data_out3_3    (data_out3_3),
		.data_out3_4    (data_out3_4),
		.data_out3_5    (data_out3_5),
		.data_out3_6    (data_out3_6),
		.data_out3_7    (data_out3_7),
		.data_out3_8    (data_out3_8),
		.data_out3_9    (data_out3_9),
		.data_out3_10   (data_out3_10),
		.data_out3_11   (data_out3_11),
		.data_out3_12   (data_out3_12),
		.data_out3_13   (data_out3_13),
		.data_out3_14   (data_out3_14),
		.data_out3_15   (data_out3_15),
		.data_out3_16   (data_out3_16),
		.data_out3_17   (data_out3_17),
		.data_out3_18   (data_out3_18),
		.data_out3_19   (data_out3_19),
		.data_out3_20   (data_out3_20),
		.data_out3_21   (data_out3_21),
		.data_out3_22   (data_out3_22),
		.data_out3_23   (data_out3_23),
		.data_out3_24   (data_out3_24),

		.conv_out_calc  (conv_out_3),

		.valid_out_calc (valid_out_calc_3)
	);

endmodule