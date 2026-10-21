module Register_EX_MEM (
    input             i_Clk,
    input             rst_n,

    input             RegWriteE,
    input      [1:0]  ResultSrcE,
    input             MemWriteE,
    input      [31:0] ALUResultE,
    input      [31:0] WriteDataE,
    input      [4:0]  RdE,
    input      [2:0]  funct3E,
    input      [31:0] PCPlus4E,

    output reg        RegWriteM,
    output reg [1:0]  ResultSrcM,
    output reg        MemWriteM,
    output reg [31:0] ALUResultM,
    output reg [31:0] WriteDataM,
    output reg [4:0]  RdM,
    output reg [2:0]  funct3M,
    output reg [31:0] PCPlus4M
);
    always @(posedge i_Clk or negedge rst_n) begin
        if (!rst_n) begin
            RegWriteM  <= 1'b0;
            ResultSrcM <= 2'b00;
            MemWriteM  <= 1'b0;
            ALUResultM <= 32'h0;
            WriteDataM <= 32'h0;
            RdM        <= 5'b0;
            funct3M    <= 3'b0;
            PCPlus4M   <= 32'h0;
        end else begin
            RegWriteM  <= RegWriteE;
            ResultSrcM <= ResultSrcE;
            MemWriteM  <= MemWriteE;
            ALUResultM <= ALUResultE;
            WriteDataM <= WriteDataE;
            RdM        <= RdE;
            funct3M    <= funct3E;
            PCPlus4M   <= PCPlus4E;
        end
    end
endmodule