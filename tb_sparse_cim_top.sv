`timescale 1ns / 1ps

module tb_sparse_cim_top;

    // Parameters
    localparam int DATA_WIDTH = 8;
    localparam int ADDR_WIDTH = 6;
    
    // Signals
    logic clk;
    logic rst_n;
    logic start;
    logic [ADDR_WIDTH-1:0] nnz_count;
    logic signed [31:0] final_result;
    logic done;

    // BRAM Preload signals
    logic web_val, web_col, web_vec;
    logic [ADDR_WIDTH-1:0] addrb;
    logic [DATA_WIDTH-1:0] dinb_val, dinb_col, dinb_vec;

    // Instantiate Top Module
    sparse_cim_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (.*);

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize everything to 0
        clk = 0;
        rst_n = 0;
        start = 0;
        nnz_count = 0;
        web_val = 0; web_col = 0; web_vec = 0;
        addrb = 0;
        dinb_val = 0; dinb_col = 0; dinb_vec = 0;

        // Apply reset
        #20 rst_n = 1;
        
        // ==========================================
        // PHASE 1: Preload the BRAMs via Port B
        // ==========================================
        @(posedge clk);
        web_val = 1; web_col = 1; web_vec = 1;
        
        // Write 1st Non-Zero Element (Weight = 5, Col = 0, Vector[0] = 3)
        addrb = 0;
        dinb_val = 8'sd5; 
        dinb_col = 8'd0; 
        dinb_vec = 8'sd3; 
        @(posedge clk);

        // Write 2nd Non-Zero Element (Weight = -4, Col = 2, Vector[2] = 2)
        // Note: We are writing the vector data to address 2!
        addrb = 1;               // The CSR arrays are packed tightly (addr 1)
        dinb_val = -8'sd4;
        dinb_col = 8'd2;         // Points to index 2 in the vector
        
        // Temporarily disable vector write to jump to address 2 safely
        web_vec = 0; 
        @(posedge clk);
        
        // Now write the vector data at address 2
        web_val = 0; web_col = 0; web_vec = 1;
        addrb = 2;
        dinb_vec = 8'sd2;
        @(posedge clk);

        // Stop writing
        web_vec = 0;
        
        // ==========================================
        // PHASE 2: Start the Accelerator
        // ==========================================
        #20;
        @(posedge clk);
        nnz_count = 2; // Tell it there are 2 non-zero elements
        start = 1;
        
        // Wait for the done signal from the FSM
        wait(done == 1'b1);
        @(posedge clk);
        start = 0;
        
        // Let it rest for a moment so we can see the final waveform
        #50;
        $finish;
    end

endmodule