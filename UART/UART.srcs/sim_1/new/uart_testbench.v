`timescale 1ps / 1ps

// This testbench verifies the functionality of the UART module by:
// 1. Testing transmission of a test pattern (0xA5)
// 2. Testing reception of the same pattern
// 3. Monitoring and debugging internal signals
module UART_Testbench;

// Configuration parameters matching the UART module under test
parameter BAUD_RATE = 9600;              // Communication speed in bits/second
parameter CLOCK_FREQ = 50000000;         // System clock frequency (50MHz)
parameter DIVISOR = CLOCK_FREQ / BAUD_RATE; // Clock cycles per bit

// Testbench signal declarations
reg clk;                    // System clock signal
reg rst_n;                  // Active-low reset
reg tx_start;              // Transmission start signal
reg [7:0] tx_data;         // Data to transmit
wire tx;                   // Transmit line from UART
wire tx_ready;             // Transmitter ready indicator
reg rx;                    // Receive line to UART
wire [7:0] rx_data;        // Received data from UART
wire rx_ready;             // Receiver data ready indicator

// Instantiate the UART module under test (UUT)
// Connect all testbench signals to the UART module ports
uart uut (
    .clk(clk),
    .rst_n(rst_n),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx(tx),
    .tx_ready(tx_ready),
    .rx(rx),
    .rx_data(rx_data),
    .rx_ready(rx_ready)
);

// Clock generation block
// Creates a 50 MHz clock with 20ns period (10ns high, 10ns low)
initial begin
    clk = 0;
    forever #10 clk = ~clk;  // Toggle every 10ns (half period)
end

// Main stimulus block
// Controls the test sequence and timing
initial begin
    // Initial setup and reset phase
    rst_n = 0;            // Assert reset
    tx_start = 0;         // Initialize transmission control
    tx_data = 8'h00;      // Clear data bus
    rx = 1;               // Set RX line to idle state (high)
    #100;                 // Hold reset for 100ns
    
    // Begin test sequence
    rst_n = 1;            // Release reset
    #100;                 // Wait for stable operation

    // Test 1: Transmit Operation
    // Send test pattern 0xA5
    tx_data = 8'hA5;      // Load test pattern
    tx_start = 1;         // Request transmission
    #20 tx_start = 0;     // Pulse tx_start for one clock cycle
    
    // Wait for transmission to complete
    wait(tx_ready == 1);  // tx_ready will go high when done

    // Test 2: Receive Operation
    // Use task to send test pattern via RX line
    #100;                 // Add delay between TX and RX tests
    send_rx_data(8'hA5);  // Send same test pattern

    // Wait for reception to complete
    wait(rx_ready == 1);  // rx_ready will go high when done

    // End simulation
    #100 $finish;         // Allow time for final signals to settle
end

// Task definition for simulating serial data reception
// Generates proper timing for start bit, data bits, and stop bit
task send_rx_data(input [7:0] data);
    integer i;
    begin
        // Generate start bit
        rx = 0;                    // Start bit is always 0
        #(DIVISOR * 20);          // Hold for one bit period

        // Send each data bit
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i];         // Send each bit, LSB first
            #(DIVISOR * 20);      // Hold for one bit period
        end

        // Generate stop bit
        rx = 1;                   // Stop bit is always 1
        #(DIVISOR * 20);         // Hold for one bit period
    end
endtask

// Simulation timeout watchdog
// Prevents infinite simulation if something goes wrong
initial begin
    #5000000               // Set maximum simulation time
    
    $display("Simulation Timeout: Ending simulation at time %0t", $time);
    $finish;
end

// Debug monitoring block
// Displays important signals on each clock cycle
always @(posedge clk) begin
    if (rst_n) begin  // Only monitor after reset is released
        // Display current state of key signals
        $display("Time: %0t | TX State: %b | TX Bit Count: %d | TX Ready: %b | RX Data: %h | RX Ready: %b",
                 $time, uut.tx_state, uut.tx_bit_count, tx_ready, rx_data, rx_ready);
        
        // Special notification when receive completes
        if (rx_ready==1) begin
                $display("RX Reset triggered at time %0t", $time);
        end         
    end
end

endmodule