`timescale 1ns / 1ps    // Defines simulation time unit (1ns) and precision (1ps)

module tb_MemoryController;    // Testbench module declaration (no ports needed)

    // Parameter definitions matching the memory controller
    parameter DATA_WIDTH = 32;     // Sets data width to 32 bits
    parameter ADDR_WIDTH = 16;     // Sets address width to 16 bits

    // Testbench signal declarations
    reg clk;                       // Clock signal (reg since testbench drives it)
    reg reset;                     // Reset signal
    reg write_enable;              // Write enable control signal
    reg read_enable;               // Read enable control signal
    reg [ADDR_WIDTH-1:0] address;  // Address bus
    reg [DATA_WIDTH-1:0] write_data;    // Data to be written
    wire [DATA_WIDTH-1:0] read_data;    // Data read from memory (wire since DUT drives it)
    wire ready;                         // Ready signal from memory controller

    // Instantiate the Memory Controller (Unit Under Test - UUT)
    MemoryController #(
        .DATA_WIDTH(DATA_WIDTH),        // Pass data width parameter
        .ADDR_WIDTH(ADDR_WIDTH)         // Pass address width parameter
    ) uut (                            // 'uut' is instance name (unit under test)
        .clk(clk),                     // Connect testbench signals to UUT ports
        .reset(reset),
        .write_enable(write_enable),
        .read_enable(read_enable),
        .address(address),
        .write_data(write_data),
        .read_data(read_data),
        .ready(ready)
    );

    // Clock generation block
    initial clk = 0;                   // Initialize clock to 0
    always #5 clk = ~clk;              // Toggle clock every 5ns (10ns period = 100MHz)

    // Test sequence block
    initial begin
        // Initialize all signals to known states
        reset = 1;                     // Assert reset
        write_enable = 0;              // Disable write operations
        read_enable = 0;               // Disable read operations
        address = 0;                   // Clear address
        write_data = 0;                // Clear write data

        #20 reset = 0;                 // Release reset after 20ns

        // Test Case 1: Write to address 1
        @(posedge clk);               // Wait for positive clock edge
        write_enable = 1;             // Enable write operation
        address = 16'h0001;           // Set address to 1
        write_data = 32'hDEADBEEF;    // Set test data pattern
        @(posedge clk);               // Wait for next clock edge
        write_enable = 0;             // Disable write operation
        wait(ready);                  // Wait for ready signal from controller

        // Test Case 2: Read from address 1
        @(posedge clk);               // Synchronize to clock
        read_enable = 1;              // Enable read operation
        address = 16'h0001;           // Read from same address
        @(posedge clk);               // Wait for clock edge
        read_enable = 0;              // Disable read operation
        wait(ready);                  // Wait for ready signal

        // Verify read data matches written data
        @(posedge clk);
        if (read_data == 32'hDEADBEEF)    // Compare read data with expected
            $display("TEST PASSED: Address 1 matches DEADBEEF.");
        else
            $display("TEST FAILED: Address 1 mismatch.");

        // Test Case 3: Write to address 2
        @(posedge clk);
        write_enable = 1;
        address = 16'h0002;           // Write to different address
        write_data = 32'hCAFEBEEF;    // Different test pattern
        @(posedge clk);
        write_enable = 0;
        wait(ready);

        // Test Case 4: Read from address 2
        @(posedge clk);
        read_enable = 1;
        address = 16'h0002;           // Read from address 2
        @(posedge clk);
        read_enable = 0;
        wait(ready);

        // Verify second read data
        @(posedge clk);
        if (read_data == 32'hCAFEBEEF)    // Compare with expected value
            $display("TEST PASSED: Address 2 matches CAFEBEEF.");
        else
            $display("TEST FAILED: Address 2 mismatch.");

        $finish;                      // End simulation
    end

endmodule