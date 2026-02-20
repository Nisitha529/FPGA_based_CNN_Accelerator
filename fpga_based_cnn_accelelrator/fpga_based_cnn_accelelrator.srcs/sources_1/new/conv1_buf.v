module conv1_buf #(
  parameter integer WIDTH      = 28,
  parameter integer HEIGHT     = 28,
  parameter integer DATA_BITS  = 8,
  parameter integer FILTERSIZE = 5
)(
  input                      clk,
  input                      rst_n,

  input                      valid_in,
  input      [DATA_BITS-1:0] data_in,

  output reg [DATA_BITS-1:0] data_out_0,
  output reg [DATA_BITS-1:0] data_out_1,
  output reg [DATA_BITS-1:0] data_out_2,
  output reg [DATA_BITS-1:0] data_out_3,
  output reg [DATA_BITS-1:0] data_out_4,
  output reg [DATA_BITS-1:0] data_out_5,
  output reg [DATA_BITS-1:0] data_out_6,
  output reg [DATA_BITS-1:0] data_out_7,
  output reg [DATA_BITS-1:0] data_out_8,
  output reg [DATA_BITS-1:0] data_out_9,
  output reg [DATA_BITS-1:0] data_out_10,
  output reg [DATA_BITS-1:0] data_out_11,
  output reg [DATA_BITS-1:0] data_out_12,
  output reg [DATA_BITS-1:0] data_out_13,
  output reg [DATA_BITS-1:0] data_out_14,
  output reg [DATA_BITS-1:0] data_out_15,
  output reg [DATA_BITS-1:0] data_out_16,
  output reg [DATA_BITS-1:0] data_out_17,
  output reg [DATA_BITS-1:0] data_out_18,
  output reg [DATA_BITS-1:0] data_out_19,
  output reg [DATA_BITS-1:0] data_out_20,
  output reg [DATA_BITS-1:0] data_out_21,
  output reg [DATA_BITS-1:0] data_out_22,
  output reg [DATA_BITS-1:0] data_out_23,
  output reg [DATA_BITS-1:0] data_out_24,

  output reg                 valid_out_buf
);

  reg [DATA_BITS - 1 : 0] buffer [WIDTH * FILTER_SIZE];
  reg [DATA_BITS - 1 : 0] buf_idx;
  reg [4 : 0]             w_idx;
  reg [4 : 0]             h_idx;
  reg [2 : 0]             buf_flag;
  reg                     state;

  integer i;

  always @ (posedge clk) begin
    if (~rst_n) begin
      for (i = 0; i < WIDTH * FILTERSIZE - 1; i = i + 1) begin
        buffer [i]  <= {DATA_BITS{1'b0}};
      end

      buf_idx       <= {DATA_BITS{1'b0}};
      w_idx         <= 5'b0;
      h_idx         <= 5'b0;
      buf_flag      <= 3'b0;
      state         <= 1'b0;
      valid_out_buf <= 1'b0;

      data_out_0    <= {DATA_BITS{1'b0}};
      data_out_1    <= {DATA_BITS{1'b0}};
      data_out_2    <= {DATA_BITS{1'b0}};
      data_out_3    <= {DATA_BITS{1'b0}};
      data_out_4    <= {DATA_BITS{1'b0}};
      data_out_5    <= {DATA_BITS{1'b0}};
      data_out_6    <= {DATA_BITS{1'b0}};
      data_out_7    <= {DATA_BITS{1'b0}};
      data_out_8    <= {DATA_BITS{1'b0}};
      data_out_9    <= {DATA_BITS{1'b0}};
      data_out_10   <= {DATA_BITS{1'b0}};
      data_out_11   <= {DATA_BITS{1'b0}};
      data_out_12   <= {DATA_BITS{1'b0}};
      data_out_13   <= {DATA_BITS{1'b0}};
      data_out_14   <= {DATA_BITS{1'b0}};
      data_out_15   <= {DATA_BITS{1'b0}};
      data_out_16   <= {DATA_BITS{1'b0}};
      data_out_17   <= {DATA_BITS{1'b0}};
      data_out_18   <= {DATA_BITS{1'b0}};
      data_out_19   <= {DATA_BITS{1'b0}};
      data_out_20   <= {DATA_BITS{1'b0}};
      data_out_21   <= {DATA_BITS{1'b0}};
      data_out_22   <= {DATA_BITS{1'b0}};
      data_out_23   <= {DATA_BITS{1'b0}};
      data_out_24   <= {DATA_BITS{1'b0}};
    end else begin
      if (valid_in) begin
        buf_idx     <= buf_idx + 1'd1;

				if (buf_idx == WODTH * FILTERSIZE - 1) begin
					buf_idx <= {DATA_BITS{1'b0}};
				end

				buffer [buf_idx] <= data_in;

				if (!state) begin
					if (buf_idx == WIDTH * FILTERSIZE - 1) begin
						
					end
				end

      end

    end
  end

endmodule
