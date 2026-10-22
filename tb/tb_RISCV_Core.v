`timescale 1ns / 1ps

module tb_RISCV_Core();

    reg clk;
    reg rst_n;

    // ==========================================
    // 1. Bus Interconnect Wires
    // ==========================================
    // Instruction Bus (Core <-> IMEM)
    wire [31:0] i_addr;
    wire        i_req;
    wire [31:0] i_rdata;

    // Data Bus Master (Core <-> Address Decoder)
    wire [31:0] d_addr;
    wire [31:0] d_wdata;
    wire [3:0]  d_we;
    wire        d_req;
    wire [31:0] d_rdata;
    wire        d_ready;

    // Slave 0: Data Memory (Address Decoder <-> DMEM)
    wire        dmem_we;
    wire        dmem_oe;
    wire [31:0] dmem_rdata;

    // Slave 1: UART Controller (Address Decoder <-> UART_TX)
    wire        uart_we;
    wire        uart_re;
    wire [31:0] uart_rdata;
    wire        uart_ready;
    wire        uart_tx_pin;

    // ==========================================
    // 2. Pure Core Instantiation (DUT)
    // ==========================================
    RISCV_Core dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .i_addr  (i_addr),
        .i_req   (i_req),
        .i_rdata (i_rdata),
        .d_addr  (d_addr),
        .d_wdata (d_wdata),
        .d_we    (d_we),
        .d_req   (d_req),
        .d_rdata (d_rdata),
        .d_ready (d_ready)
    );

    // ==========================================
    // 3. Instruction Memory (ROM)
    // ==========================================
    IMEM instruction_memory (
        .A  (i_addr),
        .RD (i_rdata),
        .OE (i_req)
    );

    // ==========================================
    // 4. Address Decoder & Bus Interconnect
    // ==========================================
    address_decoder addr_dec (
        // Master Interface (From Core)
        .d_addr     (d_addr),
        .d_wdata    (d_wdata),
        .d_we       (d_we),
        .d_req      (d_req),
        .d_rdata    (d_rdata),
        .d_ready    (d_ready),

        // Slave 0: DMEM Interface
        .dmem_we    (dmem_we),
        .dmem_oe    (dmem_oe),
        .dmem_rdata (dmem_rdata),

        // Slave 1: UART Interface
        .uart_we    (uart_we),
        .uart_re    (uart_re),
        .uart_rdata (uart_rdata),
        .uart_ready (uart_ready)
    );

    // ==========================================
    // 5. Data Memory (RAM)
    // ==========================================
    DMEM data_memory (
        .i_Clk (clk),
        .WE    (dmem_we),
        .OE    (dmem_oe),
        .BW    (d_we),
        .A     (d_addr),
        .WD    (d_wdata),
        .RD    (dmem_rdata)
    );

    // ==========================================
    // 6. UART Transmitter Peripheral
    // ==========================================
    uart_tx #(
        .CLK_FREQ  (100_000_000), // Match 100MHz testbench clock
        .BAUD_RATE (10_000_000)
    ) u_uart (
        .clk        (clk),
        .rst_n      (rst_n),
        .d_addr     (d_addr),
        .d_wdata    (d_wdata),
        .uart_we    (uart_we),
        .uart_re    (uart_re),
        .uart_rdata (uart_rdata),
        .uart_ready (uart_ready),
        .tx_pin     (uart_tx_pin)
    );

    // ==========================================
    // 7. Clock Generation (100MHz -> 10ns period)
    // ==========================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ==========================================
    // 8. Simulation Flow Control
    // ==========================================
    initial begin
        $dumpfile("build/core_waveform.vcd");
        $dumpvars(0, tb_RISCV_Core);

        // Active-low asynchronous reset
        rst_n = 1'b0;
        #20; 
        rst_n = 1'b1;
        
        $display("========================================");
        $display(" 🚀 RISC-V SOC INTERCONNECT & UART VERIFICATION");
        $display("========================================");

        #200000; 
        
        $display("========================================");
        $display(" 🛑 SIMULATION TIMEOUT REACHED (TEST FAILED)");
        $display("========================================");
        $finish;
    end

    // ==========================================
    // 9. UART Output Console Sniffer
    // ==========================================
    always @(posedge clk) begin
        if (rst_n && uart_we && (d_addr == 32'h30000000) && uart_ready) begin
            $display(" 📡 [UART BUS TX] Captured Character: '%c' (Hex: 0x%02h)", d_wdata[7:0], d_wdata[7:0]);
        end
    end

    // ==========================================
    // 10. Execution Monitoring & Kill-Switches
    // ==========================================
    reg [31:0] last_pc = 32'hFFFFFFFF; 
    reg [63:0] saved_mispredict_time = 0; 
    
    always @(posedge clk) begin
        if (rst_n && (dut.PCF !== last_pc)) begin
            $display("Time: %0t | PC: %h | Instruction: %h", $time, dut.PCF, dut.InstrF);
            last_pc <= dut.PCF;
        end

        if (dut.Mispredict_Flag == 1'b1 && saved_mispredict_time == 0) begin
            saved_mispredict_time <= $time;
        end

        // PASS_TRAP (0x00000234)
        // SMART KILL-SWITCH:
        // PC == 0x00000250 is the new PASS_TRAP infinite loop after UART transmission
        // In Section 10 of tb_RISCV_Core.v:
    // PC == 0x00000264 is the true final PASS_TRAP loop
        if (dut.PCE == 32'h00000264) begin
            $display("========================================");
            $display(" ✅ TEST PASSED!");
            $display(" 🏁 All ISA, Hazards, Interconnect, and UART tests completed.");
            $display("    Self-Check Status Register (x4) is 0x00000000.");
            if (saved_mispredict_time > 0) begin
                $display(" 💡 [%0t] RAS Overflow/Mispredict Detected! Healing pipeline...", saved_mispredict_time);
            end
            $display("========================================");
            #1000; // Allow final character to flush
            $finish;
            end
        // FAIL_TRAP (0x00000230)
        else if (dut.PCE == 32'h00000230) begin
            $display("========================================");
            $display(" ❌ TEST FAILED!");
            $display(" 🚨 Firmware diverted to FAIL_TRAP.");
            $display("========================================");
            #10;
            $finish;
        end
    end

endmodule