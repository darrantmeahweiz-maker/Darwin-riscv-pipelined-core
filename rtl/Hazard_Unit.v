module Hazard_Unit (
    // ==========================================
    // Input for Data Forwarding (EX Stage)
    // ==========================================
    input       [4:0]   Rs1E,
    input       [4:0]   Rs2E,
    input       [4:0]   RdM, RdW,
    input               RegWriteM, RegWriteW,
    input               Mispredict_Flag,

    // ==========================================
    // Input for Load-Use Stalls (ID Stage)
    // ==========================================
    input       [4:0]   Rs1D,
    input       [4:0]   Rs2D,
    input       [4:0]   RdE,
    input       [1:0]   ResultSrcE, // bit 0 detects whether EX stage is a Load

    // ==========================================
    // Input for Control Hazards (EX Stage)
    // ==========================================
    input       [1:0]   PCSrcE,     // >0 means Branch/Jump taken

    // ==========================================
    // NEW: Inputs for Bus Handshake (MEM Stage)
    // ==========================================
    input  wire         d_req,      // Core requested memory/peripheral access
    input  wire         d_ready,    // Memory/peripheral ready handshake (1=ready, 0=wait)

    // ==========================================
    // Hazard Control Outputs
    // ==========================================
    output reg  [1:0]   ForwardAE, ForwardBE,
    output reg          StallF, StallD,
    output reg          StallE, StallM, // NEW: Freeze EX & MEM when D-Bus waits
    output reg          FlushD, FlushE
);

    reg  lwStall;
    wire d_stall;

    // Data bus stall occurs when access is requested but peripheral/BRAM is not ready
    assign d_stall = d_req & ~d_ready;

    always @(*) begin
        // ----------------------------------------------------
        // 1. Data Forwarding Logic (EX Stage)
        // ----------------------------------------------------
        // Forwarding for Operand A (Rs1E)
        if (RegWriteM && (RdM != 5'b0) && (RdM == Rs1E)) begin
            ForwardAE = 2'b10;      // Forward from MEM stage
        end else if (RegWriteW && (RdW != 5'b0) && (RdW == Rs1E)) begin
            ForwardAE = 2'b01;      // Forward from WB stage
        end else begin
            ForwardAE = 2'b00;      // Default: register file output
        end

        // Forwarding for Operand B (Rs2E)
        if (RegWriteM && (RdM != 5'b0) && (RdM == Rs2E)) begin
            ForwardBE = 2'b10;      // Forward from MEM stage
        end else if (RegWriteW && (RdW != 5'b0) && (RdW == Rs2E)) begin
            ForwardBE = 2'b01;      // Forward from WB stage
        end else begin
            ForwardBE = 2'b00;      // Default: register file output
        end

        // ----------------------------------------------------
        // 2. Load-Use Hazard Detection (ID Stage)
        // ----------------------------------------------------
        if ((ResultSrcE[0] == 1'b1) && (RdE != 5'b00000) && ((RdE == Rs1D) || (RdE == Rs2D))) begin
            lwStall = 1'b1;
        end else begin
            lwStall = 1'b0;
        end

        // ----------------------------------------------------
        // 3. Pipeline Stall Routing
        // ----------------------------------------------------
        // Freeze IF and ID on either Load-Use bubble OR external memory wait
        StallF = lwStall | d_stall;
        StallD = lwStall | d_stall;

        // Freeze EX and MEM strictly on external memory wait
        StallE = d_stall;
        StallM = d_stall;

        // ----------------------------------------------------
        // 4. Pipeline Flush Routing
        // ----------------------------------------------------
        // Flush Decode stage on branch/jump or RAS mispredict,
        // but NEVER flush if the pipeline is frozen on a bus stall
        if (!d_stall && ((PCSrcE != 2'b00) || (Mispredict_Flag == 1'b1))) begin
            FlushD = 1'b1;
        end else begin
            FlushD = 1'b0;
        end

        // Flush Execute stage (insert bubble):
        // Only insert bubble on Load-Use stall or Control hazard,
        // and NEVER flush during a d_stall (otherwise the instruction in EX is destroyed)
        if (!d_stall && (lwStall || (PCSrcE != 2'b00) || (Mispredict_Flag == 1'b1))) begin
            FlushE = 1'b1;
        end else begin
            FlushE = 1'b0;
        end
    end

endmodule