`timescale 1ns / 1ps

module mac_unit (
    input  logic signed [7:0]  weight_in,
    input  logic signed [7:0]  act_in,
    input  logic               clk,
    input  logic               rst_n,
    input  logic               clr_acc,
    input  logic               en,
    output logic signed [31:0] acc_out
);

    // Combinational logic for the product
    logic signed [15:0] product;
    
    // SystemVerilog always_comb for pure combinational logic
    always_comb begin
        product = weight_in * act_in;
    end

    // Sequential logic for the accumulator using always_ff
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_out <= 32'sd0;
        end else if (clr_acc) begin
            acc_out <= 32'sd0;
        end else if (en) begin
            acc_out <= acc_out + 32'(product); // Explicit casting for safety
        end
    end

endmodule