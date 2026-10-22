`timescale 1ns / 1ps

module RISCV_Core (
    input  wire        clk,
    input  wire        rst_n,            // Active-low asynchronous reset

    // ==========================================
    // Existing Bus Ports
    // ==========================================
    output wire        o_mispredict_flag,// Debug: passes Mispredict_Flag
    output wire [31:0] o_debug_x4,       // Debug: passes register x4

    // ==========================================
    // Instruction Bus Interface (I-Bus)
    // ==========================================
    output wire [31:0] i_addr,           // Instruction fetch address (PCF)
    output wire        i_req,            // Instruction fetch request
    input  wire [31:0] i_rdata,          // Incoming instruction (InstrF)

    // ==========================================
    // Data Bus Interface (D-Bus)
    // ==========================================
    output wire [31:0] d_addr,           // Memory access address (ALUResultM)
    output wire [31:0] d_wdata,          // Memory write data (WriteDataM)
    output wire [3:0]  d_we,             // Byte-write enables (sb=0001, sh=0011, sw=1111)
    output wire        d_req,            // Memory read/write request
    input  wire [31:0] d_rdata,          // Incoming raw load data
    input  wire        d_ready           // 1 when memory/peripheral is ready, 0 when waiting
);

    // =========================================================================
    // 1. INTERNAL WIRE DECLARATIONS
    // =========================================================================

    // --- Hazard Unit ---
    wire        StallF, StallD, StallE, StallM, FlushD, FlushE;
    wire [1:0]  ForwardAE, ForwardBE;
    wire        Mispredict_Flag;

    // --- Fetch Stage (IF) ---
    wire [31:0] PC_next, PCF, PCPlus4F, InstrF;
    wire [1:0]  MUX_PCSel;
    wire        Push_EnableF, Pop_EnableF;
    wire [31:0] Predicted_PCF;

    // --- Decode Stage (ID) ---
    wire [31:0] InstrD, PCD, PCPlus4D, Predicted_PCD;
    wire        Pop_EnableD;
    wire [6:0]  opD, funct7D;
    wire [4:0]  Rs1D, Rs2D, RdD;
    wire [2:0]  funct3D, ImmSrcD;
    wire [31:0] RD1D, RD2D, ImmExtD;
    wire        RegWriteD, MemWriteD, BranchD, ALUSrcBD;
    wire [1:0]  ResultSrcD, JumpD, ExecSelD, ALUSrcAD, MultControlD, CRCControlD;
    wire [2:0]  BITControlD;
    wire [3:0]  ALUControlD;

    // --- Execute Stage (EX) ---
    wire [31:0] RD1E, RD2E, PCE, PCPlus4E, ImmExtE, Predicted_PCE;
    wire [4:0]  Rs1E, Rs2E, RdE;
    wire [2:0]  funct3E;
    wire        Pop_EnableE;
    wire        RegWriteE, MemWriteE, BranchE, ALUSrcBE;
    wire [1:0]  ResultSrcE, JumpE, ExecSelE, ALUSrcAE, MultControlE, CRCControlE;
    wire [2:0]  BITControlE;
    wire [3:0]  ALUControlE;
    wire [31:0] Formatted_SrcAE, Formatted_SrcBE, SrcAE, SrcBE;
    wire [31:0] ALU_OutE, MULT_OutE, CRC_OutE, BITMANIP_OutE, ALUResultE_Final;
    wire [31:0] PCTargetE;
    wire        ZeroE;
    wire [1:0]  PCSrcE;

    // --- Memory Stage (MEM) ---
    wire        RegWriteM, MemWriteM;
    wire [1:0]  ResultSrcM;
    wire [31:0] ALUResultM, WriteDataM, PCPlus4M;
    wire [4:0]  RdM;
    wire [2:0]  funct3M;
    wire [3:0]  BW;
    wire [31:0] ReadDataM_raw, ReadDataM_formatted;

    // --- Writeback Stage (WB) ---
    wire        RegWriteW;
    wire [1:0]  ResultSrcW;
    wire [31:0] ALUResultW, ReadDataW, PCPlus4W;
    wire [4:0]  RdW;
    wire [31:0] ResultW;

    // =========================================================================
    // 2. BUS PORT ASSIGNMENTS
    // =========================================================================

    // Instruction Bus Hookup
    assign i_addr = PCF;
    assign i_req  = ~StallF;
    assign InstrF = i_rdata;

    // Data Bus Hookup
    assign d_addr        = ALUResultM;
    assign d_wdata       = WriteDataM;
    assign d_we          = MemWriteM ? BW : 4'b0000;
    assign d_req         = MemWriteM | (ResultSrcM == 2'b01); // Store OR Load
    assign ReadDataM_raw = d_rdata;

    // =========================================================================
    // 3. FETCH STAGE (IF)
    // =========================================================================

    MUX_Fetch_Control fetch_mux_ctrl (
        .PCSrcE(PCSrcE),
        .Pop_Enable(Pop_EnableF),
        .MUX_PCSel(MUX_PCSel)
    );

    Mux_PC pc_mux (
        .MUX_PCSel(MUX_PCSel),
        .PCPlus4F(PCPlus4F),
        .PCTargetE(PCTargetE),
        .ALUResultE(ALUResultE_Final),
        .Predicted_PC(Predicted_PCF),
        .PC_next(PC_next)
    );

    Register_PC pc_reg (
        .i_Clk(clk),
        .rst_n(rst_n),
        .StallF(StallF),
        .PC_next(PC_next),
        .PCF(PCF)
    );

    Adder_PCPlus4 pc_plus_4 (
        .PCF(PCF),
        .PCPlus4F(PCPlus4F)
    );

    Pre_Decoder pre_decoder (
        .InstrF(InstrF),
        .Push_Enable(Push_EnableF),
        .Pop_Enable(Pop_EnableF)
    );

    RAS return_address_stack (
        .i_clk        (clk),
        .rst_n        (rst_n),
        .Push_Enable  (Push_EnableF & ~StallF), // Gated: push only on valid new fetch
        .Push_Data    (PCPlus4F),
        .Pop_Enable   (Pop_EnableF & ~StallF),  // Gated: pop only on valid new fetch
        .Predicted_PC (Predicted_PCF)
    );

    Register_IF_ID if_id_reg (
        .i_Clk(clk),
        .rst_n(rst_n),
        .StallD(StallD),
        .FlushD(FlushD),
        .RD(InstrF),
        .PCF(PCF),
        .PCPlus4F(PCPlus4F),
        .Predicted_PCF(Predicted_PCF),
        .Pop_EnableF(Pop_EnableF),
        .InstrD(InstrD),
        .PCD(PCD),
        .PCPlus4D(PCPlus4D),
        .Predicted_PCD(Predicted_PCD),
        .Pop_EnableD(Pop_EnableD)
    );

    // =========================================================================
    // 4. DECODE STAGE (ID)
    // =========================================================================

    Instruction_Splitter instr_split (
        .InstrD(InstrD),
        .funct7(funct7D),
        .rs2(Rs2D),
        .rs1(Rs1D),
        .funct3(funct3D),
        .rd(RdD),
        .opcode(opD),
        .Instr()
    );

    Control_Unit ctrl_unit (
        .op(opD),
        .funct3(funct3D),
        .funct7(funct7D),
        .rs2D(Rs2D),
        .RegWriteD(RegWriteD),
        .ResultSrcD(ResultSrcD),
        .MemWriteD(MemWriteD),
        .JumpD(JumpD),
        .BranchD(BranchD),
        .ExecSelD(ExecSelD),
        .BITControlD(BITControlD),
        .MultControlD(MultControlD),
        .CRCControlD(CRCControlD),
        .ALUControlD(ALUControlD),
        .ALUSrcBD(ALUSrcBD),
        .ALUSrcAD(ALUSrcAD),
        .ImmSrcD(ImmSrcD)
    );

    Register_File reg_file (
        .A1(Rs1D),
        .A2(Rs2D),
        .A3(RdW),
        .ResultW(ResultW),
        .RegWriteW(RegWriteW),
        .i_Clk(clk),
        .rst_n(rst_n),
        .RD1D(RD1D),
        .RD2D(RD2D),
        .o_debug_x4(o_debug_x4)
    );

    extend imm_extend (
        .InstrD(InstrD[31:7]),
        .ImmSrcD(ImmSrcD),
        .ImmExt(ImmExtD)
    );

    Register_ID_EX id_ex_reg (
        .i_Clk(clk),
        .rst_n(rst_n),
        .StallE(StallE),                 // Fixed case-sensitivity typo
        .FlushE(FlushE),
        .RegWriteD(RegWriteD),
        .ResultSrcD(ResultSrcD),
        .MemWriteD(MemWriteD),
        .JumpD(JumpD),
        .BranchD(BranchD),
        .ExecSelD(ExecSelD),
        .ALUControlD(ALUControlD),
        .MultControlD(MultControlD),
        .CRCControlD(CRCControlD),
        .BITControlD(BITControlD),
        .ALUSrcBD(ALUSrcBD),
        .ALUSrcAD(ALUSrcAD),
        .RD1(RD1D),
        .RD2(RD2D),
        .PCD(PCD),
        .Rs1D(Rs1D),
        .Rs2D(Rs2D),
        .RdD(RdD),
        .funct3D(funct3D),
        .ImmExtD(ImmExtD),
        .PCPlus4D(PCPlus4D),
        .Predicted_PCD(Predicted_PCD),
        .Pop_EnableD(Pop_EnableD),
        // Outputs
        .RegWriteE(RegWriteE),
        .ResultSrcE(ResultSrcE),
        .MemWriteE(MemWriteE),
        .JumpE(JumpE),
        .BranchE(BranchE),
        .ExecSelE(ExecSelE),
        .ALUControlE(ALUControlE),
        .MultControlE(MultControlE),
        .CRCControlE(CRCControlE),
        .BITControlE(BITControlE),
        .ALUSrcBE(ALUSrcBE),
        .ALUSrcAE(ALUSrcAE),
        .RD1E(RD1E),
        .RD2E(RD2E),
        .PCE(PCE),
        .Rs1E(Rs1E),
        .Rs2E(Rs2E),
        .RdE(RdE),
        .funct3E(funct3E),
        .ImmExtE(ImmExtE),
        .PCPlus4E(PCPlus4E),
        .Predicted_PCE(Predicted_PCE),
        .Pop_EnableE(Pop_EnableE)
    );

    // =========================================================================
    // 5. EXECUTE STAGE (EX)
    // =========================================================================

    Mux_ForwardAE mux_fwd_a (
        .ForwardAE(ForwardAE),
        .RD1(RD1E),
        .ResultW(ResultW),
        .ALUResultM(ALUResultM),
        .Formatted_RD1(Formatted_SrcAE)
    );

    Mux_ForwardBE mux_fwd_b (
        .ForwardBE(ForwardBE),
        .RD2(RD2E),
        .ResultW(ResultW),
        .ALUResultM(ALUResultM),
        .Formatted_RD2(Formatted_SrcBE)
    );

    Mux_ALUSrcAE mux_alu_a (
        .ALUSrcAE(ALUSrcAE),
        .Formatted_SrcAE(Formatted_SrcAE),
        .PCE(PCE),
        .SrcAE(SrcAE)
    );

    Mux_ALUSrcBE mux_alu_b (
        .ALUSrcBE(ALUSrcBE),
        .Formatted_SrcBE(Formatted_SrcBE),
        .ImmExtE(ImmExtE),
        .SrcBE(SrcBE)
    );

    ALU main_alu (
        .SrcAE(SrcAE),
        .SrcBE(SrcBE),
        .ALUControlE(ALUControlE),
        .ALUResultE(ALU_OutE),
        .o_Zero(ZeroE)
    );

    MULT exec_mult (
        .MUL_Control(MultControlE),
        .SrcA(SrcAE),
        .SrcB(SrcBE),
        .MUL_Result(MULT_OutE)
    );

    CRC exec_crc (
        .CRC_Control(CRCControlE),
        .SrcA(SrcAE),
        .SrcB(SrcBE),
        .CRC_Result(CRC_OutE)
    );

    BITMANIP exec_bitmanip (
        .SrcAE(SrcAE),
        .SrcBE(SrcBE),
        .BIT_Control(BITControlE),
        .BIT_Result(BITMANIP_OutE)
    );

    Mux_ExecSelE mux_exec_sel (
        .ExecSelE(ExecSelE),
        .ALU(ALU_OutE),
        .MULT(MULT_OutE),
        .CRC(CRC_OutE),
        .BITMANIP(BITMANIP_OutE),
        .ALUResultE(ALUResultE_Final)
    );

    Adder_PC_Target pc_target_adder (
        .ImmExtE(ImmExtE),
        .PCE(PCE),
        .PCTargetE(PCTargetE)
    );

    Next_PC_Logic next_pc_logic (
        .ZeroE(ZeroE),
        .BranchE(BranchE),
        .JumpE(JumpE),
        .Pop_EnableE(Pop_EnableE),
        .Mispredict_Flag(Mispredict_Flag),
        .PCSrcE(PCSrcE)
    );

    Branch_Monitor branch_monitor (
        .Predicted_PCE(Predicted_PCE),
        .ALUResultE(ALUResultE_Final),
        .Pop_EnableE(Pop_EnableE),
        .Mispredict_Flag(Mispredict_Flag)
    );

    Register_EX_MEM ex_mem_reg (
        .i_Clk(clk),
        .rst_n(rst_n),
        .StallM(StallM),
        .RegWriteE(RegWriteE),
        .ResultSrcE(ResultSrcE),
        .MemWriteE(MemWriteE),
        .ALUResultE(ALUResultE_Final),
        .WriteDataE(Formatted_SrcBE),
        .RdE(RdE),
        .funct3E(funct3E),
        .PCPlus4E(PCPlus4E),
        // Outputs
        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .MemWriteM(MemWriteM),
        .ALUResultM(ALUResultM),
        .WriteDataM(WriteDataM),
        .RdM(RdM),
        .funct3M(funct3M),
        .PCPlus4M(PCPlus4M)
    );

    // =========================================================================
    // 6. MEMORY STAGE (MEM)
    // =========================================================================

    LSU load_store_unit (
        .funct3M(funct3M),
        .ALUResultM(ALUResultM[1:0]),
        .RD(ReadDataM_raw),
        .BW(BW),
        .Formatted_ReadDataM(ReadDataM_formatted)
    );

    Register_MEM_WB mem_wb_reg (
        .i_Clk(clk),
        .rst_n(rst_n),
        .StallW(StallM),
        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .ALUResultM(ALUResultM),
        .Formatted_RD(ReadDataM_formatted),
        .RdM(RdM),
        .PCPlus4M(PCPlus4M),
        // Outputs
        .RegWriteW(RegWriteW),
        .ResultSrcW(ResultSrcW),
        .ALUResultW(ALUResultW),
        .ReadDataW(ReadDataW),
        .RdW(RdW),
        .PCPlus4W(PCPlus4W)
    );

    // =========================================================================
    // 7. WRITEBACK STAGE (WB)
    // =========================================================================

    Mux_ResultSrcW mux_result_w (
        .ResultSrcW(ResultSrcW),
        .ALUResultW(ALUResultW),
        .ReadDataW(ReadDataW),
        .PCPlus4W(PCPlus4W),
        .ALUResultE(ResultW)
    );

    // =========================================================================
    // 8. HAZARD UNIT
    // =========================================================================

    Hazard_Unit hazard_unit (
        .Rs1E(Rs1E),
        .Rs2E(Rs2E),
        .RdM(RdM),
        .RdW(RdW),
        .RegWriteM(RegWriteM),
        .RegWriteW(RegWriteW),
        .Mispredict_Flag(Mispredict_Flag),
        .Rs1D(Rs1D),
        .Rs2D(Rs2D),
        .RdE(RdE),
        .ResultSrcE(ResultSrcE),
        .PCSrcE(PCSrcE),
        .d_req(d_req),
        .d_ready(d_ready),
        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE),
        .StallF(StallF),
        .StallD(StallD),
        .StallE(StallE),
        .StallM(StallM),
        .FlushD(FlushD),
        .FlushE(FlushE)
    );

    assign o_mispredict_flag = Mispredict_Flag;

endmodule