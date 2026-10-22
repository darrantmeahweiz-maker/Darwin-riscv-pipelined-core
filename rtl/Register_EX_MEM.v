module Register_EX_MEM (
    input  wire        i_Clk,
    input  wire        rst_n,
    input  wire        StallM,         // Freeze MEM pipeline register on D-Bus stall

    // Inputs from Execute Stage
    input  wire        RegWriteE,
    input  wire [1:0]  ResultSrcE,
    input  wire        MemWriteE,
    input  wire [31:0] ALUResultE,
    input  wire [31:0] WriteDataE,
    input  wire [4:0]  RdE,
    input  wire [2:0]  funct3E,
    input  wire [31:0] PCPlus4E,

    // Outputs to Memory Stage
    output reg         RegWriteM,
    output reg  [1:0]  ResultSrcM,
    output reg         MemWriteM,
    output reg  [31:0] ALUResultM,
    output reg  [31:0] WriteDataM,
    output reg  [4:0]  RdM,
    output reg  [2:0]  funct3M,
    output reg  [31:0] PCPlus4M
);

    always @(posedge i_Clk or negedge rst_n) begin
        if (!rst_n) begin
            // Asynchronous Reset
            RegWriteM  <= 1'b0;
            ResultSrcM <= 2'b00;
            MemWriteM  <= 1'b0;
            ALUResultM <= 32'h0;
            WriteDataM <= 32'h0;
            RdM        <= 5'b0;
            funct3M    <= 3'b0;
            PCPlus4M   <= 32'h0;
        end else if (!StallM) begin
            // Normal Pipeline Advance
            RegWriteM  <= RegWriteE;
            ResultSrcM <= ResultSrcE;
            MemWriteM  <= MemWriteE;
            ALUResultM <= ALUResultE;
            WriteDataM <= WriteDataE;
            RdM        <= RdE;
            funct3M    <= funct3E;
            PCPlus4M   <= PCPlus4E;
        end
        // When StallM == 1'b1, all output registers hold their current values
    end

endmodule