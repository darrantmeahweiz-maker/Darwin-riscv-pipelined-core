module DMEM (
    input  wire        i_Clk,
    input  wire        WE,
    input  wire        OE,
    input  wire [3:0]  BW,
    input  wire [31:0] A,
    input  wire [31:0] WD,
    output reg  [31:0] RD
);

    // Hint to Quartus to map directly to M10K Block RAM
    (* ramstyle = "M10K" *) reg [31:0] RAM [0:1023]; // 4KB (1024 words x 32 bits)

    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            RAM[i] = 32'h00000000;
        end
        RD = 32'h00000000;
    end

    // Zero-gate wire slice (replaces 32-bit subtractor)
    wire [9:0] word_index = A[11:2];

    // Synchronous Write (Byte-Enabled) & Synchronous Read for True BRAM Inference
    always @(posedge i_Clk) begin
        if (WE) begin
            if (BW[0]) RAM[word_index][7:0]   <= WD[7:0];
            if (BW[1]) RAM[word_index][15:8]  <= WD[15:8];
            if (BW[2]) RAM[word_index][23:16] <= WD[23:16];
            if (BW[3]) RAM[word_index][31:24] <= WD[31:24];
        end
        if (OE) begin
            RD <= RAM[word_index];
        end
    end

endmodule