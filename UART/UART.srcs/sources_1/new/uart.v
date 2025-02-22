`timescale 1ns / 1ps

// This module implements a complete UART (Universal Asynchronous Receiver-Transmitter)
// with configurable baud rate and standard 8-N-1 format (8 data bits, No parity, 1 stop bit)
module uart(
    input wire clk,            // System clock input
    input wire rst_n,          // Active low reset (resets when signal is 0)
    input wire rx,             // Serial data input line for receiving
    output reg tx,             // Serial data output line for transmitting
    output reg tx_ready,       // High when transmitter is ready for new data
    input wire [7:0] tx_data,  // Parallel data input for transmission (8 bits)
    input wire tx_start,       // Signal to initiate transmission (active high)
    output reg [7:0] rx_data,  // Parallel data output from receiver (8 bits)
    output reg rx_ready        // High when new data has been received
);

// Configuration parameters for timing calculations
parameter BAUD_RATE = 9600;             // Communication speed in bits per second
parameter CLOCK_FREQ = 50000000;        // System clock frequency in Hz (50MHz)
parameter DIVISOR = CLOCK_FREQ / BAUD_RATE; // Clock cycles per bit for timing

// State definitions for transmitter and receiver state machines
parameter IDLE = 3'b000,     // Waiting for data or start bit
          TX_START = 3'b001, // Sending start bit
          TX_DATA = 3'b010,  // Sending data bits
          TX_STOP = 3'b011,  // Sending stop bit
          RX_IDLE = 3'b100,  // Waiting for start bit
          RX_DATA = 3'b101,  // Receiving data bits
          RX_STOP = 3'b110;  // Receiving stop bit

// Internal registers for managing transmission and reception
reg [7:0] tx_shift;         // Shift register for transmitting data
reg [7:0] rx_shift;         // Shift register for receiving data
reg [15:0] tx_clk_count;    // Counter for transmit bit timing
reg [15:0] rx_clk_count;    // Counter for receive bit timing
reg [3:0] tx_bit_count;     // Counter for tracking number of bits transmitted
reg [3:0] rx_bit_count;     // Counter for tracking number of bits received
reg [2:0] tx_state;         // Current state of transmitter state machine
reg [2:0] rx_state;         // Current state of receiver state machine

// Transmitter state machine
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all transmitter registers to their default states
        tx <= 1;            // Idle line state is high
        tx_ready <= 1;      // Ready to accept new data
        tx_clk_count <= 0;  // Reset bit timing counter
        tx_bit_count <= 0;  // Reset bit counter
        tx_state <= IDLE;   // Return to idle state
    end else begin
        case (tx_state)
            IDLE: begin
                // Wait for transmission request
                if (tx_start && tx_ready) begin
                    tx_shift <= tx_data;    // Load data into shift register
                    tx_ready <= 0;          // No longer ready for new data
                    tx_state <= TX_START;   // Move to start bit state
                end
            end
            TX_START: begin
                tx <= 0;                    // Send start bit (always 0)
                tx_clk_count <= 0;          // Reset bit timing
                tx_state <= TX_DATA;        // Prepare to send data bits
            end
            TX_DATA: begin
                // Handle bit timing
                if (tx_clk_count < DIVISOR - 1) begin
                    tx_clk_count <= tx_clk_count + 1;  // Count up to baud rate divisor
                    $display("TX_DATA Debug: tx_clk_count = %d at time %0t", tx_clk_count, $time);
                end else begin
                    tx_clk_count <= 0;      // Reset for next bit
                    tx <= tx_shift[0];      // Send current bit
                    tx_shift <= {1'b0, tx_shift[7:1]}; // Shift right for next bit
                    tx_bit_count <= tx_bit_count + 1;  // Count bits sent
                    
                    if (tx_bit_count == 7) begin
                        tx_state <= TX_STOP;  // All bits sent, prepare for stop bit
                    end
                end
            end
            TX_STOP: begin
                // Handle stop bit timing
                if (tx_clk_count < DIVISOR - 1) begin
                    tx_clk_count <= tx_clk_count + 1;
                end else begin
                    tx <= 1;                // Send stop bit (always 1)
                    tx_ready <= 1;          // Ready for next transmission
                    tx_bit_count <= 0;      // Reset bit counter
                    tx_state <= IDLE;       // Return to idle state
                end
            end
        endcase
    end
end

// Receiver state machine
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all receiver registers to their default states
        rx_ready <= 0;      // No data ready
        rx_clk_count <= 0;  // Reset bit timing counter
        rx_bit_count <= 0;  // Reset bit counter
        rx_state <= RX_IDLE;// Return to idle state
        rx_shift <= 8'b0;   // Clear shift register
    end else begin
        case (rx_state)
            RX_IDLE: begin
                rx_ready <= 0;              // Clear ready flag
                if (!rx) begin             // Detect start bit (low)
                    rx_clk_count <= 0;      // Reset bit timing
                    rx_state <= RX_DATA;    // Prepare to receive data
                end
            end
            RX_DATA: begin
                // Handle bit timing
                if (rx_clk_count < DIVISOR - 1) begin
                    rx_clk_count <= rx_clk_count + 1;
                end else begin
                    rx_clk_count <= 0;      // Reset for next bit
                    rx_shift <= {rx, rx_shift[7:1]}; // Shift in received bit
                    rx_bit_count <= rx_bit_count + 1;

                    if (rx_bit_count == 7) begin
                        rx_state <= RX_STOP;  // All bits received, check stop bit
                    end
                end
            end
            RX_STOP: begin
                if (rx) begin              // Verify stop bit is high
                    rx_data <= rx_shift;    // Store received data
                    rx_ready <= 1;          // Signal data is ready
                end
                rx_state <= RX_IDLE;       // Return to idle state
                rx_bit_count <= 0;         // Reset bit counter
            end
        endcase
    end
end

endmodule