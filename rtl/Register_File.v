module Register_File # (
    parameter p_DATA_DMEM_SIZE = 2**12
)(
    input  wire [4:0]  A1,
    input  wire [4:0]  A2,
    input  wire [4:0]  A3,
    input  wire [31:0] ResultW,
    input  wire        RegWriteW,
    input  wire        i_Clk,
    input  wire        rst_n,
    output wire [31:0] RD1D,
    output wire [31:0] RD2D,
    output wire [31:0] o_debug_x4   //add this port
);

    assign o_debug_x4 = r_Registers[4];     //to direct read of x4

    localparam c_SP_Index = 2;
    localparam c_GP_Index = 3;
    localparam c_GP_Initial_Value = 32'h10010000;
    localparam c_SP_Initial_Value = c_GP_Initial_Value + p_DATA_DMEM_SIZE - 4;

    reg [31:0] r_Registers [0:31];
        // Unified Positive-Edge Triggered Write (Eliminates Half-Cycle STA Path)
    always @(posedge i_Clk or negedge rst_n) begin : proc_reg_write
        integer i;
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                case (i)
                    c_SP_Index: r_Registers[i] <= c_SP_Initial_Value;
                    c_GP_Index: r_Registers[i] <= c_GP_Initial_Value;
                    default:    r_Registers[i] <= 32'h0;
                endcase
            end
        end else begin
            if (RegWriteW && (A3 != 5'h0)) begin
                r_Registers[A3] <= ResultW;
            end
        end
    end
    // Asynchronous Read with Internal WB-to-ID Write-Through Bypass
    assign RD1D = (A1 == 5'h0)              ? 32'h0   :
                  (RegWriteW && (A3 == A1)) ? ResultW : r_Registers[A1];

    assign RD2D = (A2 == 5'h0)              ? 32'h0   :
                  (RegWriteW && (A3 == A2)) ? ResultW : r_Registers[A2];

endmodule