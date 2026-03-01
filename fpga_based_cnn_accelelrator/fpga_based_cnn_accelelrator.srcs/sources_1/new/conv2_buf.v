module conv2_buf
    #(
        parameter integer WIDTH      = 12,
        parameter integer HEIGHT     = 12,
        parameter integer DATA_BITS  = 12
    )
    (
        input  wire                 clk,
        input  wire                 rst_n,
        input  wire                 valid_in,
        input  wire [DATA_BITS-1:0] data_in,

        output reg  [DATA_BITS-1:0] data_out_0,
        output reg  [DATA_BITS-1:0] data_out_1,
        output reg  [DATA_BITS-1:0] data_out_2,
        output reg  [DATA_BITS-1:0] data_out_3,
        output reg  [DATA_BITS-1:0] data_out_4,
        output reg  [DATA_BITS-1:0] data_out_5,
        output reg  [DATA_BITS-1:0] data_out_6,
        output reg  [DATA_BITS-1:0] data_out_7,
        output reg  [DATA_BITS-1:0] data_out_8,
        output reg  [DATA_BITS-1:0] data_out_9,
        output reg  [DATA_BITS-1:0] data_out_10,
        output reg  [DATA_BITS-1:0] data_out_11,
        output reg  [DATA_BITS-1:0] data_out_12,
        output reg  [DATA_BITS-1:0] data_out_13,
        output reg  [DATA_BITS-1:0] data_out_14,
        output reg  [DATA_BITS-1:0] data_out_15,
        output reg  [DATA_BITS-1:0] data_out_16,
        output reg  [DATA_BITS-1:0] data_out_17,
        output reg  [DATA_BITS-1:0] data_out_18,
        output reg  [DATA_BITS-1:0] data_out_19,
        output reg  [DATA_BITS-1:0] data_out_20,
        output reg  [DATA_BITS-1:0] data_out_21,
        output reg  [DATA_BITS-1:0] data_out_22,
        output reg  [DATA_BITS-1:0] data_out_23,
        output reg  [DATA_BITS-1:0] data_out_24,

        output reg                  valid_out_buf
    );

    localparam integer FILTER_SIZE = 5;

    // Line buffer: stores 5 rows of WIDTH pixels
    reg [DATA_BITS-1:0] buffer [0:WIDTH*FILTER_SIZE-1];

    // Indices and control
    reg [DATA_BITS-1:0] buf_idx;          // write pointer into buffer
    reg [4:0]           w_idx;            // column counter for output window
    reg [4:0]           h_idx;            // row counter for output window
    reg [2:0]           buf_flag;         // selects which 5 rows form the current window (0..4)
    reg                 state;            // 1 when buffer is full and streaming has started

    integer i;

    always @(posedge clk) begin
        if (~rst_n) begin
            // Reset buffer
            for (i = 0; i <= WIDTH * FILTER_SIZE - 1; i = i + 1)
                buffer[i] <= {DATA_BITS{1'b0}};

            // Reset counters and flags
            buf_idx       <= {DATA_BITS{1'b0}};
            w_idx         <= 5'b0;
            h_idx         <= 5'b0;
            buf_flag      <= 3'b0;
            state         <= 1'b0;
            valid_out_buf <= 1'b0;

            // Reset each output individually
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
                // Write incoming data into circular buffer
                buf_idx <= buf_idx + 1'b1;
                if (buf_idx == WIDTH * FILTER_SIZE - 1)
                    buf_idx <= {DATA_BITS{1'b0}};

                buffer[buf_idx] <= data_in;

                // After the first buffer fill, enter the valid streaming state
                if (!state) begin
                    if (buf_idx == WIDTH * FILTER_SIZE - 1)
                        state <= 1'b1;
                end else begin
                    // Move sliding window
                    w_idx <= w_idx + 1'b1;

                    // Determine when the window is inside the valid area (no padding)
                    if (w_idx == 0)
                        valid_out_buf <= 1'b1;                     // start of valid columns
                    else if (w_idx == WIDTH - FILTER_SIZE + 1)
                        valid_out_buf <= 1'b0;                     // end of valid columns

                    if (w_idx == WIDTH - 1) begin                  // end of a row
                        buf_flag <= buf_flag + 1'b1;
                        if (buf_flag == FILTER_SIZE - 1)
                            buf_flag <= 3'b0;
                        w_idx <= 5'b0;

                        if (h_idx == HEIGHT - FILTER_SIZE) begin   // last row of windows
                            h_idx <= 5'b0;
                            state <= 1'b0;                         // processing finished
                        end else begin
                            h_idx <= h_idx + 1'b1;
                        end
                    end

                    // Output the 5x5 window according to the current buf_flag
                    if (buf_flag == 3'd0) begin
                        data_out_0  <= buffer[w_idx];
                        data_out_1  <= buffer[w_idx + 1];
                        data_out_2  <= buffer[w_idx + 2];
                        data_out_3  <= buffer[w_idx + 3];
                        data_out_4  <= buffer[w_idx + 4];
                        data_out_5  <= buffer[w_idx + WIDTH];
                        data_out_6  <= buffer[w_idx + WIDTH + 1];
                        data_out_7  <= buffer[w_idx + WIDTH + 2];
                        data_out_8  <= buffer[w_idx + WIDTH + 3];
                        data_out_9  <= buffer[w_idx + WIDTH + 4];
                        data_out_10 <= buffer[w_idx + WIDTH * 2];
                        data_out_11 <= buffer[w_idx + WIDTH * 2 + 1];
                        data_out_12 <= buffer[w_idx + WIDTH * 2 + 2];
                        data_out_13 <= buffer[w_idx + WIDTH * 2 + 3];
                        data_out_14 <= buffer[w_idx + WIDTH * 2 + 4];
                        data_out_15 <= buffer[w_idx + WIDTH * 3];
                        data_out_16 <= buffer[w_idx + WIDTH * 3 + 1];
                        data_out_17 <= buffer[w_idx + WIDTH * 3 + 2];
                        data_out_18 <= buffer[w_idx + WIDTH * 3 + 3];
                        data_out_19 <= buffer[w_idx + WIDTH * 3 + 4];
                        data_out_20 <= buffer[w_idx + WIDTH * 4];
                        data_out_21 <= buffer[w_idx + WIDTH * 4 + 1];
                        data_out_22 <= buffer[w_idx + WIDTH * 4 + 2];
                        data_out_23 <= buffer[w_idx + WIDTH * 4 + 3];
                        data_out_24 <= buffer[w_idx + WIDTH * 4 + 4];
                    end else if (buf_flag == 3'd1) begin
                        data_out_0  <= buffer[w_idx + WIDTH];
                        data_out_1  <= buffer[w_idx + WIDTH + 1];
                        data_out_2  <= buffer[w_idx + WIDTH + 2];
                        data_out_3  <= buffer[w_idx + WIDTH + 3];
                        data_out_4  <= buffer[w_idx + WIDTH + 4];
                        data_out_5  <= buffer[w_idx + WIDTH * 2];
                        data_out_6  <= buffer[w_idx + WIDTH * 2 + 1];
                        data_out_7  <= buffer[w_idx + WIDTH * 2 + 2];
                        data_out_8  <= buffer[w_idx + WIDTH * 2 + 3];
                        data_out_9  <= buffer[w_idx + WIDTH * 2 + 4];
                        data_out_10 <= buffer[w_idx + WIDTH * 3];
                        data_out_11 <= buffer[w_idx + WIDTH * 3 + 1];
                        data_out_12 <= buffer[w_idx + WIDTH * 3 + 2];
                        data_out_13 <= buffer[w_idx + WIDTH * 3 + 3];
                        data_out_14 <= buffer[w_idx + WIDTH * 3 + 4];
                        data_out_15 <= buffer[w_idx + WIDTH * 4];
                        data_out_16 <= buffer[w_idx + WIDTH * 4 + 1];
                        data_out_17 <= buffer[w_idx + WIDTH * 4 + 2];
                        data_out_18 <= buffer[w_idx + WIDTH * 4 + 3];
                        data_out_19 <= buffer[w_idx + WIDTH * 4 + 4];
                        data_out_20 <= buffer[w_idx];
                        data_out_21 <= buffer[w_idx + 1];
                        data_out_22 <= buffer[w_idx + 2];
                        data_out_23 <= buffer[w_idx + 3];
                        data_out_24 <= buffer[w_idx + 4];
                    end else if (buf_flag == 3'd2) begin
                        data_out_0  <= buffer[w_idx + WIDTH * 2];
                        data_out_1  <= buffer[w_idx + WIDTH * 2 + 1];
                        data_out_2  <= buffer[w_idx + WIDTH * 2 + 2];
                        data_out_3  <= buffer[w_idx + WIDTH * 2 + 3];
                        data_out_4  <= buffer[w_idx + WIDTH * 2 + 4];
                        data_out_5  <= buffer[w_idx + WIDTH * 3];
                        data_out_6  <= buffer[w_idx + WIDTH * 3 + 1];
                        data_out_7  <= buffer[w_idx + WIDTH * 3 + 2];
                        data_out_8  <= buffer[w_idx + WIDTH * 3 + 3];
                        data_out_9  <= buffer[w_idx + WIDTH * 3 + 4];
                        data_out_10 <= buffer[w_idx + WIDTH * 4];
                        data_out_11 <= buffer[w_idx + WIDTH * 4 + 1];
                        data_out_12 <= buffer[w_idx + WIDTH * 4 + 2];
                        data_out_13 <= buffer[w_idx + WIDTH * 4 + 3];
                        data_out_14 <= buffer[w_idx + WIDTH * 4 + 4];
                        data_out_15 <= buffer[w_idx];
                        data_out_16 <= buffer[w_idx + 1];
                        data_out_17 <= buffer[w_idx + 2];
                        data_out_18 <= buffer[w_idx + 3];
                        data_out_19 <= buffer[w_idx + 4];
                        data_out_20 <= buffer[w_idx + WIDTH];
                        data_out_21 <= buffer[w_idx + WIDTH + 1];
                        data_out_22 <= buffer[w_idx + WIDTH + 2];
                        data_out_23 <= buffer[w_idx + WIDTH + 3];
                        data_out_24 <= buffer[w_idx + WIDTH + 4];
                    end else if (buf_flag == 3'd3) begin
                        data_out_0  <= buffer[w_idx + WIDTH * 3];
                        data_out_1  <= buffer[w_idx + WIDTH * 3 + 1];
                        data_out_2  <= buffer[w_idx + WIDTH * 3 + 2];
                        data_out_3  <= buffer[w_idx + WIDTH * 3 + 3];
                        data_out_4  <= buffer[w_idx + WIDTH * 3 + 4];
                        data_out_5  <= buffer[w_idx + WIDTH * 4];
                        data_out_6  <= buffer[w_idx + WIDTH * 4 + 1];
                        data_out_7  <= buffer[w_idx + WIDTH * 4 + 2];
                        data_out_8  <= buffer[w_idx + WIDTH * 4 + 3];
                        data_out_9  <= buffer[w_idx + WIDTH * 4 + 4];
                        data_out_10 <= buffer[w_idx];
                        data_out_11 <= buffer[w_idx + 1];
                        data_out_12 <= buffer[w_idx + 2];
                        data_out_13 <= buffer[w_idx + 3];
                        data_out_14 <= buffer[w_idx + 4];
                        data_out_15 <= buffer[w_idx + WIDTH];
                        data_out_16 <= buffer[w_idx + WIDTH + 1];
                        data_out_17 <= buffer[w_idx + WIDTH + 2];
                        data_out_18 <= buffer[w_idx + WIDTH + 3];
                        data_out_19 <= buffer[w_idx + WIDTH + 4];
                        data_out_20 <= buffer[w_idx + WIDTH * 2];
                        data_out_21 <= buffer[w_idx + WIDTH * 2 + 1];
                        data_out_22 <= buffer[w_idx + WIDTH * 2 + 2];
                        data_out_23 <= buffer[w_idx + WIDTH * 2 + 3];
                        data_out_24 <= buffer[w_idx + WIDTH * 2 + 4];
                    end else begin // buf_flag == 3'd4
                        data_out_0  <= buffer[w_idx + WIDTH * 4];
                        data_out_1  <= buffer[w_idx + WIDTH * 4 + 1];
                        data_out_2  <= buffer[w_idx + WIDTH * 4 + 2];
                        data_out_3  <= buffer[w_idx + WIDTH * 4 + 3];
                        data_out_4  <= buffer[w_idx + WIDTH * 4 + 4];
                        data_out_5  <= buffer[w_idx];
                        data_out_6  <= buffer[w_idx + 1];
                        data_out_7  <= buffer[w_idx + 2];
                        data_out_8  <= buffer[w_idx + 3];
                        data_out_9  <= buffer[w_idx + 4];
                        data_out_10 <= buffer[w_idx + WIDTH];
                        data_out_11 <= buffer[w_idx + WIDTH + 1];
                        data_out_12 <= buffer[w_idx + WIDTH + 2];
                        data_out_13 <= buffer[w_idx + WIDTH + 3];
                        data_out_14 <= buffer[w_idx + WIDTH + 4];
                        data_out_15 <= buffer[w_idx + WIDTH * 2];
                        data_out_16 <= buffer[w_idx + WIDTH * 2 + 1];
                        data_out_17 <= buffer[w_idx + WIDTH * 2 + 2];
                        data_out_18 <= buffer[w_idx + WIDTH * 2 + 3];
                        data_out_19 <= buffer[w_idx + WIDTH * 2 + 4];
                        data_out_20 <= buffer[w_idx + WIDTH * 3];
                        data_out_21 <= buffer[w_idx + WIDTH * 3 + 1];
                        data_out_22 <= buffer[w_idx + WIDTH * 3 + 2];
                        data_out_23 <= buffer[w_idx + WIDTH * 3 + 3];
                        data_out_24 <= buffer[w_idx + WIDTH * 3 + 4];
                    end
                end
            end
        end
    end

endmodule