module Register_PC (
    input             i_Clk,
    input             rst_n,
    input             StallF,
    input      [31:0] PC_next,
    output reg [31:0] PCF
);
    always @(posedge i_Clk or negedge rst_n) begin
        if (!rst_n) begin
            PCF <= 32'h00000000;
        end else if (!StallF) begin
            PCF <= PC_next;
        end
    end
endmodule