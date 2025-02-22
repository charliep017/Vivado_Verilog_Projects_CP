`ifndef FIFO_TEST_CASES_SV    // Guard against multiple inclusion
`define FIFO_TEST_CASES_SV

// Disable DPI and XML parser for optimization
`define UVM_NO_DPI
`define UVM_NO_XML_PARSER

package fifo_test_pkg;    // Package for test cases
    import uvm_pkg::*;    // Import UVM package
    import fifo_pkg::*;   // Import FIFO package
    `include "uvm_macros.svh"    // Include UVM macros

    // Write-Read Sequence - Tests basic write followed by read operations
    class fifo_write_read_seq extends fifo_sequence;
        `uvm_object_utils(fifo_write_read_seq)    // Register with factory
        
        // Constructor
        function new(input string name = "fifo_write_read_seq");
            super.new(name);
        endfunction

        // Sequence body
        task body();
            // Write until full (16 writes)
            repeat(16) begin
                fifo_trans tr;
                tr = fifo_trans::type_id::create("tr");
                start_item(tr);
                assert(tr.randomize() with {write == 1; read == 0;});    // Force write operation
                finish_item(tr);
            end

            // Read until empty (16 reads)
            repeat(16) begin
                fifo_trans tr;
                tr = fifo_trans::type_id::create("tr");
                start_item(tr);
                assert(tr.randomize() with {write == 0; read == 1;});    // Force read operation
                finish_item(tr);
            end
        endtask
    endclass

    // Write-Read Test - Test class for write-read sequence
    class fifo_write_read_test extends fifo_base_test;
        `uvm_component_utils(fifo_write_read_test)
        
        // Constructor
        function new(input string name = "fifo_write_read_test", input uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // Run phase - executes the write-read sequence
        task run_phase(uvm_phase phase);
            fifo_write_read_seq seq;
            seq = fifo_write_read_seq::type_id::create("seq");
            phase.raise_objection(this);
            seq.start(env.agent.sequencer);
            phase.drop_objection(this);
        endtask
    endclass

    // Full-Empty Sequence - Tests boundary conditions
    class fifo_full_empty_seq extends fifo_sequence;
        `uvm_object_utils(fifo_full_empty_seq)
        
        // Constructor
        function new(input string name = "fifo_full_empty_seq");
            super.new(name);
        endfunction

        // Sequence body
        task body();
            // Test empty condition first
            begin
                fifo_trans tr;
                tr = fifo_trans::type_id::create("tr");
                start_item(tr);
                assert(tr.randomize() with {write == 0; read == 1;});    // Try to read when empty
                finish_item(tr);
            end

            // Fill FIFO completely
            repeat(16) begin
                fifo_trans tr;
                tr = fifo_trans::type_id::create("tr");
                start_item(tr);
                assert(tr.randomize() with {write == 1; read == 0;});    // Write until full
                finish_item(tr);
            end

            // Try to write when full
            begin
                fifo_trans tr;
                tr = fifo_trans::type_id::create("tr");
                start_item(tr);
                assert(tr.randomize() with {write == 1; read == 0;});    // Attempt write to full FIFO
                finish_item(tr);
            end
        endtask
    endclass

    // Random Sequence - Tests random operations
    class fifo_random_seq extends fifo_sequence;
        `uvm_object_utils(fifo_random_seq)
        
        // Constructor
        function new(input string name = "fifo_random_seq");
            super.new(name);
        endfunction

        // Sequence body - generates random operations
        task body();
            repeat(100) begin    // 100 random operations
                fifo_trans tr;
                tr = fifo_trans::type_id::create("tr");
                start_item(tr);
                assert(tr.randomize());    // Randomize read/write operations
                finish_item(tr);
                #10;    // Add delay between operations
            end
        endtask
    endclass

    // Random Test - Test class for random sequence
    class fifo_random_test extends fifo_base_test;
        `uvm_component_utils(fifo_random_test)
        
        // Constructor
        function new(input string name = "fifo_random_test", input uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // Run phase - executes the random sequence
        task run_phase(uvm_phase phase);
            fifo_random_seq seq;
            seq = fifo_random_seq::type_id::create("seq");
            phase.raise_objection(this);
            seq.start(env.agent.sequencer);
            phase.drop_objection(this);
        endtask
    endclass

endpackage
`endif