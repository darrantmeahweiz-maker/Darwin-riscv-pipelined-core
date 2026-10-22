`timescale 1ns / 1ps

module address_decoder (
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
    // 0x1001_0000 - 0x1001_0FFF : 4KB DMEM
    // 0x3000_0000 - 0x3000_0004 : UART Controller
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
    // Master Response Multiplexing
    // ==========================================
    always @(*) begin
        if (sel_uart) begin
            d_rdata = uart_rdata;
            d_ready = uart_ready;
        end else if (sel_dmem) begin
            d_rdata = dmem_rdata;
            d_ready = 1'b1;         // Combinational/distributed RAM is always ready
        end else begin
            d_rdata = 32'h00000000;
            d_ready = 1'b1;         // Prevent lockup on unmapped addresses
        end
    end

endmodule