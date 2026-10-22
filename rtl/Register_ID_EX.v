module Register_ID_EX (
    input  wire        i_Clk,
    input  wire        rst_n,
    input  wire        StallE,         // Freeze EX pipeline register on D-Bus stall
    input  wire        FlushE,

    // Control Signals from Control Unit (Decode Stage)
    input  wire        RegWriteD,
    input  wire [1:0]  ResultSrcD,
    input  wire        MemWriteD,
    input  wire [1:0]  JumpD,
    input  wire        BranchD,
    input  wire [1:0]  ExecSelD,
    input  wire [3:0]  ALUControlD,
    input  wire [1:0]  MultControlD,
    input  wire [1:0]  CRCControlD,
    input  wire [2:0]  BITControlD,
    input  wire        ALUSrcBD,
    input  wire [1:0]  ALUSrcAD,

    // Data and Register Fields from Decode Stage
    input  wire [31:0] RD1,
    input  wire [31:0] RD2,
    input  wire [31:0] PCD,
    input  wire [4:0]  Rs1D,
    input  wire [4:0]  Rs2D,
    input  wire [4:0]  RdD,
    input  wire [2:0]  funct3D,
    input  wire [31:0] ImmExtD,
    input  wire [31:0] PCPlus4D,
    input  wire [31:0] Predicted_PCD,
    input  wire        Pop_EnableD,

    // Control Signals Output (Execute Stage)
    output reg         RegWriteE,
    output reg  [1:0]  ResultSrcE,
    output reg         MemWriteE,
    output reg  [1:0]  JumpE,
    output reg         BranchE,
    output reg  [1:0]  ExecSelE,
    output reg  [3:0]  ALUControlE,
    output reg  [1:0]  MultControlE,
    output reg  [1:0]  CRCControlE,
    output reg  [2:0]  BITControlE,
    output reg         ALUSrcBE,
    output reg  [1:0]  ALUSrcAE,

    // Data and Register Fields Output (Execute Stage)
    output reg  [31:0] RD1E,
    output reg  [31:0] RD2E,
    output reg  [31:0] PCE,
    output reg  [4:0]  Rs1E,
    output reg  [4:0]  Rs2E,
    output reg  [4:0]  RdE,
    output reg  [2:0]  funct3E,
    output reg  [31:0] ImmExtE,
    output reg  [31:0] PCPlus4E,
    output reg  [31:0] Predicted_PCE,
    output reg         Pop_EnableE
);

    always @(posedge i_Clk or negedge rst_n) begin
        if (!rst_n) begin
            // Asynchronous Reset: Clear all control signals and data
            RegWriteE     <= 1'b0;
            ResultSrcE    <= 2'b00;
            MemWriteE     <= 1'b0;
            JumpE         <= 2'b00;
            BranchE       <= 1'b0;
            ExecSelE      <= 2'b00;
            ALUControlE   <= 4'b0000;
            MultControlE  <= 2'b00;
            CRCControlE   <= 2'b00;
            BITControlE   <= 3'b000;
            ALUSrcBE      <= 1'b0;
            ALUSrcAE      <= 2'b00;
            RD1E          <= 32'h0;
            RD2E          <= 32'h0;
            PCE           <= 32'h0;
            Rs1E          <= 5'b00000;
            Rs2E          <= 5'b00000;
            RdE           <= 5'b00000;
            funct3E       <= 3'b000;
            ImmExtE       <= 32'h0;
            PCPlus4E      <= 32'h0;
            Predicted_PCE <= 32'h0;
            Pop_EnableE   <= 1'b0;
        end else if (!StallE) begin
            if (FlushE) begin
                // Synchronous Flush / Bubble: Zero out control path and data
                RegWriteE     <= 1'b0;
                ResultSrcE    <= 2'b00;
                MemWriteE     <= 1'b0;
                JumpE         <= 2'b00;
                BranchE       <= 1'b0;
                ExecSelE      <= 2'b00;
                ALUControlE   <= 4'b0000;
                MultControlE  <= 2'b00;
                CRCControlE   <= 2'b00;
                BITControlE   <= 3'b000;
                ALUSrcBE      <= 1'b0;
                ALUSrcAE      <= 2'b00;
                RD1E          <= 32'h0;
                RD2E          <= 32'h0;
                PCE           <= 32'h0;
                Rs1E          <= 5'b00000;
                Rs2E          <= 5'b00000;
                RdE           <= 5'b00000;
                funct3E       <= 3'b000;
                ImmExtE       <= 32'h0;
                PCPlus4E      <= 32'h0;
                Predicted_PCE <= 32'h0;
                Pop_EnableE   <= 1'b0;
            end else begin
                // Normal Pipeline Advance
                RegWriteE     <= RegWriteD;
                ResultSrcE    <= ResultSrcD;
                MemWriteE     <= MemWriteD;
                JumpE         <= JumpD;
                BranchE       <= BranchD;
                ExecSelE      <= ExecSelD;
                ALUControlE   <= ALUControlD;
                MultControlE  <= MultControlD;
                CRCControlE   <= CRCControlD;
                BITControlE   <= BITControlD;
                ALUSrcBE      <= ALUSrcBD;
                ALUSrcAE      <= ALUSrcAD;
                RD1E          <= RD1;
                RD2E          <= RD2;
                PCE           <= PCD;
                Rs1E          <= Rs1D;
                Rs2E          <= Rs2D;
                RdE           <= RdD;
                funct3E       <= funct3D;
                ImmExtE       <= ImmExtD;
                PCPlus4E      <= PCPlus4D;
                Predicted_PCE <= Predicted_PCD;
                Pop_EnableE   <= Pop_EnableD;
            end
        end
        // When StallE == 1'b1, all output registers hold their current values
    end

endmodule