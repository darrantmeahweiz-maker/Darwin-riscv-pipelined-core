module Register_MEM_WB(
    input             i_Clk,
    input             rst_n,
    input             RegWriteM,
    input      [1:0]  ResultSrcM,
    input      [31:0] ALUResultM,
    input      [31:0] Formatted_RD,
    input      [4:0]  RdM,
    input      [31:0] PCPlus4M,

    output reg        RegWriteW,
    output reg [1:0]  ResultSrcW,
    output reg [31:0] ALUResultW,
    output reg [31:0] ReadDataW,
    output reg [4:0]  RdW,
    output reg [31:0] PCPlus4W
);
    always @(posedge i_Clk or negedge rst_n) begin
        if (!rst_n) begin
            RegWriteW  <= 1'b0;
            ResultSrcW <= 2'b00;
            ALUResultW <= 32'h0;
            ReadDataW  <= 32'h0;
            RdW        <= 5'b0;
            PCPlus4W   <= 32'h0;
        end else begin
            RegWriteW  <= RegWriteM;
            ResultSrcW <= ResultSrcM;
            ALUResultW <= ALUResultM;
            ReadDataW  <= Formatted_RD;   
            RdW        <= RdM;
            PCPlus4W   <= PCPlus4M;
        end
    end
endmodule