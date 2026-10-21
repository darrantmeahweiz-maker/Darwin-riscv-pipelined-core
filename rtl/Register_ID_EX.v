module Register_ID_EX (
    input             i_Clk,
    input             rst_n,
    input             FlushE,

    input             RegWriteD,
    input      [1:0]  ResultSrcD,
    input             MemWriteD,
    input      [1:0]  JumpD,
    input             BranchD,
    input      [1:0]  ExecSelD,
    input      [3:0]  ALUControlD,
    input      [1:0]  MultControlD,
    input      [1:0]  CRCControlD,
    input      [2:0]  BITControlD,
    input             ALUSrcBD,
    input      [1:0]  ALUSrcAD,

    input      [31:0] RD1,
    input      [31:0] RD2,
    input      [31:0] PCD,
    input      [4:0]  Rs1D,
    input      [4:0]  Rs2D,
    input      [4:0]  RdD,
    input      [2:0]  funct3D,
    input      [31:0] ImmExtD,
    input      [31:0] PCPlus4D,
    input      [31:0] Predicted_PCD,
    input             Pop_EnableD,

    output reg        RegWriteE,
    output reg [1:0]  ResultSrcE,
    output reg        MemWriteE,
    output reg [1:0]  JumpE,
    output reg        BranchE,
    output reg [1:0]  ExecSelE,
    output reg [3:0]  ALUControlE,
    output reg [1:0]  MultControlE,
    output reg [1:0]  CRCControlE,
    output reg [2:0]  BITControlE,
    output reg        ALUSrcBE,
    output reg [1:0]  ALUSrcAE,

    output reg [31:0] RD1E,
    output reg [31:0] RD2E,
    output reg [31:0] PCE,
    output reg [4:0]  Rs1E,
    output reg [4:0]  Rs2E,
    output reg [4:0]  RdE,
    output reg [2:0]  funct3E,
    output reg [31:0] ImmExtE,
    output reg [31:0] PCPlus4E,
    output reg [31:0] Predicted_PCE,
    output reg        Pop_EnableE
);
    always @(posedge i_Clk or negedge rst_n) begin
        if (!rst_n || FlushE) begin
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
endmodule