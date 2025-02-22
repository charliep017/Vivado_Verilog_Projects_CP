// Set the time scale for simulation - 1 nanosecond time unit and precision
`timescale 1ns / 1ns

// Main module declaration for the traffic light controller
module traffic_light_fsm (
    input wire clk,          // Clock input - controls the timing of state transitions
    input wire reset,        // Reset signal (active high) - returns FSM to initial state
    output reg [2:0] lights  // 3-bit output for the three lights [Red, Yellow, Green]
);

    // State encoding using 2-bit values
    parameter RED    = 2'b00;  // Binary encoding for RED state
    parameter GREEN  = 2'b01;  // Binary encoding for GREEN state
    parameter YELLOW = 2'b10;  // Binary encoding for YELLOW state

    // State registers declaration
    reg [1:0] current_state, next_state;  // 2-bit registers to hold present and next states
    reg [3:0] counter;                    // 4-bit counter for timing control (0-9)

    // Initialize lights to prevent undefined states in simulation
    initial begin
        lights = 3'b000;  // All lights start off
    end
        
    // Sequential logic block - handles state transitions and timing
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= RED;    // Force state to RED on reset
            counter <= 0;            // Reset timing counter
        end else if (counter == 4'd9) begin  // State change condition (after 10 clock cycles)
            current_state <= next_state;      // Update to next state
            counter <= 0;                     // Reset counter for next timing cycle
        end else begin
            counter <= counter + 1;           // Increment counter each clock cycle
        end
    end

    // Combinational logic block - determines next state
    always @(current_state) begin  // Sensitivity list should include current_state
        case (current_state)
            RED:    next_state = GREEN;   // Transition from RED to GREEN
            GREEN:  next_state = YELLOW;  // Transition from GREEN to YELLOW
            YELLOW: next_state = RED;     // Transition from YELLOW to RED
            default: next_state = RED;    // Safety default - go to RED if invalid state
        endcase
    end

    // Output logic block - sets light patterns based on current state
    always @(current_state) begin  // Sensitivity list should include current_state
        case (current_state)
            RED:    lights = 3'b100;  // Red light only (leftmost bit)
            GREEN:  lights = 3'b001;  // Green light only (rightmost bit)
            YELLOW: lights = 3'b010;  // Yellow light only (middle bit)
            default: lights = 3'b000; // Safety default - all lights off
        endcase
    end

endmodule