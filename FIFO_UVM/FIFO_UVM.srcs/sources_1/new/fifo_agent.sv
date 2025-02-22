// Include necessary files
`include "C:/Xilinx/Vivado/2024.2/data/system_verilog/uvm_1.2/uvm_macros.svh"
`include "C:/Xilinx/Vivado/2024.2/data/system_verilog/uvm_1.2/xlnx_uvm_package.sv"
`include "H:/Vivado_fpga/PROJECTS/FIFO_UVM/FIFO_UVM.srcs/sim_1/new/fifo_pkg.sv"
`include "H:/Vivado_fpga/PROJECTS/FIFO_UVM/FIFO_UVM.srcs/sim_1/new/fifo_test_case.sv"

// Import packages
import uvm_pkg::*;
import fifo_pkg::*;

// Driver class definition
class fifo_driver extends uvm_driver #(fifo_trans);
    `uvm_component_utils(fifo_driver)    // Register with factory
    
    virtual fifo_if vif;    // Virtual interface handle
    
    // Constructor
    function new(input string name = "fifo_driver", input uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Get virtual interface
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set for driver")
    endfunction

    // Run phase - main driver logic
    task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);    // Get next transaction
            drive_transaction(req);               // Drive it
            seq_item_port.item_done();           // Signal completion
        end
    endtask

    // Transaction driving task
    task drive_transaction(fifo_trans tr);
        @(vif.driver_cb);    // Synchronize to clock
        if (tr.write) begin    // Write operation
            vif.driver_cb.wr_en <= 1'b1;
            vif.driver_cb.rd_en <= 1'b0;
            vif.driver_cb.wr_data <= tr.data;
        end else begin         // Read operation
            vif.driver_cb.wr_en <= 1'b0;
            vif.driver_cb.rd_en <= 1'b1;
        end
        @(vif.driver_cb);    // Wait one clock cycle
        // Reset control signals
        vif.driver_cb.wr_en <= 1'b0;
        vif.driver_cb.rd_en <= 1'b0;
    endtask
endclass

// Monitor class definition
class fifo_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_monitor)    // Register with factory
    
    virtual fifo_if vif;    // Virtual interface handle
    uvm_analysis_port #(fifo_trans) analysis_port;    // Analysis port for sending transactions
    
    // Constructor
    function new(input string name = "fifo_monitor", input uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);    // Create analysis port
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Get virtual interface
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set for monitor")
    endfunction

    // Run phase - main monitor logic
    task run_phase(uvm_phase phase);
        forever begin
            @(vif.monitor_cb);    // Synchronize to clock
            if (vif.monitor_cb.wr_en || vif.monitor_cb.rd_en) begin    // If transaction detected
                fifo_trans tr = fifo_trans::type_id::create("tr");     // Create transaction
                // Populate transaction
                tr.write = vif.monitor_cb.wr_en;
                tr.read = vif.monitor_cb.rd_en;
                tr.data = vif.monitor_cb.wr_en ? vif.monitor_cb.wr_data : vif.monitor_cb.rd_data;
                analysis_port.write(tr);    // Send transaction to subscribers
            end
        end
    endtask
endclass

// Agent class definition
class fifo_agent extends uvm_agent;
    `uvm_component_utils(fifo_agent)    // Register with factory
    
    // Component handles
    fifo_driver    driver;
    fifo_monitor   monitor;
    fifo_sequencer sequencer;
    
    // Constructor
    function new(input string name = "fifo_agent", input uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = fifo_monitor::type_id::create("monitor", this);    // Create monitor
        if (get_is_active() == UVM_ACTIVE) begin    // If active agent
            driver = fifo_driver::type_id::create("driver", this);      // Create driver
            sequencer = fifo_sequencer::type_id::create("sequencer", this);    // Create sequencer
        end
    endfunction

    // Connect phase
    function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE) begin    // If active agent
            driver.seq_item_port.connect(sequencer.seq_item_export);    // Connect driver to sequencer
        end
    endfunction
endclass