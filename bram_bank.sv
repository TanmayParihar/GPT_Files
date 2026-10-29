`timescale 1ns / 1ps

module bram_bank #(
    // Parameters make the module reusable. We can change the width/depth 
    // without rewriting the core logic.
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 6,
    parameter int DEPTH      = 64
)(
    input  logic                  clk,
    
    // ==========================================
    // PORT A: Read-Only (Used by the Accelerator)
    // ==========================================
    input  logic                  ena,     // Enable Port A
    input  logic [ADDR_WIDTH-1:0] addra,   // Address to read from
    output logic [DATA_WIDTH-1:0] douta,   // Data output to the controller

    // ==========================================
    // PORT B: Write-Only (Used for Preloading Data)
    // ==========================================
    input  logic                  enb,     // Enable Port B
    input  logic                  web,     // Write Enable (1 = Write, 0 = Read)
    input  logic [ADDR_WIDTH-1:0] addrb,   // Address to write to
    input  logic [DATA_WIDTH-1:0] dinb     // Data to write into memory
);

    // This attribute tells Vivado synthesis to specifically use 
    // hardware Block RAM slices on the FPGA, rather than LUTs (Registers).
    (* ram_style = "block" *) logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // ------------------------------------------
    // Port A Logic (Synchronous Read)
    // ------------------------------------------
    always_ff @(posedge clk) begin
        if (ena) begin
            // Data is fetched on the rising clock edge.
            // It takes 1 cycle for douta to update.
            douta <= mem[addra];
        end
    end

    // ------------------------------------------
    // Port B Logic (Synchronous Write)
    // ------------------------------------------
    always_ff @(posedge clk) begin
        if (enb) begin
            if (web) begin
                mem[addrb] <= dinb;
            end
        end
    end

endmodule