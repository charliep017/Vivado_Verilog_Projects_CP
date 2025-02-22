// Guard against multiple inclusion of this file
`ifdef GUARD_FIFO_ENV
`define GUARD_FIFO_ENV

// Include necessary UVM files and packages
`include "C:/Xilinx/Vivado/2024.2/data/system_verilog/uvm_1.2/uvm_macros.svh"    // UVM macros definitions
`include "C:/Xilinx/Vivado/2024.2/data/system_verilog/uvm_1.2/xlnx_uvm_package.sv" // Xilinx UVM package
`include "H:/Vivado_fpga/PROJECTS/FIFO_UVM/FIFO_UVM.srcs/sim_1/new/fifo_pkg.sv"   // Project-specific FIFO package

// Import UVM and FIFO packages
import uvm_pkg::*;
import fifo_pkg::*;

// Scoreboard class definition
class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)    // Register scoreboard with factory
    
    // Analysis port to receive transactions
    uvm_analysis_imp #(fifo_trans, fifo_scoreboard) analysis_imp;
    bit [31:0] fifo_queue[$];    // Queue to store FIFO data for comparison
    
    // Constructor
    function new(input string name = "fifo_scoreboard", input uvm_component parent = null);
        super.new(name, parent);    // Call parent constructor
        analysis_imp = new("analysis_imp", this);    // Create analysis import
    endfunction

    // Write function to process transactions
    function void write(input fifo_trans tr);
        if (tr.write) begin    // If write operation
            fifo_queue.push_back(tr.data);    // Store data in queue
            `uvm_info("SCB", $sformatf("Write data: %0h", tr.data), UVM_LOW)    // Log write operation
        end else if (tr.read) begin    // If read operation
            if (fifo_queue.size() > 0) begin    // Check if queue is not empty
                bit [31:0] expected_data = fifo_queue.pop_front();    // Get expected data
                if (tr.data !== expected_data)    // Compare data
                    `uvm_error("SCB", $sformatf("Mismatch! Expected: %0h, Got: %0h", expected_data, tr.data))
                else
                    `uvm_info("SCB", $sformatf("Read data match: %0h", tr.data), UVM_LOW)
            end else
                `uvm_error("SCB", "Reading from empty FIFO!")    // Error for reading empty FIFO
        end
    endfunction
endclass

// Environment class definition
class fifo_env extends uvm_env;
    `uvm_component_utils(fifo_env)    // Register environment with factory
    
    // Component instances
    fifo_agent     agent;        // Agent handle
    fifo_scoreboard scoreboard;  // Scoreboard handle
    fifo_config     cfg;         // Configuration handle
    
    // Constructor
    function new(input string name = "fifo_env", input uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build phase to create components
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Get or create configuration
        if (!uvm_config_db#(fifo_config)::get(this, "", "cfg", cfg))
            cfg = fifo_config::type_id::create("cfg");
            
        // Create agent and scoreboard    
        agent = fifo_agent::type_id::create("agent", this);
        scoreboard = fifo_scoreboard::type_id::create("scoreboard", this);
    endfunction

    // Connect phase to establish TLM connections
    function void connect_phase(uvm_phase phase);
        agent.monitor.analysis_port.connect(scoreboard.analysis_imp);    // Connect monitor to scoreboard
    endfunction
endclass

`endif    // End of guard