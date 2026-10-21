`timescale 1ns / 1ps

module tb_RISCV_Core();

    reg clk;
    reg rst_n; // Updated: Active-low asynchronous reset

    // ==========================================
    // Bus Interconnect Wires
    // ==========================================
    wire [31:0] i_addr;
    wire        i_req;
    wire [31:0] i_rdata;

    wire [31:0] d_addr;
    wire [31:0] d_wdata;
    wire [3:0]  d_we;
    wire        d_req;
    wire [31:0] d_rdata;

    // Memory control wires from address decoder
    wire dmem_we;
    wire dmem_oe;

    // ==========================================
    // 1. Pure Core Instantiation (DUT)
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
        .d_rdata (d_rdata)
    );

    // ==========================================
    // 2. Standalone Memory Subsystem (External to Core)
    // ==========================================
    IMEM instruction_memory (
        .A  (i_addr),
        .RD (i_rdata),
        .OE (i_req)
    );

    address_decoder addr_dec (
        .ALUResultM (d_addr),
        .MemWriteM  (|d_we),
        .WE         (dmem_we),
        .OE         (dmem_oe)
    );

    DMEM data_memory (
        .i_Clk (clk),
        .WE    (dmem_we),
        .OE    (dmem_oe),
        .BW    (d_we),
        .A     (d_addr),
        .WD    (d_wdata),
        .RD    (d_rdata)
    );

    // ==========================================
    // 3. Clock Generation (100MHz)
    // ==========================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ==========================================
    // 4. Simulation Flow Control
    // ==========================================
    initial begin
        $dumpfile("build/core_waveform.vcd");
        $dumpvars(0, tb_RISCV_Core);

        // Active-low reset: Assert at 0, de-assert to 1 after 20ns
        rst_n = 1'b0;
        #20; 
        rst_n = 1'b1;
        
        $display("========================================");
        $display(" 🚀 RISC-V EXHAUSTIVE SELF-CHECKING VERIFICATION");
        $display("========================================");

        // Extended simulation timeout
        #200000; 
        
        $display("========================================");
        $display(" 🛑 SIMULATION TIMEOUT REACHED (TEST FAILED)");
        $display("========================================");
        $finish;
    end

    // ==========================================
    // 5. Execution Monitoring & Kill-Switches
    // ==========================================
    reg [31:0] last_pc = 32'hFFFFFFFF; 
    reg [63:0] saved_mispredict_time = 0; 
    
    always @(posedge clk) begin
        // Trace PC progression once out of reset
        if (rst_n && (dut.PCF !== last_pc)) begin
            $display("Time: %0t | PC: %h | Instruction: %h", $time, dut.PCF, dut.InstrF);
            last_pc <= dut.PCF;
        end

        // Silently capture the time of the first misprediction
        if (dut.Mispredict_Flag == 1'b1 && saved_mispredict_time == 0) begin
            saved_mispredict_time <= $time;
        end

        // SMART KILL-SWITCH: Monitor the Execute Stage (PCE) to ignore ghost fetches
        // PC == 0x00000234 is the PASS_TRAP infinite loop
        if (dut.PCE == 32'h00000234) begin
            $display("========================================");
            $display(" ✅ TEST PASSED!");
            $display(" 🏁 All ISA, Hazards, and Speculation checks completed perfectly.");
            $display("    Self-Check Status Register (x4) is 0x00000000.");
            if (saved_mispredict_time > 0) begin
                $display(" 💡 [%0t] RAS Overflow/Mispredict Detected! Healing pipeline...", saved_mispredict_time);
            end
            $display("========================================");
            #10; 
            $finish;
        end 
        // PC == 0x00000230 is the FAIL_TRAP infinite loop
        else if (dut.PCE == 32'h00000230) begin
            $display("========================================");
            $display(" ❌ TEST FAILED!");
            $display(" 🚨 Firmware diverted to FAIL_TRAP.");
            $display("    A hardware evaluation produced the wrong result.");
            $display("========================================");
            #10;
            $finish;
        end
    end

endmodule