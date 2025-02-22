// Synchronous FIFO module
module sync_fifo #(
    parameter DEPTH = 16,          // FIFO depth
    parameter DATA_WIDTH = 32      // Data width
)(
    // Interface ports
    input  logic                  clk,      // Clock input
    input  logic                  rst_n,    // Active-low reset
    input  logic                  wr_en,    // Write enable
    input  logic                  rd_en,    // Read enable
    input  logic [DATA_WIDTH-1:0] wr_data,  // Write data
    output logic [DATA_WIDTH-1:0] rd_data,  // Read data
    output logic                  full,     // FIFO full flag
    output logic                  empty     // FIFO empty flag
);

    // Calculate address width based on FIFO depth
    localparam ADDR_WIDTH = $clog2(DEPTH);
    
    // Internal signals
    logic [DATA_WIDTH-1:0] mem [DEPTH-1:0];     // Memory array
    logic [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;      // Write and read pointers
    logic [ADDR_WIDTH:0]   count;               // Number of entries

    // Write pointer logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wr_ptr <= '0;    // Reset write pointer
        else if (wr_en && !full)    // Increment if writing and not full
            wr_ptr <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1'b1;    // Wrap around
    end

    // Read pointer logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rd_ptr <= '0;    // Reset read pointer
        else if (rd_en && !empty)    // Increment if reading and not empty
            rd_ptr <= (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1'b1;    // Wrap around
    end

    // Count logic - tracks number of entries
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= '0;    // Reset count
        else if (wr_en && !rd_en && !full)    // Writing only
            count <= count + 1'b1;
        else if (!wr_en && rd_en && !empty)   // Reading only
            count <= count - 1'b1;
    end

    // Memory write operation
    always_ff @(posedge clk) begin
        if (wr_en && !full)    // Write data when enabled and not full
            mem[wr_ptr] <= wr_data;
    end

    // Memory read operation (combinational)
    assign rd_data = mem[rd_ptr];    // Always output data at read pointer

    // Status flags
    assign full  = (count == DEPTH);    // FIFO is full when count equals depth
    assign empty = (count == 0);        // FIFO is empty when count is zero

endmodule