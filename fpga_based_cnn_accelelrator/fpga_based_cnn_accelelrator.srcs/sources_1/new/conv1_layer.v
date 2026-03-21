module conv1_layer (
	input  wire        clk,
	input  wire        rst_n,

	input  wire        valid_in,
	input  wire [7:0]  data_in,

	output wire [11:0] conv_out_1,
	output wire [11:0] conv_out_2,
	output wire [11:0] conv_out_3,

	output wire        valid_out_conv
);

	// Internal wires from line buffer

	wire [7:0] data_out_0;
	wire [7:0] data_out_1;
	wire [7:0] data_out_2;
	wire [7:0] data_out_3;
	wire [7:0] data_out_4;
	wire [7:0] data_out_5;
	wire [7:0] data_out_6;
	wire [7:0] data_out_7;
	wire [7:0] data_out_8;
	wire [7:0] data_out_9;
	wire [7:0] data_out_10;
	wire [7:0] data_out_11;
	wire [7:0] data_out_12;
	wire [7:0] data_out_13;
	wire [7:0] data_out_14;
	wire [7:0] data_out_15;
	wire [7:0] data_out_16;
	wire [7:0] data_out_17;
	wire [7:0] data_out_18;
	wire [7:0] data_out_19;
	wire [7:0] data_out_20;
	wire [7:0] data_out_21;
	wire [7:0] data_out_22;
	wire [7:0] data_out_23;
	wire [7:0] data_out_24;

	wire valid_out_buf;

	// Line buffer instance
	conv1_buf # (
	  .WIDTH      (28),
	  .HEIGHT     (28),
	  .DATA_BITS  (8),
	  .FILTERSIZE (5)
	) conv1_buf (
		.clk           (clk),
		.rst_n         (rst_n),

		.valid_in      (valid_in),
		.data_in       (data_in),

		.data_out_0    (data_out_0),
		.data_out_1    (data_out_1),
		.data_out_2    (data_out_2),
		.data_out_3    (data_out_3),
		.data_out_4    (data_out_4),
		.data_out_5    (data_out_5),
		.data_out_6    (data_out_6),
		.data_out_7    (data_out_7),
		.data_out_8    (data_out_8),
		.data_out_9    (data_out_9),
		.data_out_10   (data_out_10),
		.data_out_11   (data_out_11),
		.data_out_12   (data_out_12),
		.data_out_13   (data_out_13),
		.data_out_14   (data_out_14),
		.data_out_15   (data_out_15),
		.data_out_16   (data_out_16),
		.data_out_17   (data_out_17),
		.data_out_18   (data_out_18),
		.data_out_19   (data_out_19),
		.data_out_20   (data_out_20),
		.data_out_21   (data_out_21),
		.data_out_22   (data_out_22),
		.data_out_23   (data_out_23),
		.data_out_24   (data_out_24),

		.valid_out_buf (valid_out_buf)
	);

	// Convolution calculation instance
	conv1_calc #(
	  .WIDTH     (28),
	  .HEIGHT    (28),
	  .DATA_BITS (8)
	) conv1_calc (
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
		
		.valid_out_calc (valid_out_conv)
	);

endmodule