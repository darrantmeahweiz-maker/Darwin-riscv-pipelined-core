module Register_IF_ID (
    input             i_Clk,
    input             rst_n,
    input             StallD,
    input             FlushD,
    input      [31:0] RD,
    input      [31:0] PCF,
    input      [31:0] PCPlus4F,
    input      [31:0] Predicted_PCF,
    input             Pop_EnableF,

    output reg [31:0] InstrD,
    output reg [31:0] PCD,
    output reg [31:0] PCPlus4D,
    output reg [31:0] Predicted_PCD,
    output reg        Pop_EnableD     
);
    always @(posedge i_Clk or negedge rst_n) begin
        if (!rst_n) begin
            InstrD        <= 32'h0;
            PCD           <= 32'h0;
            PCPlus4D      <= 32'h0;
            Predicted_PCD <= 32'h0;
            Pop_EnableD   <= 1'b0;
        end else if (FlushD) begin
            InstrD        <= 32'h0;
            PCD           <= 32'h0;
            PCPlus4D      <= 32'h0;
            Predicted_PCD <= 32'h0;
            Pop_EnableD   <= 1'b0;      
        end else if (!StallD) begin
            InstrD        <= RD;
            PCD           <= PCF;
            PCPlus4D      <= PCPlus4F;
            Predicted_PCD <= Predicted_PCF; 
            Pop_EnableD   <= Pop_EnableF;   
        end
    end
endmodule