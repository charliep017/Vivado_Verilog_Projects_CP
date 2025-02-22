// Define timescale for simulation
`timescale 1ns / 1ps

// Package declaration for ALU UVM components
package alu_pkg;
    // Import UVM package and include necessary macros
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    //----------------------------------------
    // Transaction Class
    //----------------------------------------
    // Base transaction class for ALU operations
    class alu_transaction extends uvm_sequence_item;
        // Randomizable input fields
        rand logic [31:0] a;        // First operand
        rand logic [31:0] b;        // Second operand
        rand logic [1:0]  op_code;  // Operation selector (ADD/SUB/MUL/DIV)
        
        // Non-randomizable output fields
        logic [31:0]     result;    // Operation result
        logic           error;      // Error flag (e.g., division by zero)

        // UVM automation macros for field handling
        `uvm_object_utils_begin(alu_transaction)
            `uvm_field_int(a, UVM_ALL_ON)        // Enable all UVM features for field 'a'
            `uvm_field_int(b, UVM_ALL_ON)        // Enable all UVM features for field 'b'
            `uvm_field_int(op_code, UVM_ALL_ON)  // Enable all UVM features for op_code
            `uvm_field_int(result, UVM_ALL_ON)   // Enable all UVM features for result
            `uvm_field_int(error, UVM_ALL_ON)    // Enable all UVM features for error
        `uvm_object_utils_end

        // Constraint to ensure valid operation codes (0-3)
        constraint valid_op_code {
            op_code inside {[0:3]};  // Constrains op_code to be 0,1,2,or 3
        }

        // Constructor with default name
        function new(string name = "alu_transaction");
            super.new(name);
        endfunction
    endclass

    //----------------------------------------
    // Random Sequence Class
    //----------------------------------------
    // Sequence class for generating test scenarios
    class alu_random_sequence extends uvm_sequence#(alu_transaction);
        // UVM automation macro for sequence
        `uvm_object_utils(alu_random_sequence)

        // Constructor
        function new(string name = "alu_random_sequence");
            super.new(name);
        endfunction

        // Main sequence body
        virtual task body();
            alu_transaction tx;  // Transaction handle
            
            // Test Case 1: Addition with large numbers
            tx = alu_transaction::type_id::create("tx");
            start_item(tx);
            tx.a = 32'h1234_5678;     // Set operand a
            tx.b = 32'h8765_4321;     // Set operand b
            tx.op_code = 2'b00;       // ADD operation
            finish_item(tx);
            #20;                      // Wait for 20 time units

            // Test Case 2: Subtraction with overflow condition
            tx = alu_transaction::type_id::create("tx");
            start_item(tx);
            tx.a = 32'hFFFF_FFFF;     // Maximum value
            tx.b = 32'h0000_0001;     // Subtract 1
            tx.op_code = 2'b01;       // SUB operation
            finish_item(tx);
            #20;

            // Test Case 3: Multiplication with small numbers
            tx = alu_transaction::type_id::create("tx");
            start_item(tx);
            tx.a = 32'h0000_00FF;     // 255
            tx.b = 32'h0000_00FF;     // 255
            tx.op_code = 2'b10;       // MUL operation
            finish_item(tx);
            #20;

            // Test Case 4: Normal division
            tx = alu_transaction::type_id::create("tx");
            start_item(tx);
            tx.a = 32'h1000_0000;     // Dividend
            tx.b = 32'h0000_0002;     // Divisor = 2
            tx.op_code = 2'b11;       // DIV operation
            finish_item(tx);
            #20;

            // Test Case 5: Division by zero error case
            tx = alu_transaction::type_id::create("tx");
            start_item(tx);
            tx.a = 32'h1234_5678;     // Dividend
            tx.b = 32'h0000_0000;     // Divisor = 0
            tx.op_code = 2'b11;       // DIV operation
            finish_item(tx);
            #20;

            // Generate 20 random test cases
            repeat(20) begin
                tx = alu_transaction::type_id::create("tx");
                start_item(tx);
                assert(tx.randomize());  // Randomize all fields
                finish_item(tx);
                #20;
            end
        endtask
    endclass

    //----------------------------------------
    // Driver Class
    //----------------------------------------
    // Driver class to control DUT inputs
    class alu_driver extends uvm_driver#(alu_transaction);
        `uvm_component_utils(alu_driver)
        
        virtual alu_if vif;  // Virtual interface handle

        // Constructor
        function new(string name = "alu_driver", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // Build phase - get virtual interface
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            // Get interface handle from config DB
            if(!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
                `uvm_fatal("ALU_DRIVER", "Virtual interface not found!")
        endfunction

        // Run phase - main driver logic
        virtual task run_phase(uvm_phase phase);
            forever begin
                seq_item_port.get_next_item(req);  // Get next transaction
                
                // Wait for reset to be inactive
                @(posedge vif.clk iff vif.rst_n);
                
                // Drive transaction signals to DUT
                vif.a <= req.a;
                vif.b <= req.b;
                vif.op_code <= req.op_code;
                
                // Wait for 2 clock cycles for computation
                repeat(2) @(posedge vif.clk);
                
                // Sample the results
                req.result = vif.result;
                req.error = vif.error;
                
                // Log the transaction
                `uvm_info("ALU_DRIVER", $sformatf("Drove: op=%0d a=%0h b=%0h result=%0h error=%0b", 
                    req.op_code, req.a, req.b, req.result, req.error), UVM_LOW)
                    
                seq_item_port.item_done();  // Signal completion
            end
        endtask
    endclass

    //----------------------------------------
    // Monitor Class
    //----------------------------------------
    // Monitor class to observe DUT behavior
    class alu_monitor extends uvm_monitor;
        `uvm_component_utils(alu_monitor)

        virtual alu_if vif;  // Virtual interface handle
        uvm_analysis_port#(alu_transaction) ap;  // Analysis port for scoreboard

        // Constructor
        function new(string name = "alu_monitor", uvm_component parent = null);
            super.new(name, parent);
            ap = new("ap", this);  // Create analysis port
        endfunction

        // Build phase - get virtual interface
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if(!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
                `uvm_fatal("ALU_MONITOR", "Virtual interface not found!")
        endfunction

        // Run phase - monitor DUT signals
        virtual task run_phase(uvm_phase phase);
            alu_transaction tx;
            forever begin
                @(posedge vif.clk);  // Sample at clock edge
                tx = alu_transaction::type_id::create("tx");
                // Sample all signals
                tx.a = vif.a;
                tx.b = vif.b;
                tx.op_code = vif.op_code;
                tx.result = vif.result;
                tx.error = vif.error;
                ap.write(tx);  // Send to scoreboard
            end
        endtask
    endclass

    //----------------------------------------
    // Scoreboard Class
    //----------------------------------------
    // Scoreboard class for result checking
    class alu_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(alu_scoreboard)

        // Analysis import for receiving transactions
        uvm_analysis_imp#(alu_transaction, alu_scoreboard) ap_imp;

        // Constructor
        function new(string name = "alu_scoreboard", uvm_component parent = null);
            super.new(name, parent);
            ap_imp = new("ap_imp", this);
        endfunction

        // Write function - called for each transaction
        virtual function void write(alu_transaction tx);
            logic [31:0] expected_result;
            logic expected_error;
            
            // Initialize expected values
            expected_result = 0;
            expected_error = 0;
            
            // Calculate expected results based on operation
            case(tx.op_code)
                2'b00: expected_result = tx.a + tx.b;    // ADD operation
                2'b01: expected_result = tx.a - tx.b;    // SUB operation
                2'b10: expected_result = tx.a * tx.b;    // MUL operation
                2'b11: begin                             // DIV operation
                    if(tx.b == 0) begin                  // Division by zero check
                        expected_result = '0;
                        expected_error = 1'b1;
                    end else begin
                        expected_result = tx.a / tx.b;
                        expected_error = 1'b0;
                    end
                end
                default: begin                           // Invalid operation
                    expected_result = '0;
                    expected_error = 1'b0;
                end
            endcase

            // Log debug information
            `uvm_info("ALU_SCOREBOARD", $sformatf("Operation: %0d, A: %0h, B: %0h", 
                tx.op_code, tx.a, tx.b), UVM_LOW)
            `uvm_info("ALU_SCOREBOARD", $sformatf("Expected Result: %0h, Got: %0h", 
                expected_result, tx.result), UVM_LOW)
            `uvm_info("ALU_SCOREBOARD", $sformatf("Expected Error: %0b, Got: %0b", 
                expected_error, tx.error), UVM_LOW)

            // Check results and report errors
            if(tx.result !== expected_result)
                `uvm_error("ALU_SCOREBOARD", $sformatf("Result mismatch! Op: %0d, A: %0h, B: %0h, Expected: %0h, Got: %0h", 
                    tx.op_code, tx.a, tx.b, expected_result, tx.result))
            if(tx.error !== expected_error)
                `uvm_error("ALU_SCOREBOARD", $sformatf("Error flag mismatch! Op: %0d, A: %0h, B: %0h, Expected: %0b, Got: %0b",
                    tx.op_code, tx.a, tx.b, expected_error, tx.error))
        endfunction
    endclass

    //----------------------------------------
    // Environment Class
    //----------------------------------------
    // Test environment class
    class alu_env extends uvm_env;
        `uvm_component_utils(alu_env)

        // Environment components
        alu_driver    driver;      // Driver instance
        alu_monitor   monitor;     // Monitor instance
        alu_scoreboard scoreboard; // Scoreboard instance
        uvm_sequencer#(alu_transaction) sequencer;  // Sequencer instance

        // Constructor
        function new(string name = "alu_env", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // Build phase - create components
        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            driver = alu_driver::type_id::create("driver", this);
            monitor = alu_monitor::type_id::create("monitor", this);
            scoreboard = alu_scoreboard::type_id::create("scoreboard", this);
            sequencer = uvm_sequencer#(alu_transaction)::type_id::create("sequencer", this);
        endfunction

        // Connect phase - connect components
        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            driver.seq_item_port.connect(sequencer.seq_item_export);  // Connect driver to sequencer
            monitor.ap.connect(scoreboard.ap_imp);  // Connect monitor to scoreboard
        endfunction
    endclass

    //----------------------------------------
    // Test Class
    //----------------------------------------
    // Top-level test class
    class alu_test extends uvm_test;
        `uvm_component_utils(alu_test)

        // Test components
        alu_env env;              // Environment instance
        alu_random_sequence seq;  // Sequence instance

        // Constructor
        function new(string name = "alu_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // Build phase - create environment and sequence
        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = alu_env::type_id::create("env", this);
            seq = alu_random_sequence::type_id::create("seq");
        endfunction

        // Run phase - execute test sequence
        virtual task run_phase(uvm_phase phase);
            phase.raise_objection(this);    // Prevent test from ending
            seq.start(env.sequencer);       // Start sequence
            phase.drop_objection(this);     // Allow test to end
        endtask
    endclass

endpackage