// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
//----------------------------------------------------------------------------
// lesReservationStation_v    von Neumann    Memory Mapped I/O-Ps - top 16 locations
//----------------------------------------------------------------------------
`define SIMULATION // REMOVE FOR FPGA EMULATION!


module les4675ReservationStation_v (
input             reset,    // Reset, implemented with push-button on FPGA
input             clk     , // Clock, implemented with Oscillator on FPGA
input      [ 4:0] SW_pin        , // Four switches and remaining push-button
output reg [ 7:0] Display_pin     // 8 LEDs
);

    // Program Counter Signals
    reg [15:0] pc;
    wire [15:0] instruction;
    wire [11:0] next_pc;
    wire jump_taken;

    // Execution Unit Signals
    wire [15:0] Ri, Rj;
    wire [15:0] rob_write_data;
    wire [4:0]  rob_entry;
    wire        rob_write_en;
    wire [11:0] mm_addr;
    wire [15:0] mem_write_data, mem_read_data;
    wire        mem_write_en;
    wire        load_en, store_en;

    // Reorder Buffer Signals
    wire [15:0] commit_data;
    wire [4:0]  commit_reg;
    wire        commit_en;

	wire Clock_not;
    not clock_inverter ( Clock_not, clk ); // Using a language primative so timing analyzer can recognize the derived clock

    // - Instantiating only 1KWord memories to save resources; (2^10)
    // - I could instantiate up to 64KWords. (2^16)
    // - Both memories are clock synchronous i.e., the address and input data are evaluated on a positive clock edge 
    // - Note that we are using inverted clocks
    // - No rom because of Von
    `ifdef NOCACHE
    lesRES_ram_v my_ram (
        .address    ( mm_addr      [11:0] ), // input
        .clock      ( Clock_not         ), // input
        .data       ( MM_in      [15:0] 	), // input
        .wren       ( WR_DM             ), // input
        .q          ( MM_out     [15:0] )  // output
    );
    `else
    wire Done;
    les_cache_2w my_cache(
        .Resetn      ( reset             ), // input
        .MEM_address ( mm_addr [11:0] ), // input   // Address coming from the CPU
        .MEM_in      ( mem_write_data      [15:0] ), // input   // Write-Back data from the CPU
        .WR          ( mem_write_en                 ), // input   // Write-Enable from the CPU
        .Clock       ( Clock_not             ), // input
        .MEM_out     ( mem_read_data     [15:0] ), // output  // Data Stored at the Address pointed to by MEM_address
        .Done        ( Done               )  // output  // Data out is valid
    );

    `endif

    // Instantiate Register File
    // Does data fetching inside
    register_file REGFILE (
        .clk(clk),
        .reset(reset),
        .read_addr1(instruction[9:5]), 
        .read_addr2(instruction[4:0]),
        .read_data1(Ri),
        .read_data2(Rj),
        .commit_data(commit_data),
        .commit_reg(commit_reg),
        .commit_en(commit_en)
    );
    // Instantiate Memory Buffer (Handles all memory accesses)
    // Acts as my IF
    memory_buffer LSQ (
        .clk(clk),
        .reset(reset),
        .load_en(load_en),
        .store_en(store_en),
        .mm_addr(mm_addr),
        .store_data(mem_write_data),
        .pc_fetch_en(1'b1),  // Always fetching next instruction
        .pc_addr(pc),
        .instruction(instruction),
        .load_data(mem_read_data)
    );

    // Instantiate Execution Unit (Handles all instruction execution)
    // Acts as my EXE
    execution_unit EXEC (
        .clk(clk),
        .reset(reset),
        .instruction(instruction),
        .pc(pc),
        .Ri(Ri),
        .Rj(Rj),
        .rob_write_data(rob_write_data),
        .rob_entry(rob_entry),
        .rob_write_en(rob_write_en),
        .mm_addr(mm_addr),
        .mem_write_data(mem_write_data),
        .mem_read_data(mem_read_data),
        .mem_write_en(mem_write_en),
        .next_pc(next_pc),
        .jump_taken(jump_taken),
        .load_en(load_en),
        .store_en(store_en)
    );

    // Instantiate Reorder Buffer (Commits executed instructions in order)
    // Acts as my WB/MEM
    reorder_buffer ROB (
        .clk(clk),
        .reset(reset),
        .rob_write_data(rob_write_data),
        .rob_entry(rob_entry),
        .rob_write_en(rob_write_en),
        .commit_data(commit_data),
        .commit_reg(commit_reg),
        .commit_en(commit_en)
    );

    // Program Counter (PC) with Branch Handling
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 16'b0;
        else if (jump_taken)
            pc <= next_pc;  // Branch target
        else
            pc <= pc + 16'b1;    // Increment PC
    end

endmodule
