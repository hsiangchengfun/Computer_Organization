`timescale 1ns/1ps
module Pipeline_CPU(
    clk_i,
    rst_i
);

//I/O port
input         clk_i;
input         rst_i;

//Internal Signals
wire [31:0] PC_i;
wire [31:0] PC_o;
wire [31:0] MUXMemtoReg_o;
wire [31:0] ALUResult;
wire [31:0] MUXALUSrc_o;
wire [31:0] Decoder_o;
wire [31:0] RSdata_o;
wire [31:0] RTdata_o;
wire [31:0] Imm_Gen_o;
wire [31:0] ALUSrc1_o;
wire [31:0] ALUSrc2_o;
wire [7:0]  MUX_control_o;

wire [31:0] PC_Add_Immediate;
wire [1:0] ALUOp;
wire PC_write;
wire ALUSrc;
wire RegWrite;
wire Branch;
wire MUXControl; // generated by hazard detection unit
wire Jump;
wire [31:0] SL1_o;
wire [3:0] ALU_Ctrl_o;
wire ALU_zero;
wire Branch_zero;
wire MUXPCSrc;
wire [31:0] DM_o;
wire MemtoReg, MemRead, MemWrite;
wire [1:0] ForwardA;
wire [1:0] ForwardB;
wire [31:0] PC_Add4;

reg [32-1:0]Branch_adder_o;
assign Branch_zero = (Branch_adder_o == 0);

wire inverse_src2;
assign inverse_src2 = 32'd0 - RTdata_o;

//Pipeline Register Signals
//IFID
wire [31:0] IFID_PC_o;
wire [31:0] IFID_Instr_o;
wire IFID_Write;
wire IFID_Flush;
wire [31:0]IFID_PC_Add4_o;

//IDEXE
wire [31:0] IDEXE_Instr_o;
wire [2:0] IDEXE_WB_o;
wire [1:0] IDEXE_Mem_o;
wire [2:0] IDEXE_Exe_o;
wire [31:0] IDEXE_PC_o;
wire [31:0] IDEXE_RSdata_o;
wire [31:0] IDEXE_RTdata_o;
wire [31:0] IDEXE_ImmGen_o;
wire [3:0] IDEXE_Instr_30_14_12_o;
wire [4:0] IDEXE_Instr_11_7_o;
wire [31:0]IDEXE_PC_add4_o;

//EXEMEM
wire [31:0] EXEMEM_Instr_o;
wire [2:0] EXEMEM_WB_o;
wire [1:0] EXEMEM_Mem_o;
wire [31:0] EXEMEM_PCsum_o;
wire EXEMEM_Zero_o;
wire [31:0] EXEMEM_ALUResult_o;
wire [31:0] EXEMEM_RTdata_o;
wire [4:0]  EXEMEM_Instr_11_7_o;
wire [31:0] EXEMEM_PC_Add4_o;

//MEMWB
wire [2:0] MEMWB_WB_o;
wire [31:0] MEMWB_DM_o;
wire [31:0] MEMWB_ALUresult_o;
wire [4:0]  MEMWB_Instr_11_7_o;
wire [31:0] MEMWB_PC_Add4_o;


// IF
MUX_2to1 MUX_PCSrc(
    .data0_i(IDEXE_PC_add4_o),
    .data1_i(PC_Add4),
    .select_i(),
    .data_o(pc_i)
);

ProgramCounter PC(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .PCWrite(PC_write),
    .pc_i(pc_i),
    .pc_o(pc_o)
);

Adder PC_plus_4_Adder(
    .src1_i(pc_o),
    .src2_i(32'd4),
    .sum_o(PC_Add4)
);

Instr_Memory IM(
    .addr_i(pc_o),
    .instr_o(instr)
);

IFID_register IFtoID(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .flush(),
    .IFID_write(),
    .address_i(),
    .instr_i(),
    .pc_add4_i(),

    .address_o(),
    .instr_o(),
    .pc_add4_o()
);

// ID
Hazard_detection Hazard_detection_obj(
    .IFID_regRs(),
    .IFID_regRt(),
    .IDEXE_regRd(),
    .IDEXE_memRead(),
    .PC_write(),
    .IFID_write(),
    .control_output_select()
);

MUX_2to1 MUX_control(
    .data0_i(),
    .data1_i(),
    .select_i(),
    .data_o()
);

Decoder Decoder(
    .instr_i(instr[6:0]),
    .RegWrite(RegWrite),
    .Branch(Branch),
    .Jump(Jump),
    .MemtoReg(MemtoReg)
    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .ALUSrc(ALUSrc)
    .ALUOp(ALUOp)
);

Reg_File RF(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .RSaddr_i(instr[19:15]),
    .RTaddr_i(instr[24:20]),
    .RDaddr_i(instr[11:7]),
    .RDdata_i(),
    .RegWrite_i(RegWrite),
    .RSdata_o(RSdata_o),
    .RTdata_o(RTdata_o)
);

Imm_Gen ImmGen(
    .instr_i(instr),
    .Imm_Gen_o(Imm_Gen_o)
);

Shift_Left_1 SL1(
    .data_i(),
    .data_o()
);

Adder Branch_Adder(
    .src1_i(RSdata_o),
    .src2_i(inverse_src2),
    .sum_o(Branch_adder_o)
);

IDEXE_register IDtoEXE(
    .clk_i(),
    .rst_i(),
    .instr_i(),
    .WB_i(),
    .Mem_i(),
    .Exe_i(),
    .data1_i(),
    .data2_i(),
    .immgen_i(),
    .alu_ctrl_instr(),
    .WBreg_i(),
    .pc_add4_i(),

    .instr_o(),
    .WB_o(),
    .Mem_o(),
    .Exe_o(),
    .data1_o(),
    .data2_o(),
    .immgen_o(),
    .alu_ctrl_input(),
    .WBreg_o(),
    .pc_add4_o()
);

// EXE
MUX_2to1 MUX_ALUSrc(
    .data0_i(),
    .data1_i(),
    .select_i(),
    .data_o()
);

ForwardingUnit FWUnit(
    .IDEXE_RS1(),
    .IDEXE_RS2(),
    .EXEMEM_RD(),
    .MEMWB_RD(),
    .EXEMEM_RegWrite(),
    .MEMWB_RegWrite(),
    .ForwardA(),
    .ForwardB()
);

MUX_3to1 MUX_ALU_src1(
    .data0_i(),
    .data1_i(),
    .data2_i(),
    .select_i(),
    .data_o()
);

MUX_3to1 MUX_ALU_src2(
    .data0_i(),
    .data1_i(),
    .data2_i(),
    .select_i(),
    .data_o()
);

ALU_Ctrl ALU_Ctrl(
    .instr(),
    .ALUOp(),
    .ALU_Ctrl_o()
);

alu alu(
    .rst_n(),
    .src1(),
    .src2(),
    .ALU_control(),
    .result(),
    .zero() 
);

EXEMEM_register EXEtoMEM(
    .clk_i(),
	.rst_i(),
	.instr_i(),
	.WB_i(),
	.Mem_i(),
	.zero_i(),
	.alu_ans_i(),
	.rtdata_i(),
	.WBreg_i(),
	.pc_add4_i(),

	.instr_o(),
	.WB_o(),
	.Mem_o(),
	.zero_o(),
	.alu_ans_o(),
	.rtdata_o(),
	.WBreg_o(),
	.pc_add4_o()
);

// MEM
Data_Memory Data_Memory(
    .clk_i(),
    .addr_i(),
    .data_i(),
    .MemRead_i(),
    .MemWrite_i(),
    .data_o()
);

MEMWB_register MEMtoWB(
    .clk_i()
    .rst_i(),
    .WB_i(),
    .DM_i(),
    .alu_ans_i(),
    .WBreg_i(),
    .pc_add4_i(),

    .WB_o(),
    .DM_o(),
    .alu_ans_o(),
    .WBreg_o(),
    .pc_add4_o()
);

// WB
MUX_3to1 MUX_MemtoReg(
    .data0_i(),
    .data1_i(),
    .data2_i(),
    .select_i(),
    .data_o()
);

endmodule



