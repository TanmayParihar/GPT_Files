`timescale 1ns / 1ps

module sparse_cim_top #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 6,
    parameter int DEPTH      = 64
)(
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic [ADDR_WIDTH-1:0] nnz_count,
    output logic signed [31:0] final_result,
    output logic done,

    // ==========================================
    // Backdoor Write Ports for Preloading BRAMs
    // (In a real SoC, the ARM processor would drive these)
    // ==========================================
    input  logic web_val, web_col, web_vec,
    input  logic [ADDR_WIDTH-1:0] addrb,
    input  logic [DATA_WIDTH-1:0] dinb_val, dinb_col, dinb_vec
);

    // Internal wires to connect the Controller, MAC, and BRAMs
    logic [ADDR_WIDTH-1:0] val_addr, vec_addr;
    logic [DATA_WIDTH-1:0] val_data, col_data, vec_data;
    logic mac_en, mac_clr;
    logic signed [7:0] mac_weight, mac_act;

    // 1. Instantiate the Controller
    sparse_cim_controller #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) controller_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .nnz_count(nnz_count),
        .val_addr(val_addr),
        .vec_addr(vec_addr),
        .val_data(val_data),
        .col_data(col_data),
        .vec_data(vec_data),
        .mac_en(mac_en),
        .mac_clr(mac_clr),
        .mac_weight(mac_weight),
        .mac_act(mac_act),
        .done(done)
    );

    // 2. Instantiate the MAC Unit
    mac_unit mac_inst (
        .clk(clk),
        .rst_n(rst_n),
        .clr_acc(mac_clr),
        .en(mac_en),
        .weight_in(mac_weight),
        .act_in(mac_act),
        .acc_out(final_result)
    );

    // 3. Instantiate BRAM for Sparse Values (Weights)
    bram_bank #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .DEPTH(DEPTH)) bank_values (
        .clk(clk), 
        .ena(1'b1), .addra(val_addr), .douta(val_data),
        .enb(1'b1), .web(web_val),    .addrb(addrb), .dinb(dinb_val)
    );

    // 4. Instantiate BRAM for Column Indices
    bram_bank #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .DEPTH(DEPTH)) bank_col_idx (
        .clk(clk), 
        .ena(1'b1), .addra(val_addr), .douta(col_data), // Uses same read address as values
        .enb(1'b1), .web(web_col),    .addrb(addrb), .dinb(dinb_col)
    );

    // 5. Instantiate BRAM for Dense Input Vector
    bram_bank #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .DEPTH(DEPTH)) bank_vector (
        .clk(clk), 
        .ena(1'b1), .addra(vec_addr), .douta(vec_data),
        .enb(1'b1), .web(web_vec),    .addrb(addrb), .dinb(dinb_vec)
    );

endmodule