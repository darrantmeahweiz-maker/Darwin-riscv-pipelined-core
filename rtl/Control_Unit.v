module Control_Unit (
    input       [6:0]   op,
    input       [2:0]   funct3,
    input       [6:0]   funct7,  
    input       [4:0]   rs2D, 

    output reg          RegWriteD,
    output reg  [1:0]   ResultSrcD,
    output reg          MemWriteD,
    output reg  [1:0]   JumpD,
    output reg          BranchD,

    output reg  [1:0]   ExecSelD,
    output reg  [2:0]   BITControlD,
    output reg  [1:0]   MultControlD,
    output reg  [1:0]   CRCControlD,
    output reg  [3:0]   ALUControlD,
    output reg          ALUSrcBD,
    output reg  [1:0]   ALUSrcAD,  
    output reg  [2:0]   ImmSrcD     
);

    always @(*) begin
        // Complete default assignments (Prevents inferred latches in Synopsys DC)
        RegWriteD    = 1'b0;
        ResultSrcD   = 2'b00;
        MemWriteD    = 1'b0;
        JumpD        = 2'b00;
        BranchD      = 1'b0;

        ExecSelD     = 2'b00;
        BITControlD  = 3'b000;   // <--- Fixed: prevents 3-bit latch inference
        MultControlD = 2'b00;
        CRCControlD  = 2'b00;

        ALUControlD  = 4'b0000;
        ALUSrcBD     = 1'b0;
        ALUSrcAD     = 2'b00; 
        ImmSrcD      = 3'b000;

        case (op)
            7'b0110011, 7'b0010011: begin   
                RegWriteD   = 1'b1;
                ResultSrcD  = 2'b00;
                ALUSrcBD    = (op == 7'b0010011);
                ImmSrcD     = 3'b000;

                if (op == 7'b0010011) begin
                    case ({funct3, rs2D})
                        8'b001_00000: begin
                            ExecSelD    = 2'b11;
                            BITControlD = 3'b000;
                        end
                        8'b001_00010: begin
                            ExecSelD    = 2'b11;
                            BITControlD = 3'b001;
                        end
                        8'b101_11000: begin
                            ExecSelD    = 2'b11;
                            BITControlD = 3'b010;
                        end
                        default: ;
                    endcase
                end else begin
                    case (funct7)
                        7'b0110000: begin
                            ExecSelD     = 2'b11;
                            BITControlD  = (funct3 == 3'b001) ? 3'b011 : 3'b100;
                        end
                        7'b0000001: begin
                            ExecSelD     = 2'b01;
                            MultControlD = funct3[1:0];
                        end
                        7'b1000000: begin
                            ExecSelD     = 2'b10;
                            CRCControlD  = funct3[1:0];
                        end
                        default: ;
                    endcase
                end

                case (funct3)
                    3'b000: ALUControlD = (funct7[5] == 1'b1 && op == 7'b0110011) ? 4'h2 : 4'h1;
                    3'b001: ALUControlD = 4'h6;
                    3'b010: ALUControlD = 4'h9;
                    3'b011: ALUControlD = 4'hA;
                    3'b100: ALUControlD = 4'h5;
                    3'b101: ALUControlD = (funct7[5] == 1'b1) ? 4'h8 : 4'h7;
                    3'b110: ALUControlD = 4'h4;
                    3'b111: ALUControlD = 4'h3;
                    default: ALUControlD = 4'h0;
                endcase
            end

            7'b0000011: begin               
                RegWriteD   = 1'b1;
                ResultSrcD  = 2'b01;
                ALUSrcBD    = 1'b1;
                ImmSrcD     = 3'b000;
                ALUControlD = 4'h1;
            end

            7'b0100011: begin               
                MemWriteD   = 1'b1;
                ALUSrcBD    = 1'b1;
                ImmSrcD     = 3'b001;
                ALUControlD = 4'h1;
            end

            7'b1100011: begin               
                ALUSrcBD    = 1'b0;
                ImmSrcD     = 3'b010;   
                BranchD     = 1'b1;
                case(funct3)
                    3'b000: ALUControlD = 4'h2;
                    3'b001: ALUControlD = 4'hB;
                    3'b100: ALUControlD = 4'hC;
                    3'b101: ALUControlD = 4'hD;
                    3'b110: ALUControlD = 4'hE;
                    3'b111: ALUControlD = 4'hF;
                    default: ALUControlD = 4'h0;
                endcase
            end

            7'b1101111: begin               
                RegWriteD   = 1'b1;
                JumpD       = 2'b01;
                ResultSrcD  = 2'b10;
                ImmSrcD     = 3'b011;
            end

            7'b1100111: begin               
                RegWriteD   = 1'b1;
                JumpD       = 2'b10;
                ResultSrcD  = 2'b10;
                ALUSrcBD    = 1'b1;
                ImmSrcD     = 3'b000;
                ALUControlD = 4'h1;
            end

            7'b0110111: begin   
                RegWriteD   = 1'b1;
                ResultSrcD  = 2'b00;
                ALUSrcAD    = 2'b10;  
                ALUSrcBD    = 1'b1;
                ImmSrcD     = 3'b100;
                ALUControlD = 4'h0;
            end

            7'b0010111: begin 
                RegWriteD   = 1'b1;
                ResultSrcD  = 2'b00;
                ALUSrcAD    = 2'b01;
                ALUSrcBD    = 1'b1;
                ImmSrcD     = 3'b100;
                ALUControlD = 4'h1;
            end

            7'b1110011, 7'b0001111: begin               
            end

            default: begin
            end
        endcase
    end
endmodule