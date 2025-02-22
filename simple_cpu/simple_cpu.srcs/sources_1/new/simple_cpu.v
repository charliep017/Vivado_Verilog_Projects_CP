// Set the time scale for simulation - 1 picosecond time unit with 1 picosecond precision
`timescale 1ps / 1ps

// Main CPU module definition with input and output ports
module simple_cpu(
    input wire clk,          // Clock input for synchronous operations
    input wire rst,          // Reset signal to initialize CPU state
    output reg [3:0] acc,    // 4-bit Accumulator register - stores computation results
    output reg [3:0] pc,     // 4-bit Program Counter - keeps track of current instruction address
    output reg [7:0] instr,  // 8-bit Current instruction register - shows current instruction being executed
    output reg halt          // Halt signal - indicates when CPU has stopped
    );
    
    // Instruction Set Architecture (ISA) - Define operation codes
    parameter NOP = 4'b0000;    // No Operation - does nothing
    parameter ADD = 4'b0001;    // Add - adds immediate value to accumulator
    parameter SUB = 4'b0010;    // Subtract - subtracts immediate value from accumulator
    parameter AND = 4'b0011;    // Bitwise AND - performs AND operation with immediate value
    parameter OR  = 4'b0100;    // Bitwise OR - performs OR operation with immediate value
    parameter LDI = 4'b0101;    // Load Immediate - loads immediate value into accumulator
    parameter JMP = 4'b0110;    // Jump - changes program counter to specified address
    parameter HLT = 4'b1111;    // Halt - stops CPU execution
    
    // Memory declarations
    reg [7:0] instr_mem [15:0];  // 16x8-bit instruction memory (16 locations, each 8 bits wide)
    reg [7:0] current_instr;     // Temporary register to hold the current instruction being executed
    
    integer avoid;  // Loop variable for memory initialization
    
    // Main CPU operation block - triggered on clock edge or reset
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset condition - initialize all registers to zero
            pc <= 4'b0000;              // Reset program counter to start
            acc <= 4'b0000;             // Clear accumulator
            halt <= 4'b0000;            // Clear halt signal
            instr <= 8'b00000000;       // Clear instruction register
            current_instr <= 8'b00000000; // Clear current instruction
        end else if (!halt) begin
            // Normal operation (when not halted)
            
            // Instruction Fetch stage
            current_instr = instr_mem[pc];  // Get instruction from memory at PC location
            instr = instr_mem[pc];          // Update instruction output for external monitoring
            
            // Instruction Decode and Execute stage
            case (current_instr[7:4])       // Check opcode (upper 4 bits of instruction)
                LDI: acc <= current_instr[3:0];         // Load immediate value into accumulator
                ADD: acc <= acc + current_instr[3:0];   // Add immediate value to accumulator
                SUB: acc <= acc - current_instr[3:0];   // Subtract immediate value from accumulator
                AND: acc <= acc & current_instr[3:0];   // Bitwise AND with immediate value
                OR:  acc <= acc | current_instr[3:0];   // Bitwise OR with immediate value
                JMP: pc <= current_instr[3:0];          // Jump to address specified in immediate value
                HLT: halt <=1;                          // Set halt signal to stop CPU
            endcase
            
            // Program Counter Update stage
            pc <= pc + 1;  // Increment PC to next instruction (unless modified by JMP)
        end
    end
   
    // Initialize instruction memory with a simple program
    initial begin
        // Load the program instructions
        instr_mem[0] = 8'b01010010;     // LDI 2 - Load immediate value 2 into accumulator
        instr_mem[1] = 8'b00010011;     // ADD 3 - Add immediate value 3 to accumulator
        instr_mem[2] = 8'b00100001;     // SUB 1 - Subtract immediate value 1 from accumulator
        instr_mem[3] = 8'b11110000;     // HLT - Halt the CPU
        
        // Fill remaining memory with NOPs
        for (avoid = 4; avoid < 16; avoid = avoid + 1) begin  
            instr_mem[avoid] = 8'b00000000;   // Fill unused memory with NOP instructions
        end
    end 
    
endmodule