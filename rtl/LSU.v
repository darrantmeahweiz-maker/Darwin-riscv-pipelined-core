module LSU (
    input       [2:0]   funct3M,
    input       [1:0]   ALUResultM,         //bottom 2 bits for alignment
    input       [31:0]  RD,                 //RD from DMEM, then to ReadDataW
    output reg  [3:0]   BW,                 //BW from funct3M, thento DMEM
    output reg  [31:0]  Formatted_ReadDataM 
);

always @(*) begin
    //Default
    BW = 4'b0000;
    Formatted_ReadDataM = 32'h00000000;

    //Write path -- generate byte enable (BW) for DMEM
    //bottom 2 bit of funct3M: 00(sb), 01(sh), 10(sw)
    /*NOTE: Load instruction share these code, 
    but DMEM will just ignore the BW output if WE pin is set to 0 */
    case (funct3M[1:0])
        2'b00: begin
            case (ALUResultM)       //sb, save byte
                2'b00: BW = 4'b0001;
                2'b01: BW = 4'b0010;
                2'b10: BW = 4'b0100;
                2'b11: BW = 4'b1000;
            endcase
        end
        2'b01: begin
            case (ALUResultM[1])    //sh, save halfword
                1'b0: BW = 4'b0011;
                1'b1: BW = 4'b1100;
            endcase
        end
        2'b10: begin
            BW = 4'b1111;           //sw, save word
        end
    endcase

    //Read path
    case (funct3M)
        3'b000: begin   //lb (load byte, sign-extended)
            case (ALUResultM)
                2'b00: Formatted_ReadDataM = {{24{RD[7]}}, RD[7:0]};
                2'b01: Formatted_ReadDataM = {{24{RD[15]}}, RD[15:8]};
                2'b10: Formatted_ReadDataM = {{24{RD[23]}}, RD[23:16]};
                2'b11: Formatted_ReadDataM = {{24{RD[31]}}, RD[31:24]};
            endcase
        end
        3'b100: begin   //lbu (load byte unsigned, zero-extended)
            case (ALUResultM)
                2'b00: Formatted_ReadDataM = {24'b0, RD[7:0]};
                2'b01: Formatted_ReadDataM = {24'b0, RD[15:8]};
                2'b10: Formatted_ReadDataM = {24'b0, RD[23:16]};
                2'b11: Formatted_ReadDataM = {24'b0, RD[31:24]};
            endcase
        end
        3'b001: begin   //lh (load halfword, sign-extended)
            case (ALUResultM[1])
                1'b0: Formatted_ReadDataM = {{16{RD[15]}}, RD[15:0]};
                1'b1: Formatted_ReadDataM = {{16{RD[31]}}, RD[31:16]};
            endcase
        end
        3'b101: begin   //lhu (Load Halfword Unsigned, Zero-Extended)
            case (ALUResultM[1])
                1'b0: Formatted_ReadDataM = {16'b0, RD[15:0]};
                1'b1: Formatted_ReadDataM = {16'b0, RD[31:16]};
            endcase
        end
        3'b010: begin   //lw (load word)
            Formatted_ReadDataM = RD;
        end
        default: begin
            Formatted_ReadDataM = RD;
        end
    endcase
end
endmodule