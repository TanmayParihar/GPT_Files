`timescale 1ns / 1ps

module tb_mac_unit;

    // All signals use the 'logic' type in SystemVerilog
    logic signed [7:0]  weight_in;
    logic signed [7:0]  act_in;
    logic               clk;
    logic               rst_n;
    logic               clr_acc;
    logic               en;
    logic signed [31:0] acc_out;

    // Instantiate Unit Under Test (UUT) using implicit port connections
    mac_unit uut (.*); 

    // Clock generation (100 MHz, 10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize Signals
        clk       = 0;
        rst_n     = 0;
        clr_acc   = 0;
        en        = 0;
        weight_in = 8'sd0;
        act_in    = 8'sd0;

        // Apply Reset
        #15 rst_n = 1;

        // Test 1: First MAC operation (5 * 3 = 15)
        @(posedge clk);
        en        = 1;
        weight_in = 8'sd5;
        act_in    = 8'sd3;

        // Test 2: Second MAC accumulation (15 + (-4 * 2) = 7)
        @(posedge clk);
        weight_in = -8'sd4;
        act_in    = 8'sd2;

        // Test 3: Disable enable (Sparsity condition / skipped cycle)
        @(posedge clk);
        en        = 0;
        weight_in = 8'sd10; // Ignored because en = 0
        act_in    = 8'sd10;

        // Test 4: Clear accumulator
        @(posedge clk);
        clr_acc   = 1;
        
        @(posedge clk);
        clr_acc   = 0;

        #20;
        $finish;
    end

endmodule