module RAS (
    input             i_clk,
    input             rst_n,
    input             Push_Enable,
    input      [31:0] Push_Data,
    input             Pop_Enable,
    output     [31:0] Predicted_PC
);
    reg [31:0] stack [0:7];
    reg [2:0]  sp;

    always @(posedge i_clk or negedge rst_n) begin 
        if (!rst_n) begin
            sp <= 3'b000;
        end else if (Push_Enable) begin 
            stack[sp] <= Push_Data;     
            sp <= sp + 1;
        end else if (Pop_Enable) begin
            sp <= sp - 1;
        end
    end

    assign Predicted_PC = stack[sp-1];
endmodule