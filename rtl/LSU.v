module LSU (
    input  wire [2:0]  funct3M,
    input  wire [1:0]  ALUResultM,          // Bottom 2 bits for byte alignment
    input  wire [31:0] RD,                  // Raw read data from DMEM
    output reg  [3:0]  BW,                  // Byte write enable to DMEM
    output reg  [31:0] Formatted_ReadDataM  // Formatted data to Writeback
);

    always @(*) begin
        // Default assignments
        BW                  = 4'b0000;
        Formatted_ReadDataM = 32'h00000000;

        // -------------------------------------------------------------
        // Write Path: Byte Enable (BW) generation
        // -------------------------------------------------------------
        case (funct3M[1:0])
            2'b00: begin // sb (store byte)
                case (ALUResultM)
                    2'b00:   BW = 4'b0001;
                    2'b01:   BW = 4'b0010;
                    2'b10:   BW = 4'b0100;
                    2'b11:   BW = 4'b1000;
                    default: BW = 4'b0001;
                endcase
            end

            2'b01: begin // sh (store halfword)
                case (ALUResultM[1])
                    1'b0:    BW = 4'b0011;
                    1'b1:    BW = 4'b1100;
                    default: BW = 4'b0011;
                endcase
            end

            2'b10: begin // sw (store word)
                BW = 4'b1111;
            end

            default: begin
                BW = 4'b0000;
            end
        endcase

        // -------------------------------------------------------------
        // Read Path: Sign/Zero extension and sub-word alignment
        // -------------------------------------------------------------
        case (funct3M)
            3'b000: begin // lb (load byte, sign-extended)
                case (ALUResultM)
                    2'b00:   Formatted_ReadDataM = {{24{RD[7]}},  RD[7:0]};
                    2'b01:   Formatted_ReadDataM = {{24{RD[15]}}, RD[15:8]};
                    2'b10:   Formatted_ReadDataM = {{24{RD[23]}}, RD[23:16]};
                    2'b11:   Formatted_ReadDataM = {{24{RD[31]}}, RD[31:24]};
                    default: Formatted_ReadDataM = {{24{RD[7]}},  RD[7:0]};
                endcase
            end

            3'b100: begin // lbu (load byte unsigned, zero-extended)
                case (ALUResultM)
                    2'b00:   Formatted_ReadDataM = {24'b0, RD[7:0]};
                    2'b01:   Formatted_ReadDataM = {24'b0, RD[15:8]};
                    2'b10:   Formatted_ReadDataM = {24'b0, RD[23:16]};
                    2'b11:   Formatted_ReadDataM = {24'b0, RD[31:24]};
                    default: Formatted_ReadDataM = {24'b0, RD[7:0]};
                endcase
            end

            3'b001: begin // lh (load halfword, sign-extended)
                case (ALUResultM[1])
                    1'b0:    Formatted_ReadDataM = {{16{RD[15]}}, RD[15:0]};
                    1'b1:    Formatted_ReadDataM = {{16{RD[31]}}, RD[31:16]};
                    default: Formatted_ReadDataM = {{16{RD[15]}}, RD[15:0]};
                endcase
            end

            3'b101: begin // lhu (load halfword unsigned, zero-extended)
                case (ALUResultM[1])
                    1'b0:    Formatted_ReadDataM = {16'b0, RD[15:0]};
                    1'b1:    Formatted_ReadDataM = {16'b0, RD[31:16]};
                    default: Formatted_ReadDataM = {16'b0, RD[15:0]};
                endcase
            end

            3'b010: begin // lw (load word)
                Formatted_ReadDataM = RD;
            end

            default: begin
                Formatted_ReadDataM = RD;
            end
        endcase
    end

endmodule