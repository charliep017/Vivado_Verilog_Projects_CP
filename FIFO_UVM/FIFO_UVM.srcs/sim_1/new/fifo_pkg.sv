// Header guards to prevent multiple inclusion
`ifndef FIFO_PKG
`define FIFO_PKG

// Performance optimizations for UVM
`define UVM_NO_DPI          // Disable DPI functionality
`define UVM_NO_XML_PARSER   // Disable XML parsing
`include "uvm_macros.svh"   // Include UVM macros

// Package declaration
package fifo_pkg;
    import uvm_pkg::*;      // Import UVM package

    // Transaction class - defines the data structure for FIFO operations
    class fifo_trans extends uvm_sequence_item;
        rand bit [31:0] data;    // 32-bit data for FIFO
        rand bit        write;    // Write enable flag
        rand bit        read;     // Read enable flag
        
        // Register fields with UVM factory for automation
        `uvm_object_utils_begin(fifo_trans)
            `uvm_field_int(data, UVM_ALL_ON)   // Register data field
            `uvm_field_int(write, UVM_ALL_ON)   // Register write field
            `uvm_field_int(read, UVM_ALL_ON)    // Register read field
        `uvm_object_utils_end

        // Constraint to prevent simultaneous read and write
        constraint valid_ops_c {
            write != read;  // Mutually exclusive operations
        }

        // Constructor
        function new(input string name = "fifo_trans");
            super.new(name);
        endfunction
    endclass

    // Configuration class - stores FIFO parameters
    class fifo_config extends uvm_object;
        `uvm_object_utils(fifo_config)    // Register with factory

        // Configuration parameters
        int fifo_depth = 16;     // Default FIFO depth
        int data_width = 32;     // Default data width
        
        // Constructor
        function new(input string name = "fifo_config");
            super.new(name);
        endfunction
    endclass

    // Define sequencer type for FIFO transactions
    typedef uvm_sequencer #(fifo_trans) fifo_sequencer;

    // Driver class - drives transactions to DUT
    class fifo_driver extends uvm_driver #(fifo_trans);
        `uvm_component_utils(fifo_driver)    // Register with factory
        
        virtual fifo_if vif;    // Virtual interface handle
        
        // Constructor
        function new(input string name = "fifo_driver", input uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // Build phase - get virtual interface
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "Virtual interface not set for driver")
        endfunction

        // Run phase - main driver operation
        task run_phase(uvm_phase phase);
            forever begin
                seq_item_port.get_next_item(req);    // Get next transaction
                drive_transaction(req);               // Drive it to DUT
                seq_item_port.item_done();           // Signal completion
            end
        endtask

        // Drive transaction task
        task drive_transaction(fifo_trans tr);
            @(vif.driver_cb);    // Synchronize to clock
            if (tr.write) begin    // Handle write operation
                vif.driver_cb.wr_en <= 1'b1;
                vif.driver_cb.rd_en <= 1'b0;
                vif.driver_cb.wr_data <= tr.data;
            end else begin         // Handle read operation
                vif.driver_cb.wr_en <= 1'b0;
                vif.driver_cb.rd_en <= 1'b1;
            end
            @(vif.driver_cb);    // Wait one clock cycle
            // Reset control signals
            vif.driver_cb.wr_en <= 1'b0;
            vif.driver_cb.rd_en <= 1'b0;
        endtask
    endclass

    // Monitor class - observes DUT activity
    class fifo_monitor extends uvm_monitor;
        `uvm_component_utils(fifo_monitor)    // Register with factory
        
        virtual fifo_if vif;    // Virtual interface handle
        uvm_analysis_port #(fifo_trans) analysis_port;    // Port for sending transactions
        
        // Constructor
        function new(input string name = "fifo_monitor", input uvm_component parent = null);
            super.new(name, parent);
            analysis_port = new("analysis_port", this);    // Create analysis port
        endfunction

        // Build phase - get virtual interface
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "Virtual interface not set for monitor")
        endfunction

        // Run phase - monitor DUT activity
        task run_phase(uvm_phase phase);
            forever begin
                @(vif.monitor_cb);    // Synchronize to clock
                if (vif.monitor_cb.wr_en || vif.monitor_cb.rd_en) begin    // Detect transaction
                    fifo_trans tr = fifo_trans::type_id::create("tr");     // Create transaction
                    // Capture transaction details
                    tr.write = vif.monitor_cb.wr_en;
                    tr.read = vif.monitor_cb.rd_en;
                    tr.data = vif.monitor_cb.wr_en ? vif.monitor_cb.wr_data : vif.monitor_cb.rd_data;
                    analysis_port.write(tr);    // Send transaction to subscribers
                end
            end
        endtask
    endclass

    // Agent class - manages driver, monitor, and sequencer
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

        // Build phase - create components
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            monitor = fifo_monitor::type_id::create("monitor", this);    // Create monitor
            if (get_is_active() == UVM_ACTIVE) begin    // If active agent
                driver = fifo_driver::type_id::create("driver", this);      // Create driver
                sequencer = fifo_sequencer::type_id::create("sequencer", this);    // Create sequencer
            end
        endfunction

        // Connect phase - establish connections
        function void connect_phase(uvm_phase phase);
            if (get_is_active() == UVM_ACTIVE) begin    // If active agent
                driver.seq_item_port.connect(sequencer.seq_item_export);    // Connect driver to sequencer
            end
        endfunction
    endclass

    // Environment class - top-level verification component
    class fifo_env extends uvm_env;
        `uvm_component_utils(fifo_env)    // Register with factory
        
        fifo_agent  agent;    // Agent handle
        fifo_config cfg;      // Configuration handle
        
        // Constructor
        function new(input string name = "fifo_env", input uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // Build phase - create components
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            // Get or create configuration
            if (!uvm_config_db#(fifo_config)::get(this, "", "cfg", cfg))
                cfg = fifo_config::type_id::create("cfg");
                
            agent = fifo_agent::type_id::create("agent", this);    // Create agent
        endfunction
    endclass

    // Base sequence - defines basic stimulus pattern
    class fifo_sequence extends uvm_sequence #(fifo_trans);
        `uvm_object_utils(fifo_sequence)    // Register with factory
        
        // Constructor
        function new(input string name = "fifo_sequence");
            super.new(name);
        endfunction

        // Sequence body - generates transactions
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

    // Base test - defines basic test structure
    class fifo_base_test extends uvm_test;
        `uvm_component_utils(fifo_base_test)    // Register with factory
        
        fifo_env env;        // Environment handle
        fifo_config cfg;     // Configuration handle
        
        // Constructor
        function new(input string name = "fifo_base_test", input uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // Build phase - create and configure components
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            cfg = fifo_config::type_id::create("cfg");    // Create config
            uvm_config_db#(fifo_config)::set(this, "*", "cfg", cfg);    // Set config in DB
            
            env = fifo_env::type_id::create("env", this);    // Create environment
        endfunction

        // Run phase - execute test
        task run_phase(uvm_phase phase);
            fifo_sequence seq;
            seq = fifo_sequence::type_id::create("seq");    // Create sequence
            phase.raise_objection(this);                    // Prevent phase from ending
            seq.start(env.agent.sequencer);                 // Start sequence
            phase.drop_objection(this);                     // Allow phase to end
        endtask
    endclass

endpackage
`endif    // End of header guard