module execution_unit (
    input  wire        clk,
    input  wire        reset,
    
    input  wire [15:0] instruction,
    input  wire [15:0] pc,
    
    input  wire [15:0] Ri, Rj,
    output reg  [15:0] rob_write_data, // Data to ROB
    output reg  [4:0]  rob_entry,      // Updated to 5-bit for 32 registers
    output reg         rob_write_en,   // ROB write enable
    
    output reg  [15:0] mm_addr,
    output reg  [15:0] mem_write_data,
    input  wire [15:0] mem_read_data,
    output reg         mem_write_en,
    
    output reg  [15:0] next_pc,
    output reg         jump_taken,
    
    output reg         load_en,
    output reg         store_en

);

    parameter o = 6;
    parameter WORD_SIZE = 16;

    // Memory and Register Operations
    localparam [o-1:0] LD_IC      = 6'b000000;  // Load from memory to register
    localparam [o-1:0] ST_IC      = 6'b000001;  // Store from register to memory
    localparam [o-1:0] CPY_IC     = 6'b000010;  // Copy between registers
    localparam [o-1:0] SWAP_IC    = 6'b000011;  // Swap register contents

    // Flow Control
    localparam [o-1:0] JMP_IC     = 6'b000100;  // Unconditional jump
    localparam [o-1:0] CALL_IC    = 6'b110001;  // Function call
    localparam [o-1:0] RET_IC     = 6'b110010;  // Return from function

    // Arithmetic Operations
    localparam [o-1:0] ADD_IC     = 6'b000101;  // Add registers
    localparam [o-1:0] SUB_IC     = 6'b000110;  // Subtract registers
    localparam [o-1:0] ADDC_IC    = 6'b000111;  // Add constant
    localparam [o-1:0] SUBC_IC    = 6'b001000;  // Subtract constant
    localparam [o-1:0] MUL_IC     = 6'b001001;  // Multiply
    localparam [o-1:0] DIV_IC     = 6'b001010;  // Divide

    // Logical Operations
    localparam [o-1:0] NOT_IC     = 6'b001011;  // Bitwise NOT
    localparam [o-1:0] AND_IC     = 6'b001100;  // Bitwise AND
    localparam [o-1:0] OR_IC      = 6'b001101;  // Bitwise OR
    localparam [o-1:0] XOR_IC     = 6'b001110;  // Bitwise XOR

    // Shift and Rotate Operations
    localparam [o-1:0] SHRA_IC    = 6'b001111;  // Shift right arithmetic
    localparam [o-1:0] SHRL_IC    = 6'b010000;  // Shift right logical
    localparam [o-1:0] RRC_IC     = 6'b010001;  // Rotate right through carry
    localparam [o-1:0] RLN_IC     = 6'b010010;  // Rotate left negative
    localparam [o-1:0] RLZ_IC     = 6'b010011;  // Rotate left zero
    localparam [o-1:0] RRV_IC     = 6'b010100;  // Rotate right overflow
    localparam [o-1:0] ROTL_IC    = 6'b010101;  // Rotate left by register
    localparam [o-1:0] ROTR_IC    = 6'b010110;  // Rotate right by register

    // SIMD Vector Operations
    localparam [o-1:0] VADD_IC    = 6'b010111;  // Vector addition
    localparam [o-1:0] VSUB_IC    = 6'b011000;  // Vector subtraction



    //Jump conditions
    localparam [4:0]  JU  = 5'b00000 ; // Jump Unconditional
    localparam [4:0]  JC1 = 5'b10000 ; // Jump if Carry == 1
    localparam [4:0]  JN1 = 5'b01000 ; // Jump if Negative == 1
    localparam [4:0]  JV1 = 5'b00100 ; // Jump if Overflow == 1
    localparam [4:0]  JZ1 = 5'b00010 ; // Jump if Zero == 1
    localparam [4:0]  JC0 = 5'b01110 ; // Jump if Carry == 0
    localparam [4:0]  JN0 = 5'b10110 ; // Jump if Negative == 0
    localparam [4:0]  JV0 = 5'b11010 ; // Jump if Overflow == 0
    localparam [4:0]  JZ0 = 5'b11100 ; // Jump if Zero == 0


    wire [o-1:0] opcode = instruction[15:10];
    parameter n = 5; // number of different stations
    parameter RS_SIZE = 2;

    
    
    reg [15:0] rs_add [1:0][3:0];  // Two ALU RS with 4 entries each
    reg        rs_add_busy [1:0];
    reg 

    reg [15:0] rs_load [1:0][3:0];  // Two MEM RS with 4 entries each
    reg [1:0]  add_busy, load_busy; // Execution unit status


    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rob_write_data <= 16'b0;
            rob_entry <= 5'b0;
            rob_write_en <= 0;
            mem_write_en <= 0;
            jump_taken <= 0;
            load_en <= 0;
            store_en <= 0;
            mm_addr <= 12'b0;
            add_busy <= 2'b00;
            load_busy <= 2'b00;

        end else begin
            case (opcode)
                ADD_IC: begin // ADD
                    rob_write_data <= Ri + Rj;
                    rob_entry <= instruction[9:5]; // Destination register (now 5-bit)
                    rob_write_en <= 1;
                end
                LD_IC: begin // LOAD
                    mm_addr <= Ri;
                    rob_entry <= instruction[9:5]; // Destination register
                    load_en <= 1;
                end
                ST_IC: begin // STORE
                    mm_addr <= Ri;
                    mem_write_data <= Rj;
                    store_en <= 1;
                    mem_write_en <= 1;
                end
                JMP_IC: begin // BRANCH
                    if (Ri == 0) begin
                        next_pc <= pc + instruction[11:0];
                        jump_taken <= 1;
                    end else begin
                        jump_taken <= 0;
                    end
                end
                default: begin
                    rob_write_en <= 0;
                    load_en <= 0;
                    store_en <= 0;
                    mem_write_en <= 0;
                    jump_taken <= 0;
                end
            endcase
        end
    end

endmodule
