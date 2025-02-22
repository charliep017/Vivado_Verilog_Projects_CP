`timescale 1ns/1ps    // Define simulation timescale
// Include necessary files
`include "H:/Vivado_fpga/PROJECTS/FIFO_UVM/FIFO_UVM.srcs/sources_1/new/fifo_if.sv"
`include "H:/Vivado_fpga/PROJECTS/FIFO_UVM/FIFO_UVM.srcs/sim_1/new/sync_fifo.sv"

// Disable DPI and XML parser for UVM (optimization)
`define UVM_NO_DPI
`define UVM_NO_XML_PARSER
`include "uvm_macros.svh"

module fifo_tb_top;    // Top-level testbench module
    // Import required packages
    import uvm_pkg::*;
    import fifo_pkg::*;
    import fifo_test_pkg::*;

    // Clock and reset signals
    bit clk;
    bit rst_n;

    // Clock generation (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;    // Toggle every 5ns
    end

    // Reset generation
    initial begin
        rst_n = 0;        // Assert reset
        #50 rst_n = 1;    // Deassert after 50ns
    end

    // Interface instantiation
    fifo_if fifo_vif();

    // DUT (Device Under Test) instantiation
    sync_fifo #(
        .DEPTH(16),        // FIFO depth parameter
        .DATA_WIDTH(32)    // Data width parameter
    ) dut (
        // Connect DUT ports to interface signals
        .clk(fifo_vif.clk),
        .rst_n(fifo_vif.rst_n),
        .wr_en(fifo_vif.wr_en),
        .rd_en(fifo_vif.rd_en),
        .wr_data(fifo_vif.wr_data),
        .rd_data(fifo_vif.rd_data),
        .full(fifo_vif.full),
        .empty(fifo_vif.empty)
    );

    // Connect clock and reset to interface
    assign fifo_vif.clk = clk;
    assign fifo_vif.rst_n = rst_n;

    // Test execution
    initial begin
        // Set virtual interface in config DB
        uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", fifo_vif);
        run_test("fifo_random_test");    // Start UVM test
    end

    // Waveform dump and monitoring
    initial begin
        $dumpfile("dump.vcd");           // Create VCD file
        $dumpvars(0, fifo_tb_top);       // Dump all variables

        // Monitor and display key signals
        $monitor("Time=%0t rst_n=%0b wr_en=%0b rd_en=%0b wr_data=%0h rd_data=%0h full=%0b empty=%0b",
                 $time, rst_n, fifo_vif.wr_en, fifo_vif.rd_en, 
                 fifo_vif.wr_data, fifo_vif.rd_data, 
                 fifo_vif.full, fifo_vif.empty);
    end
endmodule