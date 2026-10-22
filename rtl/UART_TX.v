`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_FREQ  = 10_000_000,  // Adjust to your actual core clock (e.g., 10MHz or 50MHz)
    parameter BAUD_RATE = 115_200
)(
    input  wire        clk,
    input  wire        rst_n,

    // Bus Interface
    input  wire [31:0] d_addr,
    input  wire [31:0] d_wdata,
    input  wire        uart_we,
    input  wire        uart_re,
    output reg  [31:0] uart_rdata,
    output wire        uart_ready,

    // Physical Serial Pin to DE1-SoC USB-UART bridge
    output reg         tx_pin
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // FSM States
    localparam STATE_IDLE  = 2'b00;
    localparam STATE_START = 2'b01;
    localparam STATE_DATA  = 2'b10;
    localparam STATE_STOP  = 2'b11;

    reg [1:0]  state       = STATE_IDLE;
    reg [15:0] clk_cnt     = 16'd0;
    reg [2:0]  bit_idx     = 3'd0;
    reg [7:0]  tx_shift    = 8'h00;

    wire is_data_reg   = (d_addr == 32'h30000000);
    wire is_status_reg = (d_addr == 32'h30000004);
    wire tx_busy       = (state != STATE_IDLE);

    // If writing while busy, stall the CPU. Otherwise, acknowledge immediately.
    assign uart_ready = (uart_we && is_data_reg && tx_busy) ? 1'b0 : 1'b1;

    // Bus Read Multiplexing
    always @(*) begin
        if (uart_re && is_status_reg) begin
            uart_rdata = {31'b0, tx_busy}; // bit 0 = 1 if busy, 0 if ready
        end else begin
            uart_rdata = 32'h00000000;
        end
    end

    // UART Transmitter State Machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= STATE_IDLE;
            clk_cnt  <= 16'd0;
            bit_idx  <= 3'd0;
            tx_shift <= 8'h00;
            tx_pin   <= 1'b1; // Idle high
        end else begin
            case (state)
                STATE_IDLE: begin
                    tx_pin  <= 1'b1;
                    clk_cnt <= 16'd0;
                    bit_idx <= 3'd0;
                    if (uart_we && is_data_reg && !tx_busy) begin
                        tx_shift <= d_wdata[7:0];
                        state    <= STATE_START;
                    end
                end

                STATE_START: begin
                    tx_pin <= 1'b0; // Start bit = 0
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end else begin
                        clk_cnt <= 16'd0;
                        state   <= STATE_DATA;
                    end
                end

                STATE_DATA: begin
                    tx_pin <= tx_shift[bit_idx]; // LSB first
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end else begin
                        clk_cnt <= 16'd0;
                        if (bit_idx < 3'd7) begin
                            bit_idx <= bit_idx + 1'b1;
                        end else begin
                            bit_idx <= 3'd0;
                            state   <= STATE_STOP;
                        end
                    end
                end

                STATE_STOP: begin
                    tx_pin <= 1'b1; // Stop bit = 1
                    if (clk_cnt < CLKS_PER_BIT - 1) begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end else begin
                        clk_cnt <= 16'd0;
                        state   <= STATE_IDLE;
                    end
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule