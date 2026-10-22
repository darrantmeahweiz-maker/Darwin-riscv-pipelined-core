`timescale 1ns / 1ps

module address_decoder (
    input  wire        clk,
    input  wire        rst_n,

    // ==========================================
    // Master Interface (From RISCV_Core D-Bus)
    // ==========================================
    input  wire [31:0] d_addr,
    input  wire [31:0] d_wdata,
    input  wire [3:0]  d_we,
    input  wire        d_req,
    output reg  [31:0] d_rdata,
    output reg         d_ready,

    // ==========================================
    // Slave 0: Data Memory (DMEM) Interface
    // ==========================================
    output wire        dmem_we,
    output wire        dmem_oe,
    input  wire [31:0] dmem_rdata,

    // ==========================================
    // Slave 1: UART Controller Interface
    // ==========================================
    output wire        uart_we,
    output wire        uart_re,
    input  wire [31:0] uart_rdata,
    input  wire        uart_ready
);

    // ==========================================
    // Memory Map Decoding
    // ==========================================
    wire sel_dmem = d_req && (d_addr >= 32'h10010000 && d_addr <= 32'h10010FFF);
    wire sel_uart = d_req && (d_addr >= 32'h30000000 && d_addr <= 32'h30000004);

    // ==========================================
    // Slave Request Routing
    // ==========================================
    assign dmem_we = sel_dmem && (|d_we);
    assign dmem_oe = sel_dmem && (d_we == 4'b0000);

    assign uart_we = sel_uart && (|d_we);
    assign uart_re = sel_uart && (d_we == 4'b0000);

    // ==========================================
    // 1-Cycle Synchronous BRAM Read Handshake
    // ==========================================
    reg dmem_read_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dmem_read_ready <= 1'b0;
        end else if (dmem_oe && !dmem_read_ready) begin
            dmem_read_ready <= 1'b1; // Data latched into BRAM output register
        end else begin
            dmem_read_ready <= 1'b0; // Ready for next access
        end
    end

    // ==========================================
    // Master Response Multiplexing
    // ==========================================
    always @(*) begin
        if (sel_uart) begin
            d_rdata = uart_rdata;
            d_ready = uart_ready;
        end else if (sel_dmem) begin
            d_rdata = dmem_rdata;
            // Writes finish in 1 cycle; Reads wait 1 cycle for synchronous BRAM output
            d_ready = dmem_oe ? dmem_read_ready : 1'b1;
        end else begin
            d_rdata = 32'h00000000;
            d_ready = 1'b1;
        end
    end

endmodule