// Include UVM files
`include "C:/Xilinx/Vivado/2024.2/data/system_verilog/uvm_1.2/uvm_macros.svh"
`include "C:/Xilinx/Vivado/2024.2/data/system_verilog/uvm_1.2/xlnx_uvm_package.sv"
import uvm_pkg::*;

// FIFO interface definition
interface fifo_if;
    // Interface signals
    logic        clk;           // Clock signal
    logic        rst_n;         // Active-low reset
    logic        wr_en;         // Write enable
    logic        rd_en;         // Read enable
    logic [31:0] wr_data;       // Write data bus
    logic [31:0] rd_data;       // Read data bus
    logic        full;          // FIFO full flag
    logic        empty;         // FIFO empty flag

    // Driver clocking block - synchronizes driver operations
    clocking driver_cb @(posedge clk);
        output wr_en, rd_en, wr_data;    // Signals driven by driver
        input  rd_data, full, empty;     // Signals monitored by driver
    endclocking

    // Monitor clocking block - synchronizes monitor operations
    clocking monitor_cb @(posedge clk);
        input wr_en, rd_en, wr_data, rd_data, full, empty;    // All signals monitored
    endclocking

    // Interface modports
    modport driver (clocking driver_cb, input clk, rst_n);     // Driver access
    modport monitor (clocking monitor_cb, input clk, rst_n);   // Monitor access
endinterface