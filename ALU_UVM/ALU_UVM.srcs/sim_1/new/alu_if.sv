interface alu_if(input logic clk, rst_n);
    // Standard interface declaration with clock and reset inputs
    
    // Input signals with default values
    logic [31:0] a;        // First operand, 32-bit width
    logic [31:0] b;        // Second operand, 32-bit width
    logic [1:0]  op_code;  // Operation code for selecting ALU function
    
    // Output signals
    logic [31:0] result;   // Result of ALU operation
    logic        error;    // Error flag (e.g., for division by zero)

    // Debug operation name mapping
    string op_name;        // String representation of current operation
    always_comb begin      // Combinational block for operation name decoding
        case(op_code)
            2'b00: op_name = "ADD";  // Addition operation
            2'b01: op_name = "SUB";  // Subtraction operation
            2'b10: op_name = "MUL";  // Multiplication operation
            2'b11: op_name = "DIV";  // Division operation
            default: op_name = "XXX"; // Invalid operation
        endcase
    end

    // Default signal assignments
    assign a = '0;         // Initialize input a to zero
    assign b = '0;         // Initialize input b to zero
    assign op_code = '0;   // Initialize operation code to zero
    
    // Runtime assertion checking
    always @(posedge clk) begin
        if (rst_n) begin   // Only check when not in reset
            assert(op_code inside {2'b00, 2'b01, 2'b10, 2'b11})  // Verify valid operation codes
                else $error("Invalid op_code detected!");
        end
    end

    // Coverage definition
    covergroup alu_cov @(posedge clk);
        // Operation code coverage
        op_code_cp: coverpoint op_code {
            bins add = {2'b00};  // Coverage bin for addition
            bins sub = {2'b01};  // Coverage bin for subtraction
            bins mul = {2'b10};  // Coverage bin for multiplication
            bins div = {2'b11};  // Coverage bin for division
        }
        
        // Input a coverage
        a_cp: coverpoint a {
            bins zero = {32'h0};                         // Zero value coverage
            bins pos = {[32'h1:32'h7FFFFFFF]};          // Positive values
            bins neg = {[32'h80000000:32'hFFFFFFFF]};   // Negative values
        }
        
        // Input b coverage
        b_cp: coverpoint b {
            bins zero = {32'h0};                         // Zero value coverage
            bins pos = {[32'h1:32'h7FFFFFFF]};          // Positive values
            bins neg = {[32'h80000000:32'hFFFFFFFF]};   // Negative values
        }
        
        // Error flag coverage
        error_cp: coverpoint error;  // Track error conditions
        
        // Cross coverage of operation and error
        op_x_error: cross op_code_cp, error_cp;  // Analyze error occurrence per operation
    endgroup

    // Coverage initialization
    initial begin
        alu_cov cov = new();  // Create coverage object instance
    end
        
endinterface