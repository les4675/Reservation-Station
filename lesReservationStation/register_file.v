module register_file (
    input  wire        clk,
    input  wire        reset,
    
    // Register Read Interface
    input  wire [4:0]  read_addr1, read_addr2,  // 5-bit addresses for 32 registers
    output wire  [15:0] read_data1, read_data2,
    
    // ROB Commit Interface
    input  wire [15:0] commit_data,
    input  wire [4:0]  commit_reg,  // 5-bit address to support 32 registers
    input  wire        commit_en
);

    reg [15:0] registers[31:0];  // 32 16-bit registers

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            integer i;
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 16'b0;
        end else if (commit_en) begin
            registers[commit_reg] <= commit_data;
        end
    end
		
    assign read_data1 = registers[read_addr1];
    assign read_data2 = registers[read_addr2];

endmodule
