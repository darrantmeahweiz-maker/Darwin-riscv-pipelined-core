module IMEM (
    input wire [31:0] A,
    output reg [31:0] RD,
    input wire        OE        //permanently turned on (1'b1)
);

    reg [31:0] ROM [0:1023]; //4kb (1024 words x 32bits)

    //$readmemh reads hexadecimal text file and load into ROM array
    initial begin
        $readmemh("program.hex",ROM);
    end

    //Address Translation: PC, program counter counts by 4 (0x0, 0x4, 0x8...)
    //Shifting right by 2 (divide by 4) converts byte-address into word_index
    //Assuming IMEM starts at address 0x0000_0000.
    wire [9:0] word_index = A[11:2];

    //Combinational Read Logic
    always @(*) begin
        if (OE) begin
            RD = ROM[word_index];
        end else begin
            RD = 32'h00000013; //NOP instruction (addi x0,x0,0)
        end
    end
endmodule
        

    
