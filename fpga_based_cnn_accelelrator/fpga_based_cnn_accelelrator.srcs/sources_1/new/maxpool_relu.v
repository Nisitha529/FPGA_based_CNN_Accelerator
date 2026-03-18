module maxpool_relu #(
	parameter CONV_BIT       = 12,
	parameter HALF_WIDTH     = 12,
	parameter HALF_HEIGHT    = 12,
  parameter HALF_WIDTH_BIT = 4
)(
	input                                 clk,
	input                                 rst_n,

	input                                 valid_in,

	input  wire signed [CONV_BIT - 1 : 0] conv_out_1,
	input  wire signed [CONV_BIT - 1 : 0] conv_out_2,
	input  wire signed [CONV_BIT - 1 : 0] conv_out_3,
  
	output reg         [CONV_BIT - 1 : 0] max_value_1,
	output reg         [CONV_BIT - 1 : 0] max_value_2,
	output reg         [CONV_BIT - 1 : 0] max_value_3,

	output reg                            valid_out_relu
);

  // Buffers to hold intermediate maxima for each channel
	reg signed [CONV_BIT-1 : 0] buffer1 [0 : HALF_WIDTH - 1];
	reg signed [CONV_BIT-1 : 0] buffer2 [0 : HALF_WIDTH - 1];
	reg signed [CONV_BIT-1 : 0] buffer3 [0 : HALF_WIDTH - 1];	

	// Control signals
	reg [HALF_WIDTH_BIT - 1 : 0] pcount; // Column counter within a row
	reg                          state;  // Processing which row of a 2x2 block
	reg                          flag;   // Toggle each valid in

	integer i;

	always @ (posedge clk) begin
		if (~rst_n) begin
			for (i = 0; i <= HALF_WIDTH - 1; i = i + 1) begin
				buffer1[i]   <= 12'd0;
				buffer2[i]   <= 12'd0;
				buffer3[i]   <= 12'd0;
			end
			
			max_value_1    <= 12'd0;
			max_value_2    <= 12'd0;
			max_value_3    <= 12'd0;

			valid_out_relu <= 1'd0;

			pcount         <= 4'd0;
			state          <= 1'd0;
			flag           <= 1'd0;
		end else begin
			if (valid_in) begin
				flag <= ~flag; // Flag toggles every cycle. indicates whether this is the first (flag=0) or second (flag=1) pixel in the current row of the 2x2 block.

        if (flag == 1) begin
					pcount <= pcount + 4'd1;

          if (pcount == HALF_WIDTH - 1) begin // When a row is finished, toggle state and reset the pcount
						state <= ~state;
						pcount <= 4'd0; 
					end

				end

				if (state == 0) begin
					valid_out_relu <= 1'd0;

          if (flag == 0) begin
						// First pixel of the first row
						buffer1[pcount] <= conv_out_1;
						buffer2[pcount] <= conv_out_2;
						buffer3[pcount] <= conv_out_3;
					end else begin
						// Second pixel of the first row : Compare with the stored value and replace accordingly.

						if (buffer1[pcount] < conv_out_1) begin
							buffer1[pcount] <= conv_out_1;
						end

						if (buffer2[pcount] < conv_out_2) begin
							buffer2[pcount] <= conv_out_2;
						end

						if (buffer3[pcount] < conv_out_3) begin
							buffer3[pcount] <= conv_out_3;
						end

					end

				end else begin
					if (flag == 0) begin
						// First pixel of the second row.
						valid_out_relu    <= 1'd0;

						if (buffer1[pcount] < conv_out_1) begin
							buffer1[pcount] <= conv_out_1;
						end

						if (buffer2[pcount] < conv_out_2) begin
							buffer2[pcount] <= conv_out_2;
						end

						if (buffer3[pcount] < conv_out_3) begin
							buffer3[pcount] <= conv_out_3;
						end

					end else begin
						// Second pixel of the second row comparison
						valid_out_relu    <= 1'd1;

            // Activating Relu to the final value of the maxpooling.
            if (buffer1[pcount] < conv_out_1) begin 
              if (conv_out_1 > 0) begin
								max_value_1   <= conv_out_1;
							end else begin
								max_value_1   <= 0;
							end

						end else begin
							if (buffer1[pcount] > 0) begin
								max_value_1   <= buffer1[pcount];
							end else begin
								max_value_1   <= 0;
							end

						end

            if (buffer2[pcount] < conv_out_2) begin 
              if (conv_out_2 > 0) begin
								max_value_2   <= conv_out_2;
							end else begin
								max_value_2   <= 0;
							end

						end else begin
							if (buffer2[pcount] > 0) begin
								max_value_2   <= buffer2[pcount];
							end else begin
								max_value_2   <= 0;
							end
							
						end

            if (buffer3[pcount] < conv_out_3) begin 
              if (conv_out_3 > 0) begin
								max_value_3   <= conv_out_3;
							end else begin
								max_value_3   <= 0;
							end

						end else begin
							if (buffer3[pcount] > 0) begin
								max_value_3   <= buffer3[pcount];
							end else begin
								max_value_3   <= 0;
							end
							
						end

					end

				end

			end else begin
				valid_out_relu <= 1'd0;
			end

		end
	end
    
endmodule