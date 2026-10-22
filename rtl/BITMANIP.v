module BITMANIP (
    input  wire [31:0] SrcAE,
    input  wire [31:0] SrcBE,
    input  wire [2:0]  BIT_Control,
    output reg  [31:0] BIT_Result
);

    always @(*) begin : proc_bitmanip
        integer i;
        
        BIT_Result = 32'h00000000;

        case (BIT_Control)
            3'b000: begin // clz (count leading zeros)
                BIT_Result = 32'd32;
                for (i = 0; i < 32; i = i + 1) begin
                    if (SrcAE[i]) begin
                        BIT_Result = 31 - i;
                    end
                end
            end

            3'b001: begin // cpop (population count)
                BIT_Result = 32'd0;
                for (i = 0; i < 32; i = i + 1) begin
                    BIT_Result = BIT_Result + SrcAE[i];
                end
            end

            3'b010: begin // rev8 (byte reverse / endian swap)
                BIT_Result = {SrcAE[7:0], SrcAE[15:8], SrcAE[23:16], SrcAE[31:24]};
            end

            3'b011: begin // rol (rotate left)
                if (SrcBE[4:0] == 5'd0) begin
                    BIT_Result = SrcAE;
                end else begin
                    BIT_Result = (SrcAE << SrcBE[4:0]) | (SrcAE >> (6'd32 - SrcBE[4:0]));
                end
            end

            3'b100: begin // ror (rotate right)
                if (SrcBE[4:0] == 5'd0) begin
                    BIT_Result = SrcAE;
                end else begin
                    BIT_Result = (SrcAE >> SrcBE[4:0]) | (SrcAE << (6'd32 - SrcBE[4:0]));
                end
            end

            default: begin
                BIT_Result = 32'h00000000;
            end
        endcase
    end

endmodule