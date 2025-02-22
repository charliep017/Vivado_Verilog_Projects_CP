`ifndef FIFO_SEQUENCE    // Guard against multiple inclusion
`define FIFO_SEQUENCE

// Include necessary UVM files
`include "C:/Xilinx/Vivado/2024.2/data/system_verilog/uvm_1.2/uvm_macros.svh"
`include "C:/Xilinx/Vivado/2024.2/data/system_verilog/uvm_1.2/xlnx_uvm_package.sv"
`include "H:/Vivado_fpga/PROJECTS/FIFO_UVM/FIFO_UVM.srcs/sim_1/new/fifo_pkg.sv"

// Import packages
import uvm_pkg::*;
import fifo_pkg::*;

// Base sequence class definition
class fifo_sequence extends uvm_sequence #(fifo_trans);
    `uvm_object_utils(fifo_sequence)    // Register with factory
    
    // Constructor
    function new(input string name = "fifo_sequence");
        super.new(name);
    endfunction

    // Sequence body
    task body();
        repeat(20) begin    // Generate 20 transactions
            fifo_trans tr;
            tr = fifo_trans::type_id::create("tr");    // Create transaction
            start_item(tr);                            // Start transaction
            assert(tr.randomize());                    // Randomize transaction
            finish_item(tr);                           // End transaction
        end
    endtask
endclass

// Base test class definition
class fifo_base_test extends uvm_test;
    `uvm_component_utils(fifo_base_test)    // Register with factory
    
    // Class properties
    fifo_env env;        // Environment handle
    fifo_config cfg;     // Configuration handle
    
    // Constructor
    function new(input string name = "fifo_base_test", input uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg = fifo_config::type_id::create("cfg");    // Create config
        uvm_config_db#(fifo_config)::set(this, "*", "cfg", cfg);    // Set config in DB
        
        env = fifo_env::type_id::create("env", this);    // Create environment
    endfunction

    // Run phase
    task run_phase(uvm_phase phase);
        fifo_sequence seq;
        seq = fifo_sequence::type_id::create("seq");    // Create sequence
        phase.raise_objection(this);                    // Prevent phase from ending
        seq.start(env.agent.sequencer);                 // Start sequence
        phase.drop_objection(this);                     // Allow phase to end
    endtask
endclass
`endif