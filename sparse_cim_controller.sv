`timescale 1ns / 1ps

module sparse_cim_controller #(
    parameter int ADDR_WIDTH = 6,
    parameter int DATA_WIDTH = 8
)(
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    
    // Tells the FSM how many elements to process before stopping
    input  logic [ADDR_WIDTH-1:0] nnz_count, 

    // ==========================================
    // BRAM Interface (Driving addresses, reading data)
    // ==========================================
    output logic [ADDR_WIDTH-1:0] val_addr,  
    output logic [ADDR_WIDTH-1:0] vec_addr,  
    input  logic [DATA_WIDTH-1:0] val_data,  
    input  logic [DATA_WIDTH-1:0] col_data,  
    input  logic [DATA_WIDTH-1:0] vec_data,  

    // ==========================================
    // MAC Interface (Controlling the arithmetic)
    // ==========================================
    output logic mac_en,
    output logic mac_clr,
    output logic signed [7:0] mac_weight,
    output logic signed [7:0] mac_act,
    
    // Status flag for the testbench
    output logic done
);

    // Define the states for our FSM
    typedef enum logic [2:0] {
        IDLE,
        FETCH_PTR,
        FETCH_VEC,
        COMPUTE,
        DONE_STATE
    } state_t;

    state_t current_state, next_state;
    
    // Pointer to track which non-zero element we are currently processing
    logic [ADDR_WIDTH-1:0] current_ptr;

    // ------------------------------------------
    // Sequential Block: State Memory & Counter
    // ------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            current_ptr   <= 0;
        end else begin
            current_state <= next_state;
            
            // Only increment the pointer after a successful MAC compute
            if (current_state == COMPUTE) begin
                current_ptr <= current_ptr + 1;
            end else if (current_state == IDLE) begin
                current_ptr <= 0;
            end
        end
    end

    // ------------------------------------------
    // Combinational Block: Next State & Outputs
    // ------------------------------------------
    always_comb begin
        // Default assignments prevent inferred latches in synthesis
        next_state = current_state;
        val_addr   = current_ptr;
        vec_addr   = 0;
        mac_en     = 0;
        mac_clr    = 0;
        mac_weight = 0;
        mac_act    = 0;
        done       = 0;

        case (current_state)
            IDLE: begin
                mac_clr = 1; // Keep MAC accumulator at 0 while resting
                if (start && nnz_count > 0) begin
                    next_state = FETCH_PTR;
                end
            end

            FETCH_PTR: begin
                // Ask BRAM for the Value and the Column Index.
                val_addr = current_ptr;
                
                // We must wait here. BRAM has a 1-cycle read latency.
                next_state = FETCH_VEC; 
            end

            FETCH_VEC: begin
                // The col_data has now arrived from the BRAM.
                // We immediately use it as the address to fetch the input vector.
                vec_addr = col_data[ADDR_WIDTH-1:0];
                next_state = COMPUTE;
            end

            COMPUTE: begin
                // All data has arrived. Pass it to the MAC and enable it.
                mac_weight = val_data;
                mac_act    = vec_data;
                mac_en     = 1;
                
                // Check if we are done with the array
                if (current_ptr == nnz_count - 1) begin
                    next_state = DONE_STATE;
                end else begin
                    next_state = FETCH_PTR; // Loop back for next element
                end
            end

            DONE_STATE: begin
                done = 1;
                // Wait for the testbench/CPU to drop the start signal
                if (!start) begin 
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end

endmodule