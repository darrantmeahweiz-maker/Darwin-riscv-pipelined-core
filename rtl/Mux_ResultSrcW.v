module Mux_ResultSrcW (
    input  wire [1:0]  ResultSrcW,
    input  wire [31:0] ALUResultW,
    input  wire [31:0] ReadDataW,
    input  wire [31:0] PCPlus4W,
    output reg  [31:0] ResultW
);

    always @(*) begin
        case (ResultSrcW) 
            2'b00:   ResultW = ALUResultW;
            2'b01:   ResultW = ReadDataW;
            2'b10:   ResultW = PCPlus4W;
            default: ResultW = ALUResultW;
        endcase
    end
endmodule