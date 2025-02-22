// Module declaration with configurable data and address widths
module MemoryController #(
    parameter DATA_WIDTH = 32,    // Defines the width of data bus (default 32 bits)
    parameter ADDR_WIDTH = 16     // Defines the width of address bus (default 16 bits)
)(
    // Port declarations
    input wire clk,              // Clock signal
    input wire reset,            // Reset signal
    input wire write_enable,     // Signal to enable write operations
    input wire read_enable,      // Signal to enable read operations
    input wire [ADDR_WIDTH-1:0] address,    // Address bus for read/write operations
    input wire [DATA_WIDTH-1:0] write_data, // Data to be written to memory
    output reg [DATA_WIDTH-1:0] read_data,  // Data read from memory
    output reg ready            // Signal indicating operation completion
);

    // Memory array declaration
    // Creates a 2D array of registers where each element is DATA_WIDTH bits wide
    // Total size is 2^ADDR_WIDTH elements
    reg [DATA_WIDTH-1:0] memory [0:2**ADDR_WIDTH-1];

    // State machine state definitions
    localparam IDLE  = 2'b00;    // Idle state: waiting for commands
    localparam READ  = 2'b01;    // Read state: performing read operation
    localparam WRITE = 2'b10;    // Write state: performing write operation

    // State registers for the state machine
    reg [1:0] current_state, next_state;

    // Memory initialization block
    // Sets all memory locations to zero at startup
    integer i;
    initial begin
        for (i = 0; i < 2**ADDR_WIDTH; i = i + 1)
            memory[i] = {DATA_WIDTH{1'b0}};
    end

    // Sequential logic block for state transitions and ready signal
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;    // Reset to idle state
            ready <= 1'b0;           // Clear ready signal
        end else begin
            current_state <= next_state;  // Update state
            // Set ready signal based on current state
            if (current_state == READ || current_state == WRITE)
                ready <= 1'b1;       // Assert ready during operations
            else
                ready <= 1'b0;       // Deassert ready in IDLE state
        end
    end

    // Combinational logic block for next state determination
    always @(*) begin
        next_state = current_state;  // Default: maintain current state

        case (current_state)
            IDLE: begin
                // Transition from IDLE based on enable signals
                if (write_enable)
                    next_state = WRITE;
                else if (read_enable)
                    next_state = READ;
            end
            WRITE: begin
                next_state = IDLE;   // One-cycle write operation
            end
            READ: begin
                next_state = IDLE;   // One-cycle read operation
            end
        endcase
    end

    // Memory operation block
    always @(posedge clk) begin
        if (current_state == WRITE) begin
            memory[address] <= write_data;  // Write data to specified address
        end
        if (current_state == READ) begin
            read_data <= memory[address];   // Read data from specified address
        end
    end

endmodule