module memory_buffer (
    input  wire        clk,
    input  wire        reset,
    
    // Load/Store Control
    input  wire        load_en,
    input  wire        store_en,
    input  wire [11:0] mm_addr,      // Address from execution unit
    input  wire [15:0] store_data,
    
    // Program Counter Fetch
    input  wire        pc_fetch_en,
    input  wire [11:0] pc_addr,
    output reg  [15:0] instruction,  
    
    // Load/Store Outputs
    output reg  [15:0] load_data,
    output reg         store_commit
);

    // Load/Store Queue
    reg [11:0] lsq_addr[7:0];   
    reg [15:0] lsq_data[7:0];   
    reg        lsq_type[7:0];  // 0 = Load, 1 = Store
    reg [2:0]  head, tail;    

    // Load Address Register (LAR) to track Load/Store operand addresses
    reg [11:0] load_address_register;
    
    // Instruction Fetch Buffer
    reg [11:0] fetch_address;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            head <= 0;
            tail <= 0;
            store_commit <= 0;
            fetch_address <= 12'b0;
            load_address_register <= 12'b0;
        end else begin
            // Update the instruction fetch address normally
            if (pc_fetch_en) begin
                fetch_address <= pc_addr + 12'h1;  // Fetch next instruction normally
            end

            // Store Request
            if (store_en) begin
                lsq_addr[tail] <= mm_addr;  // Use execution unit address
                lsq_data[tail] <= store_data;
                lsq_type[tail] <= 1'b1; 
                tail <= tail + 3'b1;
            end

            // Load Request
            if (load_en) begin
                integer i;
                load_data = 16'b0; 
                load_address_register <= mm_addr;  // Track where the data is being loaded from
                for (i = 0; i < 8; i = i + 1) begin: load
                    if (lsq_type[i] == 1'b1 && lsq_addr[i] == mm_addr) begin
                        load_data = lsq_data[i];
                        disable load;
                    end
                end
            end

            // Instruction Fetch: Avoid fetching memory operands
            if (pc_fetch_en) begin
                if (fetch_address == load_address_register) begin
                    fetch_address <= fetch_address + 12'h1;  // Skip over memory operand location
                end
                instruction <= fetch_address;  // Normal instruction fetch
            end

            // Commit Stores In-Order
            if (lsq_type[head] == 1'b1) begin
                store_commit <= 1;
                head <= head + 3'b1;
            end else begin
                store_commit <= 0;
            end
        end
    end
endmodule
