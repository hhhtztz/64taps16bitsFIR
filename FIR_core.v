`timescale 1us/1ns

module FIR_core(
    input clk, // faster clock 10ns rd
    input clk1, // slower clock 10000ns wr
    input rstn, // reset
    input [15:0] cin, // coefficient input
    input [$clog2(64)-1:0] caddr, // coefficient address
    input cload, // coefficient load
    input valid_in, // input enable
    input [15:0] input_data, // input data
    output reg valid_out, // output enable
    output [15:0] output_data // output data
);

    // FSM State Definitions
    localparam IDLE = 3'b000;
    localparam LOAD_COEFFICIENTS = 3'b001;
    localparam READ_FIFO = 3'b010;
    localparam READ_MEM = 3'b011; //3
    localparam PROCESS = 3'b100;
    localparam OUTPUT = 3'b101;
    localparam SHIFT = 3'b110;

    // FSM Registers
    reg [2:0] state;
    reg [2:0] next_state;

//wires and regs
//for FIFO
    reg wr_en;
    reg rd_en;
    wire [15:0] FIFO_out;
    wire full;
    wire empty;
//for CMEM
    reg crd;
    //reg [$clog2(64)-1:0] addr;
    wire [15:0] CMEM_OUT;
    wire readco_done;
//for IMEM
    reg start;         
    reg shift_enable;  //shift enable signal
    wire [15:0] IMEM_OUT;
    wire shift_done;
    wire read_done;
//for ALU
    reg ALU_enable;
    wire done;

//FIFO
    FIFO #(
        .DATA_WIDTH(16),
        .DEPTH(4)
    ) fifo_uut(
        .clk_wr(clk1),  // faster clock
        .clk_rd(clk), // slower clock
        .rstn(rstn),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .data_in(input_data),
        .FIFO_out(FIFO_out),
        .full(full),
        .empty(empty)
    );

//CMEM
    CMEM #(
        .DATA_WIDTH(16),
        .DEPTH(64)
    ) cmem_uut(
        .clk(clk),  // faster clock
        .rstn(rstn),
        .cload(cload),
        .caddr(caddr),
        .cin(cin),
        .rd_en(crd),
        .data_out(CMEM_OUT),
        .readco_done(readco_done)
    );
    
//IMEM
    IMEM #(
        .DATA_WIDTH(16),
        .DEPTH(64)
    ) imem_uut(
        .clk(clk), // faster clock
        .rstn(rstn),
        .start(start),
        .shift_enable(shift_enable),
        .FIFO_out(FIFO_out),
        .serial_out(IMEM_OUT),
        .shift_done(shift_done),
        .read_done(read_done)
    );

//ALU 
    ALU alu_uut(
        .rstn(rstn),
        .clk2(clk),
        .enable(ALU_enable),
        .cout(CMEM_OUT),
        .x_in(IMEM_OUT),
        .done(done),
        .data_out(output_data)
    );


// FSM Control Logic
// State transition
always @(posedge clk or negedge rstn) begin
    if (~rstn)
        state <= IDLE;
    else
        state <= next_state;
end

// Next state logic
always @(*) begin
    case (state)
        IDLE: begin //initial state
            if (valid_in)begin
                next_state = LOAD_COEFFICIENTS;
            end
            else
            begin
                next_state = IDLE;
            end
        end

        LOAD_COEFFICIENTS: begin // Load coefficients state
            if (~cload)  begin// If coefficient load is done, move to next state
                next_state = READ_FIFO;
            end
            else
            begin
                next_state = LOAD_COEFFICIENTS;
            end
        end

        READ_FIFO: begin // Read FIFO state
            if (~empty)  begin// If FIFO is not full, start reading data
                next_state = SHIFT;
            end
            else begin
                next_state = READ_FIFO;
            end
        end
        
        SHIFT: begin // Shift data in IMEM
            if (shift_done)  begin// If IMEM has data to shift
                next_state = PROCESS;
            end
            else
                next_state = SHIFT;
        end

        READ_MEM: begin // Read CMEM state
            if (readco_done)  // If CMEM has data to read
                next_state = PROCESS;
            else
                next_state = READ_MEM;
        end

        PROCESS: begin // Process data state
            if (done)  // If FIFO has data to process
                next_state = OUTPUT;
            else
                next_state = PROCESS;
        end

        OUTPUT: begin // Output data state
            next_state = READ_FIFO;  // After output, return to read FIFO state
        end

        default: next_state = IDLE;
    endcase
end

// Output control signals based on FSM state
always @(*) begin
    if (~rstn) begin
        valid_out <= 0;
        wr_en <= 0;
        rd_en <= 0;
        crd <= 0;
        start <= 0;
        shift_enable <= 0;
        ALU_enable <= 0;
    end else begin
        case (state)
            IDLE: begin
                valid_out <= 0;
                wr_en <= 0;
                rd_en <= 0;
                crd <= 0;
                start <= 0;
                shift_enable <= 0;
                ALU_enable <= 0;
            end

            LOAD_COEFFICIENTS: begin
               wr_en <= 1; // Enable coefficient load
            end

            READ_FIFO: begin
                wr_en <= 1; // Enable coefficient load
                rd_en <= 1; // Enable reading from FIFO
                valid_out <= 0; // Disable output signal
            end

            SHIFT: begin
                wr_en <= 1; // Enable coefficient load
                shift_enable <= 1; // Enable shifting in IMEM
            end

            READ_MEM: begin
                wr_en <= 1; // Enable coefficient load
                start <= 1; // Start IMEM reading
                crd <= 1; // Enable reading from CMEM
                shift_enable <= 0; // Disable shifting in IMEM
            end

            PROCESS: begin
                wr_en <= 1; // Enable coefficient load
                ALU_enable <= 1; // Enable ALU
                start <= 1; // Start IMEM reading
                crd <= 1; // Enable reading from CMEM
                shift_enable <= 0; // Disable shifting in IMEM
            end

            OUTPUT: begin
                wr_en <= 1; // Enable coefficient load
                valid_out <= 1; // Enable output signal
                ALU_enable <= 0; // Disable ALU after processing
                start <=0; // Disable IMEM reading
                crd <= 0; // Disable reading from CMEM
            end

            default: begin
                valid_out <= 0;
            end
        endcase
    end
end

endmodule
