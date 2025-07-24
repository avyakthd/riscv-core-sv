`timescale 1ns/1ps
import riscv_pkg::*;


module Top (
  input clk,
  input rst,
  // FOR DEBUGGING //
  input reg_idx_t debug_addr_RF,
  input logic `reg_size debug_addr_DF, 
  output logic `reg_size debug_data_RF,debug_data_DF
);

  /* ----------------------------- */
  /* PIPELINE REGISTER DECLARATION */
  /* ----------------------------- */ 

  IF_ID_t   IF_ID_R;
  ID_EX_t   ID_EX_R;
  EX_MEM_t  EX_MEM_R;
  MEM_WB_t  MEM_WB_R;

  /* ---------------------------- */
  /* WIRES CONNECTING THE MODULES */
  /* ---------------------------- */    

  logic `reg_size PC_Out, Instr_Out;
  logic `reg_size PC_next, PC_4, PC_branch;
  logic branch_taken;
  logic Stall, Flush;
  opcode_e opcode;
  funct3_e funct3;
  funct7_e funct7;
  reg_idx_t rs1, rs2, rd;
  // no explicit IF_ID_Write signal 
  alu_op_e ALU_Op;
  logic RegWrite;
  DataMem_sel_e DataMem_RW;
  MReg_sel_e MReg;
  PC_sel_e PC_sel;
  logic is_R;
  fwd_e ForwardA, ForwardB, ForwardS;
  logic `reg_size Rs1, Rs2;
  logic `reg_size imm32;
  logic `reg_size Rs2_imm32;
  logic `reg_size ALU_Result;
  logic is_equal;
  logic `reg_size Rd;
  logic `reg_size Rs2_fwd;


  /*----------------------*/  
  /* MODULE INSTANTIATION */
  /*----------------------*/

  PC uPC (
    .clk(clk),
    .rst(rst),
    .Stall(Stall),
    .PC_in(PC_next),
    .PC_Out(PC_Out)
  );

  InstrFile uIF (
    .PC_Out(PC_Out),
    .Instr_Out(Instr_Out)
  );

  Control_Unit uCU (
    .Stall(Stall),
    .opcode(opcode),
    .funct3(funct3),
    .RegWrite(RegWrite),
    .DataMem_RW(DataMem_RW),
    .MReg(MReg),
    .PC_sel(PC_sel),
    .is_R(is_R)
  );

  imd_gen uIG (
    .Instr_Out(IF_ID_R.instr32),
    .imm32(imm32)
  );

  Hazard_Unit uHU (
    .MReg(ID_EX_R.MReg),
    .rd(ID_EX_R.rd),
    .rs1(rs1), 
    .rs2(rs2),
    .Stall(Stall)
  );

  ALU_Ctl uAC (
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .ALU_Op(ALU_Op)
  );

  Register_File uRF (
    .clk(clk),
    .rst(rst),
    .RegWrite(MEM_WB_R.RegWrite), 
    .rd(MEM_WB_R.rd), 
    .Rd(MEM_WB_R.Rd),
    .rs1(rs1), 
    .rs2(rs2),
    .Rs1(Rs1), 
    .Rs2(Rs2),
    // for debugging
    .debug_addr_RF(debug_addr_RF),
    .debug_data_RF(debug_data_RF)
  );

  ALU uALU (
    .is_R(ID_EX_R.is_R), 
    .opcode(ID_EX_R.opcode),
    .Rs1(ID_EX_R.Rs1), 
    .Rs2_imm32(Rs2_imm32), 
    .ALU_Op(ID_EX_R.ALU_Op),
    .ForwardA(ForwardA), 
    .ForwardB(ForwardB),
    .ex_mem_A(EX_MEM_R.ALU_Result), 
    .mem_wb_A(MEM_WB_R.Rd), 
    .ex_mem_B(EX_MEM_R.ALU_Result), 
    .mem_wb_B(MEM_WB_R.Rd), 
    .is_equal(is_equal),
    .ALU_Result(ALU_Result)
  );

  Forwarding_Unit uFU (
    .rs1(ID_EX_R.rs1), 
    .rs2(ID_EX_R.rs2),
    .ex_mem_rd(EX_MEM_R.rd), 
    .ex_mem_regwrite(EX_MEM_R.RegWrite),
    .ex_mem_MReg(EX_MEM_R.MReg),
    .mem_wb_rd(MEM_WB_R.rd), 
    .mem_wb_regwrite(MEM_WB_R.RegWrite),
    .ForwardA(ForwardA), 
    .ForwardB(ForwardB), 
    .ForwardS(ForwardS) // for S-Type
  );

  DataFile uDF (
    .clk(clk),
    .DataMem_RW(EX_MEM_R.DataMem_RW), 
    .MReg(EX_MEM_R.MReg), 
    .ALU_Result(EX_MEM_R.ALU_Result), 
    .Rs2(EX_MEM_R.Rs2), 
    .Rd(Rd),
    // for debugging
    .debug_addr_DF(debug_addr_DF),
    .debug_data_DF(debug_data_DF)
  );

  /*------------------*/
  /*INSTRUCTION DECODE*/
  /*------------------*/ 

  //always_comb begin -> not supported if bit-selects are used
  assign rs1 = reg_idx_t'(IF_ID_R.instr32[19:15]);
  assign rs2 = reg_idx_t'(IF_ID_R.instr32[24:20]); 
  assign rd  = reg_idx_t'(IF_ID_R.instr32[11: 7]); 

  assign opcode = opcode_e'(IF_ID_R.instr32[6:0]);
  assign funct3 = funct3_e'(IF_ID_R.instr32[14:12]);
  assign funct7 = funct7_e'(IF_ID_R.instr32[31:25]);

  assign Rs2_imm32 = ID_EX_R.is_R ? ID_EX_R.Rs2 : ID_EX_R.imm32;

  // EX //

  assign Flush = 
    ((ID_EX_R.PC_sel == PC_BEQ) & (is_equal)) || 
    (ID_EX_R.PC_sel == PC_J);

  // FORWARDING LOGIC FOR Rs2//
  always_comb
    case (ForwardS)
      from_Reg:    Rs2_fwd = ID_EX_R.Rs2;
      from_ex_mem: Rs2_fwd = EX_MEM_R.ALU_Result;
      from_mem_wb: Rs2_fwd = MEM_WB_R.Rd;
    endcase

  // ---------------- //
  // PC Control Logic //
  // ---------------- //
  always_comb begin
    PC_4 = PC_Out + 4;
    PC_branch = ID_EX_R.PC + ID_EX_R.imm32;
    case (ID_EX_R.PC_sel)
      PC_BEQ: branch_taken = is_equal? 1: 0;
      PC_J: branch_taken = 1;
      default: branch_taken = 0;
    endcase
    PC_next = branch_taken ? PC_branch : PC_4; 
  end

  /*-------------------------*/
  /* PIPELINE REGISTER LOGIC */
  /*-------------------------*/

  //IF_ID
  //always_ff @ (posedge clk) begin -> not working for some reason :(
  always @ (posedge clk or posedge rst) begin 
    if (rst)
      IF_ID_R <= 0;
    else if (Flush) 
      IF_ID_R <= 0;
    else if (~Stall) begin
      IF_ID_R.PC <= PC_Out;
      IF_ID_R.instr32 <= Instr_Out;
    end
  end

  // ID_EX
  //always_ff @(posdege clk) begin
  always @ (posedge clk or posedge rst) begin 
    if (rst)
      ID_EX_R <= 0;
    else if (Flush || Stall) begin // Flush takes priority over Stall
      ID_EX_R.RegWrite <= 0;
      ID_EX_R.DataMem_RW <= Read;
      ID_EX_R.rd <= 0; 
      ID_EX_R.PC_sel <= PC_4; // to avoid partial-bubbles
    end else begin
      ID_EX_R.PC <= IF_ID_R.PC;
      ID_EX_R.opcode <= opcode;
      ID_EX_R.ALU_Op <= ALU_Op;
      ID_EX_R.RegWrite <= RegWrite;
      ID_EX_R.DataMem_RW <= DataMem_RW;
      ID_EX_R.MReg <= MReg;
      ID_EX_R.PC_sel <= PC_sel;
      ID_EX_R.Rs1 <= Rs1;
      ID_EX_R.Rs2 <= Rs2;
      ID_EX_R.imm32 <= imm32;
      ID_EX_R.is_R <= is_R;
      ID_EX_R.rs1 <= rs1;
      ID_EX_R.rs2 <= rs2;
      ID_EX_R.rd <= rd;
    end
  end

  // EX_MEM
  //always_ff @(posedge clk) begin
  always @ (posedge clk or posedge rst) begin 
    if (rst) 
      EX_MEM_R <= 0;
    else begin
      EX_MEM_R.ALU_Result <= ALU_Result;
      EX_MEM_R.DataMem_RW <= ID_EX_R.DataMem_RW;
      EX_MEM_R.MReg <= ID_EX_R.MReg;
      EX_MEM_R.Rs2 <= Rs2_fwd;
      EX_MEM_R.RegWrite <= ID_EX_R.RegWrite;
      EX_MEM_R.rd <= ID_EX_R.rd;
    end
  end

  // MEM_WB
  //always_ff @(posedge clk) begin
  always @ (posedge clk or posedge rst) begin 
    if (rst) 
      MEM_WB_R <= 0;
    else begin
      MEM_WB_R.Rd <= Rd;
      MEM_WB_R.RegWrite <= EX_MEM_R.RegWrite;
      MEM_WB_R.rd <= EX_MEM_R.rd;
    end
  end

endmodule
