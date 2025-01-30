module load_instruction (
    input  wire        clk,
    input  wire        reset,
    input  wire        load_en,
    input  wire [15:0] addr,
    input  wire [15:0] memory_out,
    input  wire [15:0] forwarded_data, // Data from LSQ if available
    output reg  [15:0] load_result
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            load_result <= 16'b0;
        else if (load_en) begin
            if (forwarded_data != 16'b0) 
                load_result <= forwarded_data;  // Use LSQ forwarded data
            else
                load_result <= memory_out;  // Load from memory
        end
    end
endmodule
