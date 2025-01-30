module store_instruction (
    input  wire        clk,
    input  wire        reset,
    input  wire        store_en,
    input  wire [15:0] addr,
    input  wire [15:0] store_data,
    input  wire        store_commit,
    output reg  [15:0] memory_write_data,
    output reg  [15:0] memory_write_addr,
    output reg         memory_write_en
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            memory_write_en <= 0;
        end else if (store_en && store_commit) begin
            memory_write_addr <= addr;
            memory_write_data <= store_data;
            memory_write_en <= 1;  // Store to memory when commit is received
        end else begin
            memory_write_en <= 0;
        end
    end
endmodule
