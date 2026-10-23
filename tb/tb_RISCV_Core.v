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

    // Core Diagnostic / Debug Ports
    wire        core_mispredict;
    wire [31:0] core_x4;

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
        .clk               (clk),
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
        .o_mispredict_flag (core_mispredict), // Debug port
        .o_debug_x4        (core_x4)          // Debug port: register x4 status
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
        .clk        (clk),
        .rst_n      (rst_n),
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
        .BAUD_RATE (10_000_000)   // Accelerated baud for fast simulation
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

        // Active-low asynchronous reset pulse
        rst_n = 1'b0;
        #20; 
        rst_n = 1'b1;
        
        $display("=========================================================");
        $display(" 🚀 RISC-V EXTENDED VERIFICATION (BUGS 1, 2 & 4 AUDIT)");
        $display("=========================================================");

        #300000; 
        
        $display("=========================================================");
        $display(" 🛑 SIMULATION TIMEOUT REACHED (TEST FAILED / STALLED)");
        $display(" Last PC Executed: 0x%08h | Status Register x4: 0x%08h", dut.PCE, core_x4);
        $display("=========================================================");
        $finish;
    end

    // ==========================================
    // 9. UART Output Console Sniffer (Live Stream)
    // ==========================================
    always @(posedge clk) begin
        if (rst_n && uart_we && (d_addr == 32'h30000000) && uart_ready) begin
            if (d_wdata[7:0] == 8'h0A) begin
                $display(" 📡 [UART BUS TX] Captured Character: '\\n' (Hex: 0x0a)");
            end else begin
                $display(" 📡 [UART BUS TX] Captured Character: '%c' (Hex: 0x%02h)", d_wdata[7:0], d_wdata[7:0]);
            end
        end
    end

    // ==========================================
    // 10. Execution Monitoring & Kill-Switches
    // ==========================================
    reg [31:0] last_pc = 32'hFFFFFFFF; 
    reg [63:0] saved_mispredict_time = 0; 
    
    always @(posedge clk) begin
        // Live Instruction Trace
        if (rst_n && (dut.PCF !== last_pc)) begin
            $display("Time: %0t | PC: 0x%h | Instr: 0x%h", $time, dut.PCF, dut.InstrF);
            last_pc <= dut.PCF;
        end

        // Track Speculative Recovery Events
        if (core_mispredict && saved_mispredict_time == 0) begin
            saved_mispredict_time <= $time;
        end

        // ---------------------------------------------------------------------
        // PASS KILL-SWITCH: Final infinite loop at 0x00000378
        // ---------------------------------------------------------------------
        if (dut.PCE == 32'h00000378) begin
            $display("=========================================================");
            $display(" ✅ ALL TESTS PASSED!");
            $display(" 🏁 Core successfully passed all 14 test suites:");
            $display("    - Standard RV32I Base ALU, Shifts, Branches, Memory");
            $display("    - Custom Extensions: Zmmul, Xicrc, Zbb");
            $display("    - Bug 1 Audit: No shift hijacking on slli/srli");
            $display("    - Bug 2 Audit: No false stalls or corruption on x0");
            $display("    - Bug 4 Audit: RAS stack push gating under pipeline stalls");
            $display("    - SoC Interconnect: UART flow control & bus arbitration");
            $display(" Status Register x4 = 0x%08h", core_x4);
            if (saved_mispredict_time > 0) begin
                $display(" 💡 [%0t] RAS Recovery Event verified natively.", saved_mispredict_time);
            end
            $display("=========================================================");
            #2000; // Allow remaining UART frame to finish transmitting
            $finish;
        end

        // ---------------------------------------------------------------------
        // FAIL KILL-SWITCHES: Divergence to any fail trap
        // ---------------------------------------------------------------------
        else if (dut.PCE == 32'h00000358) begin
            $display("=========================================================");
            $display(" ❌ TEST FAILED!");
            $display(" 🚨 Firmware diverted to FAIL_TRAP at PC: 0x%08h", dut.PCE);
            $display(" 🚨 Error Code Register x4: 0x%08h", core_x4);
            $display("=========================================================");
            #20;
            $finish;
        end
    end

endmodule