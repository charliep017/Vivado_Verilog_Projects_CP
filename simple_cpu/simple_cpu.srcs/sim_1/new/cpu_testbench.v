// Set the time scale for simulation - 1 picosecond time unit with 1 picosecond precision
`timescale 1ps / 1ps

// Testbench module definition - no external ports needed as this is a testbench
module cpu_testbench;
    // Declare test signals that will connect to the CPU
    reg clk;              // Clock signal - controlled by testbench
    reg rst;              // Reset signal - controlled by testbench
    wire [3:0] acc;       // Accumulator output - monitored from CPU
    wire [3:0] pc;        // Program Counter output - monitored from CPU
    wire [7:0] instr;     // Current instruction output - monitored from CPU
    wire halt;            // Halt signal output - monitored from CPU
    
    // Instantiate the CPU module under test (UUT)
    simple_cpu uut (
        .clk(clk),        // Connect testbench clock to CPU clock
        .rst(rst),        // Connect testbench reset to CPU reset
        .acc(acc),        // Connect CPU accumulator output
        .pc(pc),          // Connect CPU program counter output
        .instr(instr),    // Connect CPU instruction output
        .halt(halt)       // Connect CPU halt signal output
    );
    
    // Clock Generation Block
    // Creates a clock signal that toggles every 10 time units
    // This results in a clock period of 20 time units (10 high + 10 low)
    always #10 clk = ~clk;
    
    // Main testbench stimulus procedure
    initial begin 
        // Initialize testbench signals
        clk = 0;          // Start with clock at 0
        rst = 1;          // Start with reset asserted (active high)
        
        #10              // Wait for 10 time units
        rst = 0;         // De-assert reset to let CPU start executing
        
        // Let simulation run for 100 more time units to observe CPU execution
        // This should be enough time to see the complete program execution
        #100 
        $finish;         // End the simulation
    end     
    
endmodule