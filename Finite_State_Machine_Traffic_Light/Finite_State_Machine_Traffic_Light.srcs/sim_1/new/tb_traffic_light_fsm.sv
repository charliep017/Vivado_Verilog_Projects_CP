// Set simulation timescale: 1ns time unit with 1ps precision
`timescale 1ns / 1ps

// Testbench module declaration - no ports needed as it's a self-contained test environment
module tb_traffic_light_fsm;

    // Testbench signal declarations
    reg clk;                  // Clock signal - declared as reg since testbench drives it
    reg reset;               // Reset signal - declared as reg since testbench drives it
    wire [2:0] lights;       // Light outputs - declared as wire since FSM drives it
    integer scaled_time;     // Integer variable to store and display simulation time

    // Instantiate the traffic light FSM (Unit Under Test)
    traffic_light_fsm uut (   // 'uut' stands for Unit Under Test
        .clk(clk),            // Connect testbench clock to FSM clock
        .reset(reset),        // Connect testbench reset to FSM reset
        .lights(lights)       // Connect FSM lights output to testbench wire
    );

    // Clock generation block
    // Creates a 10ns period clock (5ns high, 5ns low)
    always #5 clk = ~clk;    // Toggle clock every 5ns

    // Main stimulus block
    initial begin
        // Initialize testbench signals
        clk = 0;              // Start with clock low
        reset = 1;            // Start with reset active

        // Hold reset for 10ns then release
        #10 reset = 0;        // Deactivate reset after 10ns

        // Run simulation for 1000ns then stop
        #1000 $stop;          // Stop simulation after 1000ns
    end

    // Monitoring block
    initial begin
        // Continuous monitoring loop
        forever begin
            // Convert simulation time to nanoseconds and store in integer
            scaled_time = $time / 1;  // Division by 1 ensures integer result
            
            // Display current time and light status
            // %0d formats scaled_time as decimal
            // %b formats lights as binary
            $display("Time: %0d ns | Lights: %b", scaled_time, lights);
            
            // Wait 10ns before next display update
            #10;              // Display update interval
        end
    end

endmodule