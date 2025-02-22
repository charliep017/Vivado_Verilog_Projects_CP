//Set simulation timescale
`timescale 1ns / 1ps

//Include DUT Source File - modify path according to your project structure
`include "H:/Vivado_fpga/Personal/project_6_ALU_UVM/project_6_ALU_UVM.srcs/sources_1/new/alu.sv"

module alu_tb_top;
    import uvm_pkg::*;              //IMport UVM Package
    import alu_pkg::*;              //Import ALU-specific package
    `include "uvm_macros.svh"       //Include UVM macros
    
    // Signal declarations
    logic clk;          //System flock
    logic rst_n;        //Active-low reset
    
    // Local signal monitors
    logic [31:0] a_mon;             //Monitor for operand A
    logic [31:0] b_mon;             //Monitor for operand B
    logic [1:0]  op_code_mon;       //Monitor for operation code
    logic [31:0] result_mon;        //Monitor for result
    logic        error_mon;         //Monitor for error flag
    
    // Interface instance
    alu_if intf(clk, rst_n);
    
    // DUT instance (Device Under Test)
    alu dut(
        .clk(clk),                  //Connect clock
        .rst_n(rst_n),              //Connect reset
        .a(intf.a),                 //Connect operand A
        .b(intf.b),                 //Connect operand B
        .op_code(intf.op_code),     //Connect operation code
        .result(intf.result),       //Connect result
        .error(intf.error)          //Connect error flag
    );
    
    // Monitor interface signals
    always @(posedge clk) begin
        a_mon <= intf.a;                //Sample operand A
        b_mon <= intf.b;                //Sample operand B
        op_code_mon <= intf.op_code;    //Sample operation code
        result_mon <= intf.result;      //Sample result
        error_mon <= intf.error;        //Sample error flag
    end
    
    // Clock generation
    initial begin
        clk = 0;                //Initialize clock to 0
        forever #5 clk = ~clk;  //Toggle every 5ns
    end
    
    // Reset generation
    initial begin
        rst_n = 0;                      //Assert reset
        repeat(10) @(posedge clk);      //Hold for 10 clock cycles
        rst_n = 1;                      //De-assert reset
    end

    // Debug prints and wave setup
    initial begin
        // Print interface signals
        $display("Time=%0t Interface signals:", $time);
        $display("clk=%b rst_n=%b", clk, rst_n);
        $display("a=%h b=%h op_code=%h", intf.a, intf.b, intf.op_code);
        $display("result=%h error=%b", intf.result, intf.error);
        
        // Monitor signals throughout simulation
        $monitor("Time=%0t op=%h a=%h b=%h result=%h error=%b", 
                 $time, op_code_mon, a_mon, b_mon, result_mon, error_mon);
    end

    // Test execution
    initial begin
        // Configure the interface
        uvm_config_db#(virtual alu_if)::set(null, "*", "vif", intf);
        
        // Start UVM phases
        run_test("alu_test");
    end

endmodule