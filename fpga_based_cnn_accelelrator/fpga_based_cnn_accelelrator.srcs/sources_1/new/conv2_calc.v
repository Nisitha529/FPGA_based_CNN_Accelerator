// This module performs a convolution of three 5x5 input windows with three separate 5x5 filters.
// Eventually release one convolutional value.

module conv2_calc #(
	parameter WIDTH     = 28,
	parameter HEIGHT    = 28,
	parameter DATA_BITS = 12,

  parameter WEIGHT_1  = "conv2_weight_11.mem",
  parameter WEIGHT_2  = "conv2_weight_12.mem",
  parameter WEIGHT_3  = "conv2_weight_13.mem"
)(
	input  wire                        clk,
	input  wire                        rst_n,

	input  wire                        valid_out_buf,

	input  wire signed [DATA_BITS-1:0] data_out1_0,
	input  wire signed [DATA_BITS-1:0] data_out1_1,
	input  wire signed [DATA_BITS-1:0] data_out1_2,
	input  wire signed [DATA_BITS-1:0] data_out1_3,
	input  wire signed [DATA_BITS-1:0] data_out1_4,
	input  wire signed [DATA_BITS-1:0] data_out1_5,
	input  wire signed [DATA_BITS-1:0] data_out1_6,
	input  wire signed [DATA_BITS-1:0] data_out1_7,
	input  wire signed [DATA_BITS-1:0] data_out1_8,
	input  wire signed [DATA_BITS-1:0] data_out1_9,
	input  wire signed [DATA_BITS-1:0] data_out1_10,
	input  wire signed [DATA_BITS-1:0] data_out1_11,
	input  wire signed [DATA_BITS-1:0] data_out1_12,
	input  wire signed [DATA_BITS-1:0] data_out1_13,
	input  wire signed [DATA_BITS-1:0] data_out1_14,
	input  wire signed [DATA_BITS-1:0] data_out1_15,
	input  wire signed [DATA_BITS-1:0] data_out1_16,
	input  wire signed [DATA_BITS-1:0] data_out1_17,
	input  wire signed [DATA_BITS-1:0] data_out1_18,
	input  wire signed [DATA_BITS-1:0] data_out1_19,  
	input  wire signed [DATA_BITS-1:0] data_out1_20,
	input  wire signed [DATA_BITS-1:0] data_out1_21,
	input  wire signed [DATA_BITS-1:0] data_out1_22,
	input  wire signed [DATA_BITS-1:0] data_out1_23,
	input  wire signed [DATA_BITS-1:0] data_out1_24,

	input  wire signed [DATA_BITS-1:0] data_out2_0,
	input  wire signed [DATA_BITS-1:0] data_out2_1,
	input  wire signed [DATA_BITS-1:0] data_out2_2,
	input  wire signed [DATA_BITS-1:0] data_out2_3,
	input  wire signed [DATA_BITS-1:0] data_out2_4,
	input  wire signed [DATA_BITS-1:0] data_out2_5,
	input  wire signed [DATA_BITS-1:0] data_out2_6,
	input  wire signed [DATA_BITS-1:0] data_out2_7,
	input  wire signed [DATA_BITS-1:0] data_out2_8,
	input  wire signed [DATA_BITS-1:0] data_out2_9,
	input  wire signed [DATA_BITS-1:0] data_out2_10,
	input  wire signed [DATA_BITS-1:0] data_out2_11,
	input  wire signed [DATA_BITS-1:0] data_out2_12,
	input  wire signed [DATA_BITS-1:0] data_out2_13,
	input  wire signed [DATA_BITS-1:0] data_out2_14,
	input  wire signed [DATA_BITS-1:0] data_out2_15,
	input  wire signed [DATA_BITS-1:0] data_out2_16,
	input  wire signed [DATA_BITS-1:0] data_out2_17,
	input  wire signed [DATA_BITS-1:0] data_out2_18,
	input  wire signed [DATA_BITS-1:0] data_out2_19,  
	input  wire signed [DATA_BITS-1:0] data_out2_20,
	input  wire signed [DATA_BITS-1:0] data_out2_21,
	input  wire signed [DATA_BITS-1:0] data_out2_22,
	input  wire signed [DATA_BITS-1:0] data_out2_23,
	input  wire signed [DATA_BITS-1:0] data_out2_24,

	input  wire signed [DATA_BITS-1:0] data_out3_0,
	input  wire signed [DATA_BITS-1:0] data_out3_1,
	input  wire signed [DATA_BITS-1:0] data_out3_2,
	input  wire signed [DATA_BITS-1:0] data_out3_3,
	input  wire signed [DATA_BITS-1:0] data_out3_4,
	input  wire signed [DATA_BITS-1:0] data_out3_5,
	input  wire signed [DATA_BITS-1:0] data_out3_6,
	input  wire signed [DATA_BITS-1:0] data_out3_7,
	input  wire signed [DATA_BITS-1:0] data_out3_8,
	input  wire signed [DATA_BITS-1:0] data_out3_9,
	input  wire signed [DATA_BITS-1:0] data_out3_10,
	input  wire signed [DATA_BITS-1:0] data_out3_11,
	input  wire signed [DATA_BITS-1:0] data_out3_12,
	input  wire signed [DATA_BITS-1:0] data_out3_13,
	input  wire signed [DATA_BITS-1:0] data_out3_14,
	input  wire signed [DATA_BITS-1:0] data_out3_15,
	input  wire signed [DATA_BITS-1:0] data_out3_16,
	input  wire signed [DATA_BITS-1:0] data_out3_17,
	input  wire signed [DATA_BITS-1:0] data_out3_18,
	input  wire signed [DATA_BITS-1:0] data_out3_19,  
	input  wire signed [DATA_BITS-1:0] data_out3_20,
	input  wire signed [DATA_BITS-1:0] data_out3_21,
	input  wire signed [DATA_BITS-1:0] data_out3_22,
	input  wire signed [DATA_BITS-1:0] data_out3_23,
	input  wire signed [DATA_BITS-1:0] data_out3_24,

	output wire        [13:0]          conv_out_calc,

	output wire                        valid_out_calc
);

  wire signed [19:0] calc_out;      
  wire signed [19:0] calc_out_1;    
  wire signed [19:0] calc_out_2;  
  wire signed [19:0] calc_out_3; 

  reg signed  [7:0]  weight_1   [0:24];   
  reg signed  [7:0]  weight_2   [0:24];   
  reg signed  [7:0]  weight_3   [0:24];

 // Pipeline registers for the three multiplier-adder trees. Each tree has 4 stages, using 20-bit signed accumulators to avoid overflow.

	// Channel 1 pipeline registers

	reg signed [19:0] calc_out_1_tmp0;
	reg signed [19:0] calc_out_1_tmp1;
	reg signed [19:0] calc_out_1_tmp2;
	reg signed [19:0] calc_out_1_tmp3;
	reg signed [19:0] calc_out_1_tmp4;
	reg signed [19:0] calc_out_1_tmp5;
	reg signed [19:0] calc_out_1_tmp6;
	reg signed [19:0] calc_out_1_tmp7;
	reg signed [19:0] calc_out_1_tmp8;
	reg signed [19:0] calc_out_1_tmp9;
	reg signed [19:0] calc_out_1_tmp10;
	reg signed [19:0] calc_out_1_tmp11;
	reg signed [19:0] calc_out_1_tmp12;
	reg signed [19:0] calc_out_1_tmp13;
	reg signed [19:0] calc_out_1_tmp14;
	reg signed [19:0] calc_out_1_tmp15;
	reg signed [19:0] calc_out_1_tmp16;
	reg signed [19:0] calc_out_1_tmp17;
	reg signed [19:0] calc_out_1_tmp18;
	reg signed [19:0] calc_out_1_tmp19;
	reg signed [19:0] calc_out_1_tmp20;
	reg signed [19:0] calc_out_1_tmp21;
	reg signed [19:0] calc_out_1_tmp22;

	// Channel 2 pipeline registers

	reg signed [19:0] calc_out_2_tmp0;
	reg signed [19:0] calc_out_2_tmp1;
	reg signed [19:0] calc_out_2_tmp2;
	reg signed [19:0] calc_out_2_tmp3;
	reg signed [19:0] calc_out_2_tmp4;
	reg signed [19:0] calc_out_2_tmp5;
	reg signed [19:0] calc_out_2_tmp6;
	reg signed [19:0] calc_out_2_tmp7;
	reg signed [19:0] calc_out_2_tmp8;
	reg signed [19:0] calc_out_2_tmp9;
	reg signed [19:0] calc_out_2_tmp10;
	reg signed [19:0] calc_out_2_tmp11;
	reg signed [19:0] calc_out_2_tmp12;
	reg signed [19:0] calc_out_2_tmp13;
	reg signed [19:0] calc_out_2_tmp14;
	reg signed [19:0] calc_out_2_tmp15;
	reg signed [19:0] calc_out_2_tmp16;
	reg signed [19:0] calc_out_2_tmp17;
	reg signed [19:0] calc_out_2_tmp18;
	reg signed [19:0] calc_out_2_tmp19;
	reg signed [19:0] calc_out_2_tmp20;
	reg signed [19:0] calc_out_2_tmp21;
	reg signed [19:0] calc_out_2_tmp22;

	// Channel 3 pipeline registers

	reg signed [19:0] calc_out_3_tmp0;
	reg signed [19:0] calc_out_3_tmp1;
	reg signed [19:0] calc_out_3_tmp2;
	reg signed [19:0] calc_out_3_tmp3;
	reg signed [19:0] calc_out_3_tmp4;
	reg signed [19:0] calc_out_3_tmp5;
	reg signed [19:0] calc_out_3_tmp6;
	reg signed [19:0] calc_out_3_tmp7;
	reg signed [19:0] calc_out_3_tmp8;
	reg signed [19:0] calc_out_3_tmp9;
	reg signed [19:0] calc_out_3_tmp10;
	reg signed [19:0] calc_out_3_tmp11;
	reg signed [19:0] calc_out_3_tmp12;
	reg signed [19:0] calc_out_3_tmp13;
	reg signed [19:0] calc_out_3_tmp14;
	reg signed [19:0] calc_out_3_tmp15;
	reg signed [19:0] calc_out_3_tmp16;
	reg signed [19:0] calc_out_3_tmp17;
	reg signed [19:0] calc_out_3_tmp18;
	reg signed [19:0] calc_out_3_tmp19;
	reg signed [19:0] calc_out_3_tmp20;
	reg signed [19:0] calc_out_3_tmp21;
	reg signed [19:0] calc_out_3_tmp22;

	// Valid signal pipeline: toggle on each input valid, then delay 3 cycles

	reg valid_out_calc_tmp0;
	reg valid_out_calc_tmp1;
	reg valid_out_calc_tmp2;
	reg valid_out_calc_tmp3;

	initial begin
		$readmemh(WEIGHT_1, weight_1);
		$readmemh(WEIGHT_2, weight_2);
		$readmemh(WEIGHT_3, weight_3);
	end

	// Multi stage multiplication and addition for channel 1

	// Stage 1: 13 partial sums (12 pairs + 1 single)

	always @(posedge clk) begin
		if (~rst_n) begin
			calc_out_1_tmp0  <= 0;
			calc_out_1_tmp1  <= 0;
			calc_out_1_tmp2  <= 0;
			calc_out_1_tmp3  <= 0;
			calc_out_1_tmp4  <= 0;
			calc_out_1_tmp5  <= 0;
			calc_out_1_tmp6  <= 0;
			calc_out_1_tmp7  <= 0;
			calc_out_1_tmp8  <= 0;
			calc_out_1_tmp9  <= 0;
			calc_out_1_tmp10 <= 0;
			calc_out_1_tmp11 <= 0;
			calc_out_1_tmp12 <= 0;
	  end else begin
			calc_out_1_tmp0  <= data_out1_0  * weight_1[0]  + data_out1_1  * weight_1[1];
			calc_out_1_tmp1  <= data_out1_2  * weight_1[2]  + data_out1_3  * weight_1[3];
			calc_out_1_tmp2  <= data_out1_4  * weight_1[4]  + data_out1_5  * weight_1[5];
			calc_out_1_tmp3  <= data_out1_6  * weight_1[6]  + data_out1_7  * weight_1[7];
			calc_out_1_tmp4  <= data_out1_8  * weight_1[8]  + data_out1_9  * weight_1[9];
			calc_out_1_tmp5  <= data_out1_10 * weight_1[10] + data_out1_11 * weight_1[11];
			calc_out_1_tmp6  <= data_out1_12 * weight_1[12] + data_out1_13 * weight_1[13];
			calc_out_1_tmp7  <= data_out1_14 * weight_1[14] + data_out1_15 * weight_1[15];
			calc_out_1_tmp8  <= data_out1_16 * weight_1[16] + data_out1_17 * weight_1[17];
			calc_out_1_tmp9  <= data_out1_18 * weight_1[18] + data_out1_19 * weight_1[19];
			calc_out_1_tmp10 <= data_out1_20 * weight_1[20] + data_out1_21 * weight_1[21];
			calc_out_1_tmp11 <= data_out1_22 * weight_1[22] + data_out1_23 * weight_1[23];
			calc_out_1_tmp12 <= data_out1_24 * weight_1[24];
		end
	end

	// Stage 2: sum pairs into 6 intermediate values

	always @(posedge clk) begin
		if (~rst_n) begin
			calc_out_1_tmp13 <= 0;
			calc_out_1_tmp14 <= 0;
			calc_out_1_tmp15 <= 0;
			calc_out_1_tmp16 <= 0;
			calc_out_1_tmp17 <= 0;
			calc_out_1_tmp18 <= 0;
		end else begin
			calc_out_1_tmp13 <= calc_out_1_tmp0  + calc_out_1_tmp1;
			calc_out_1_tmp14 <= calc_out_1_tmp2  + calc_out_1_tmp3;
			calc_out_1_tmp15 <= calc_out_1_tmp4  + calc_out_1_tmp5;
			calc_out_1_tmp16 <= calc_out_1_tmp6  + calc_out_1_tmp7;
			calc_out_1_tmp17 <= calc_out_1_tmp8  + calc_out_1_tmp9;
			calc_out_1_tmp18 <= calc_out_1_tmp10 + calc_out_1_tmp11 + calc_out_1_tmp12;
		end
	end

  // Stage 3: combine into three sums

	always @(posedge clk) begin
		if (~rst_n) begin
			calc_out_1_tmp19 <= 0;
			calc_out_1_tmp20 <= 0;
			calc_out_1_tmp21 <= 0;
		end else begin
			calc_out_1_tmp19 <= calc_out_1_tmp13 + calc_out_1_tmp14;
			calc_out_1_tmp20 <= calc_out_1_tmp15 + calc_out_1_tmp16;
			calc_out_1_tmp21 <= calc_out_1_tmp17 + calc_out_1_tmp18;
		end
	end

	// Stage 4: final sum for channel 1

	always @(posedge clk) begin
		if (~rst_n) begin
			calc_out_1_tmp22 <= 0;
		end else begin
			calc_out_1_tmp22 <= calc_out_1_tmp19 + calc_out_1_tmp20 + calc_out_1_tmp21;
		end
	end

	assign calc_out_1 = calc_out_1_tmp22;

	// Multi-stage multiplication and addition for channel 2

	always @(posedge clk) begin
		if (~rst_n) begin
			calc_out_2_tmp0  <= 0; 
			calc_out_2_tmp1  <= 0;
			calc_out_2_tmp2  <= 0; 
			calc_out_2_tmp3  <= 0;
			calc_out_2_tmp4  <= 0; 
			calc_out_2_tmp5  <= 0; 
			calc_out_2_tmp6  <= 0; 
			calc_out_2_tmp7  <= 0;
			calc_out_2_tmp8  <= 0; 
			calc_out_2_tmp9  <= 0; 
			calc_out_2_tmp10 <= 0; 
			calc_out_2_tmp11 <= 0;
			calc_out_2_tmp12 <= 0;
		end else begin
			calc_out_2_tmp0  <= data_out2_0  * weight_2[0]  + data_out2_1  * weight_2[1];
			calc_out_2_tmp1  <= data_out2_2  * weight_2[2]  + data_out2_3  * weight_2[3];
			calc_out_2_tmp2  <= data_out2_4  * weight_2[4]  + data_out2_5  * weight_2[5];
			calc_out_2_tmp3  <= data_out2_6  * weight_2[6]  + data_out2_7  * weight_2[7];
			calc_out_2_tmp4  <= data_out2_8  * weight_2[8]  + data_out2_9  * weight_2[9];
			calc_out_2_tmp5  <= data_out2_10 * weight_2[10] + data_out2_11 * weight_2[11];
			calc_out_2_tmp6  <= data_out2_12 * weight_2[12] + data_out2_13 * weight_2[13];
			calc_out_2_tmp7  <= data_out2_14 * weight_2[14] + data_out2_15 * weight_2[15];
			calc_out_2_tmp8  <= data_out2_16 * weight_2[16] + data_out2_17 * weight_2[17];
			calc_out_2_tmp9  <= data_out2_18 * weight_2[18] + data_out2_19 * weight_2[19];
			calc_out_2_tmp10 <= data_out2_20 * weight_2[20] + data_out2_21 * weight_2[21];
			calc_out_2_tmp11 <= data_out2_22 * weight_2[22] + data_out2_23 * weight_2[23];
			calc_out_2_tmp12 <= data_out2_24 * weight_2[24];
		end
	end

	always @(posedge clk) begin
		if (~rst_n) begin
			calc_out_2_tmp13 <= 0; 
			calc_out_2_tmp14 <= 0; 
			calc_out_2_tmp15 <= 0;
			calc_out_2_tmp16 <= 0; 
			calc_out_2_tmp17 <= 0; 
			calc_out_2_tmp18 <= 0;
		end else begin
			calc_out_2_tmp13 <= calc_out_2_tmp0 + calc_out_2_tmp1;
			calc_out_2_tmp14 <= calc_out_2_tmp2 + calc_out_2_tmp3;
			calc_out_2_tmp15 <= calc_out_2_tmp4 + calc_out_2_tmp5;
			calc_out_2_tmp16 <= calc_out_2_tmp6 + calc_out_2_tmp7;
			calc_out_2_tmp17 <= calc_out_2_tmp8 + calc_out_2_tmp9;
			calc_out_2_tmp18 <= calc_out_2_tmp10 + calc_out_2_tmp11 + calc_out_2_tmp12;
		end
	end

	always @(posedge clk) begin
		if (~rst_n) begin
			calc_out_2_tmp19 <= 0; 
			calc_out_2_tmp20 <= 0; 
			calc_out_2_tmp21 <= 0;
		end else begin
			calc_out_2_tmp19 <= calc_out_2_tmp13 + calc_out_2_tmp14;
			calc_out_2_tmp20 <= calc_out_2_tmp15 + calc_out_2_tmp16;
			calc_out_2_tmp21 <= calc_out_2_tmp17 + calc_out_2_tmp18;
		end
	end

	always @(posedge clk) begin
		if (~rst_n) begin
			calc_out_2_tmp22 <= 0;
		end else begin
			calc_out_2_tmp22 <= calc_out_2_tmp19 + calc_out_2_tmp20 + calc_out_2_tmp21;
		end
	end

	assign calc_out_2 = calc_out_2_tmp22;	

	// Multi-stage multiplication and addition for channel 3 

	always @(posedge clk) begin
		if (~rst_n) begin
			calc_out_3_tmp0  <= 0; 
			calc_out_3_tmp1  <= 0; 
			calc_out_3_tmp2  <= 0; 
			calc_out_3_tmp3  <= 0;
			calc_out_3_tmp4  <= 0; 
			calc_out_3_tmp5  <= 0; 
			calc_out_3_tmp6  <= 0; 
			calc_out_3_tmp7  <= 0;
			calc_out_3_tmp8  <= 0; 
			calc_out_3_tmp9  <= 0; 
			calc_out_3_tmp10 <= 0; 
			calc_out_3_tmp11 <= 0;
			calc_out_3_tmp12 <= 0;
		end else begin
			calc_out_3_tmp0  <= data_out3_0  * weight_3[0]  + data_out3_1  * weight_3[1];
			calc_out_3_tmp1  <= data_out3_2  * weight_3[2]  + data_out3_3  * weight_3[3];
			calc_out_3_tmp2  <= data_out3_4  * weight_3[4]  + data_out3_5  * weight_3[5];
			calc_out_3_tmp3  <= data_out3_6  * weight_3[6]  + data_out3_7  * weight_3[7];
			calc_out_3_tmp4  <= data_out3_8  * weight_3[8]  + data_out3_9  * weight_3[9];
			calc_out_3_tmp5  <= data_out3_10 * weight_3[10] + data_out3_11 * weight_3[11];
			calc_out_3_tmp6  <= data_out3_12 * weight_3[12] + data_out3_13 * weight_3[13];
			calc_out_3_tmp7  <= data_out3_14 * weight_3[14] + data_out3_15 * weight_3[15];
			calc_out_3_tmp8  <= data_out3_16 * weight_3[16] + data_out3_17 * weight_3[17];
			calc_out_3_tmp9  <= data_out3_18 * weight_3[18] + data_out3_19 * weight_3[19];
			calc_out_3_tmp10 <= data_out3_20 * weight_3[20] + data_out3_21 * weight_3[21];
			calc_out_3_tmp11 <= data_out3_22 * weight_3[22] + data_out3_23 * weight_3[23];
			calc_out_3_tmp12 <= data_out3_24 * weight_3[24];
		end
	end

	always @(posedge clk) begin
		if (~rst_n) begin
			calc_out_3_tmp13 <= 0; 
			calc_out_3_tmp14 <= 0; 
			calc_out_3_tmp15 <= 0;
			calc_out_3_tmp16 <= 0; 
			calc_out_3_tmp17 <= 0; 
			calc_out_3_tmp18 <= 0;
		end else begin
			calc_out_3_tmp13 <= calc_out_3_tmp0  + calc_out_3_tmp1;
			calc_out_3_tmp14 <= calc_out_3_tmp2  + calc_out_3_tmp3;
			calc_out_3_tmp15 <= calc_out_3_tmp4  + calc_out_3_tmp5;
			calc_out_3_tmp16 <= calc_out_3_tmp6  + calc_out_3_tmp7;
			calc_out_3_tmp17 <= calc_out_3_tmp8  + calc_out_3_tmp9;
			calc_out_3_tmp18 <= calc_out_3_tmp10 + calc_out_3_tmp11 + calc_out_3_tmp12;
		end
	end

	always @(posedge clk) begin
		if (~rst_n) begin
			calc_out_3_tmp19 <= 0; 
			calc_out_3_tmp20 <= 0; 
			calc_out_3_tmp21 <= 0;
		end else begin
			calc_out_3_tmp19 <= calc_out_3_tmp13 + calc_out_3_tmp14;
			calc_out_3_tmp20 <= calc_out_3_tmp15 + calc_out_3_tmp16;
			calc_out_3_tmp21 <= calc_out_3_tmp17 + calc_out_3_tmp18;
		end
	end

	always @(posedge clk) begin
		if (~rst_n) begin
			calc_out_3_tmp22 <= 0;
		end else begin
			calc_out_3_tmp22 <= calc_out_3_tmp19 + calc_out_3_tmp20 + calc_out_3_tmp21;
		end
	end

	assign calc_out_3     = calc_out_3_tmp22;

  // Combine the three channel accumulators and truncate to 14 bits

  assign calc_out      = calc_out_1 + calc_out_2 + calc_out_3;
  assign conv_out_calc = calc_out[19:6];                   // Divide by 64

	// Valid signal generation

	always @(posedge clk) begin
		if (~rst_n) begin
			valid_out_calc_tmp0     <= 0;
		end else begin
			// Toggle on each valid_out_buf high
			if (valid_out_buf == 1) begin
				if (valid_out_calc_tmp0 == 1)
					valid_out_calc_tmp0 <= 0;
				else
					valid_out_calc_tmp0 <= 1;
			end
		end
	end

	always @(posedge clk) begin
		if (~rst_n) begin
			valid_out_calc_tmp1     <= 0;
			valid_out_calc_tmp2     <= 0;
			valid_out_calc_tmp3     <= 0;
		end else begin
			valid_out_calc_tmp1     <= valid_out_calc_tmp0;
			valid_out_calc_tmp2     <= valid_out_calc_tmp1;
			valid_out_calc_tmp3     <= valid_out_calc_tmp2;
		end
	end

	assign valid_out_calc = valid_out_calc_tmp3;

endmodule