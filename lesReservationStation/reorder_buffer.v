module reorder_buffer (
    input  wire        clk,
    input  wire        reset,
    
    // Execution Unit Interface
    input  wire [15:0] rob_write_data,
    input  wire [4:0]  rob_entry, 
    input  wire        rob_write_en,
    
    // Commit Logic
    output reg  [15:0] commit_data,
    output reg  [4:0]  commit_reg, // Updated to 5-bit
    output reg         commit_en
);

    reg [15:0] rob_data[31:0];  // 32-entry ROB
    reg [4:0]  rob_dest[31:0];  // Destination register (5-bit)
    reg        rob_valid[31:0]; // Valid bits
    reg [4:0]  head, tail;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            head <= 0;
            tail <= 0;
            commit_en <= 0;
        end else begin
            // Write new result to ROB
            if (rob_write_en) begin
                rob_data[tail] <= rob_write_data;
                rob_dest[tail] <= rob_entry;
                rob_valid[tail] <= 1;
                tail <= tail + 5'b1;
            end
            
            // Commit oldest instruction in order
            if (rob_valid[head]) begin
                commit_data <= rob_data[head];
                commit_reg <= rob_dest[head];
                commit_en <= 1;
                rob_valid[head] <= 0;
                head <= head + 5'b1;
            end else begin
                commit_en <= 0;
            end
        end
    end
endmodule
