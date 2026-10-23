`timescale 1ns / 1ps

module fpga_top (
    input  wire        CLOCK_50,   // Dedicated Global Clock Pin (PIN_AF14)
    input  wire [3:0]  KEY,        // KEY[0] = Reset Button (PIN_AA14)
    input  wire [9:0]  SW,         // Reserved for future control

    output wire [9:0]  LEDR,
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5,
    output wire        UART_TXD
);

    // =========================================================================
    // 1. Dedicated Global Clock Routing (Eliminates Fabric Ripple Clock Skew)
    // =========================================================================
    wire core_clk = CLOCK_50;

    // =========================================================================
    // 2. 2-Stage Reset Synchronizer (Synchronous De-assertion on core_clk)
    // =========================================================================
    reg rst_meta = 1'b0;
    reg rst_n    = 1'b0;

    always @(posedge core_clk or negedge KEY[0]) begin
        if (!KEY[0]) begin
            rst_meta <= 1'b0;
            rst_n    <= 1'b0;
        end else begin
            rst_meta <= 1'b1;
            rst_n    <= rst_meta;
        end
    end

    // =========================================================================
    // 3. Interconnect Bus Wires & Debug Telemetry
    // =========================================================================
    wire [31:0] i_addr;
    wire        i_req;
    wire [31:0] i_rdata;

    wire [31:0] d_addr;
    wire [31:0] d_wdata;
    wire [3:0]  d_we;
    wire        d_req;
    wire [31:0] d_rdata;
    wire        d_ready;

    wire        dmem_we;
    wire        dmem_oe;
    wire [31:0] dmem_rdata;

    wire        uart_we;
    wire        uart_re;
    wire [31:0] uart_rdata;
    wire        uart_ready;

    // Telemetry debug wires from Core
    wire        core_mispredict;
    wire [31:0] core_x4;

    // =========================================================================
    // 4. Core & Memory Subsystem Instantiation
    // =========================================================================
    RISCV_Core u_core (
        .clk               (core_clk),
        .rst_n             (rst_n),
        .i_addr            (i_addr),
        .i_req             (i_req),
        .i_rdata           (i_rdata),
        .d_addr            (d_addr),
        .d_wdata           (d_wdata),
        .d_we              (d_we),
        .d_req             (d_req),
        .d_rdata           (d_rdata),
        .d_ready           (d_ready),
        .o_mispredict_flag (core_mispredict), // Explicit synthesizable port
        .o_debug_x4        (core_x4)          // Explicit synthesizable port
    );

    IMEM u_imem (
        .A  (i_addr),
        .RD (i_rdata),
        .OE (i_req)
    );

    address_decoder u_bus (
        .clk        (core_clk),
        .rst_n      (rst_n),
        .d_addr     (d_addr),
        .d_wdata    (d_wdata),
        .d_we       (d_we),
        .d_req      (d_req),
        .d_rdata    (d_rdata),
        .d_ready    (d_ready),
        .dmem_we    (dmem_we),
        .dmem_oe    (dmem_oe),
        .dmem_rdata (dmem_rdata),
        .uart_we    (uart_we),
        .uart_re    (uart_re),
        .uart_rdata (uart_rdata),
        .uart_ready (uart_ready)
    );

    DMEM u_dmem (
        .i_Clk (core_clk),
        .WE    (dmem_we),
        .OE    (dmem_oe),
        .BW    (d_we),
        .A     (d_addr),
        .WD    (d_wdata),
        .RD    (dmem_rdata)
    );

    uart_tx #(
        .CLK_FREQ  (50_000_000), // Matches 50 MHz Global Clock
        .BAUD_RATE (115_200)
    ) u_uart (
        .clk        (core_clk),
        .rst_n      (rst_n),
        .d_addr     (d_addr),
        .d_wdata    (d_wdata),
        .uart_we    (uart_we),
        .uart_re    (uart_re),
        .uart_rdata (uart_rdata),
        .uart_ready (uart_ready),
        .tx_pin     (UART_TXD)
    );

    // =========================================================================
    // 5. Diagnostics & Status Outputs
    // =========================================================================
    reg mispredict_latched = 1'b0;
    reg test_passed_latched = 1'b0;
    reg test_failed_latched = 1'b0;

    always @(posedge core_clk or negedge rst_n) begin
        if (!rst_n) begin
            mispredict_latched  <= 1'b0;
            test_passed_latched <= 1'b0;
            test_failed_latched <= 1'b0;
        end else begin
            if (core_mispredict) begin
                mispredict_latched <= 1'b1;
            end
            if ((i_addr == 32'h00000378) && (core_x4 == 32'h00000000)) begin
                test_passed_latched <= 1'b1;
            end
            if (i_addr == 32'h00000358) begin
                test_failed_latched <= 1'b1;
            end
        end
    end

    // Lock HEX display onto terminal address once reached so digits do not blur
    wire [15:0] display_pc = test_passed_latched ? 16'h0378 :
                             test_failed_latched ? 16'h0358 : i_addr[15:0];

    assign LEDR[0]   = rst_n;
    assign LEDR[1]   = ~uart_ready;
    assign LEDR[2]   = mispredict_latched;
    assign LEDR[7:3] = 5'b00000;
    assign LEDR[8]   = test_failed_latched; // Lights up if core hits FAIL_TRAP (0x0358)
    assign LEDR[9]   = test_passed_latched; // Lights up solid when core hits PASS_LOOP (0x0378)

    // Display lower 16 bits of PC on HEX0 - HEX3
    hex_digit_decoder seg0 (.nibble(display_pc[3:0]),   .hex(HEX0));
    hex_digit_decoder seg1 (.nibble(display_pc[7:4]),   .hex(HEX1));
    hex_digit_decoder seg2 (.nibble(display_pc[11:8]),  .hex(HEX2));
    hex_digit_decoder seg3 (.nibble(display_pc[15:12]), .hex(HEX3));

    // Display lowest byte of status register x4 on HEX4 - HEX5
    hex_digit_decoder seg4 (.nibble(core_x4[3:0]),  .hex(HEX4));
    hex_digit_decoder seg5 (.nibble(core_x4[7:4]),  .hex(HEX5));

endmodule

module hex_digit_decoder (
    input  wire [3:0] nibble,
    output reg  [6:0] hex
);
    always @(*) begin
        case (nibble)
            4'h0: hex = 7'b1000000;
            4'h1: hex = 7'b1111001;
            4'h2: hex = 7'b0100100;
            4'h3: hex = 7'b0110000;
            4'h4: hex = 7'b0011001;
            4'h5: hex = 7'b0010010;
            4'h6: hex = 7'b0000010;
            4'h7: hex = 7'b1111000;
            4'h8: hex = 7'b0000000;
            4'h9: hex = 7'b0010000;
            4'hA: hex = 7'b0001000;
            4'hB: hex = 7'b0000011;
            4'hC: hex = 7'b1000110;
            4'hD: hex = 7'b0100001;
            4'hE: hex = 7'b0000110;
            4'hF: hex = 7'b0001110;
            default: hex = 7'b1111111;
        endcase
    end
endmodule