module MULT(
    input  wire [1:0]  MUL_Control,
    input  wire [31:0] SrcA,
    input  wire [31:0] SrcB, 
    output reg  [31:0] MUL_Result
);

    wire signed [63:0] mul_ss = $signed(SrcA) * $signed(SrcB);
    wire signed [63:0] mul_su = $signed(SrcA) * $signed({1'b0, SrcB});
    wire        [63:0] mul_uu = SrcA * SrcB;

    always @(*) begin
        case (MUL_Control)
            2'b00:   MUL_Result = mul_ss[31:0];   // MUL
            2'b01:   MUL_Result = mul_ss[63:32];  // MULH
            2'b10:   MUL_Result = mul_su[63:32];  // MULHSU
            2'b11:   MUL_Result = mul_uu[63:32];  // MULHU
            default: MUL_Result = 32'h00000000;
        endcase
    end
endmodule