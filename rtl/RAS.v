module RAS (
    input  wire        i_clk,
    input  wire        rst_n,
    input  wire        Push_Enable,
    input  wire [31:0] Push_Data,
    input  wire        Pop_Enable,
    output wire [31:0] Predicted_PC
);
    reg [31:0] stack [0:7];
    reg [2:0]  sp;

    always @(posedge i_clk or negedge rst_n) begin : proc_ras
        integer i;
        if (!rst_n) begin
            sp <= 3'b000;
            for (i = 0; i < 8; i = i + 1) begin
                stack[i] <= 32'h00000000;
            end
        end else if (Push_Enable) begin 
            stack[sp] <= Push_Data;     
            sp <= sp + 3'd1;
        end else if (Pop_Enable) begin
            sp <= sp - 3'd1;
        end
    end

    assign Predicted_PC = stack[sp - 3'd1];
endmodule