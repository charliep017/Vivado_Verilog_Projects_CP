`timescale 1ns / 1ps
// Parameterized ALU Design
module alu #(
    parameter DATA_WIDTH = 32
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [DATA_WIDTH-1:0]   a,
    input  logic [DATA_WIDTH-1:0]   b,
    input  logic [1:0]              op_code,
    output logic [DATA_WIDTH-1:0]   result,
    output logic                    error
);

    // Operation encoding
    localparam ADD = 2'b00;
    localparam SUB = 2'b01;
    localparam MUL = 2'b10;
    localparam DIV = 2'b11;

    // Internal signals
    logic [DATA_WIDTH-1:0] mul_result;
    logic [DATA_WIDTH-1:0] div_result;
    
    // Combinational logic for operations
    always_comb begin
        error = 1'b0;
        case(op_code)
            ADD: result = a + b;
            SUB: result = a - b;
            MUL: result = mul_result;
            DIV: begin
                if (b == 0) begin
                    result = '0;
                    error = 1'b1;
                end else begin
                    result = div_result;
                end
            end
            default: result = '0;
        endcase
    end

    // Multiplication logic
    assign mul_result = a * b;

    // Division logic
    assign div_result = a / b;

    // Assertions
    property valid_op_code;
        @(posedge clk) disable iff (!rst_n)
        op_code inside {ADD, SUB, MUL, DIV};
    endproperty

    property div_by_zero;
        @(posedge clk) disable iff (!rst_n)
        (op_code == DIV) |-> (b != 0) or error;
    endproperty

    assert_valid_op: assert property(valid_op_code)
        else $error("Invalid operation code detected!");
    
    assert_div_zero: assert property(div_by_zero)
        else $error("Division by zero without error flag!");

endmodule