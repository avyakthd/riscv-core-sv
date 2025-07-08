`timescale 1ns/1ps
import riscv_pkg::*;

module InstrFile (
  input `reg_size PC_Out,
  output logic `reg_size Instr_Out,
  // to RegFile
  output reg_idx_t rs1, rs2, rd,
  // to ALU_Ctl
  output opcode_e opcode,
  output funct3_e funct3,
  output funct7_e funct7
  //
);
  
  // create Instruction Memory
  logic [7:0] InstrMem [43:0];
  
  localparam  [11:0] imm_i = 12'h5;
  localparam  [11:0] imm_s = 12'h5;
  localparam  [12:1] imm_b = 12'h6; // 6<<1 = 10
  localparam  [20:1] imm_j = 20'h6; // 6<<1 = 10
  
  initial begin // initialisations for now 
    // R-Type: Add
    // r2 = r1 + r0
    {InstrMem[3], InstrMem[2] , InstrMem[1], InstrMem[0]} = 
    {F7_ADD, {5'h1}, {5'h0}, F3_ADD_SUB_BEQ, {5'h2}, OP_R};
    
    //I-Type: Or
    // r3 = r2 | 5
    {InstrMem[7], InstrMem[6] , InstrMem[5], InstrMem[4]} = 
    {imm_i, 5'h2, F3_OR, 5'h3, OP_I};
    
    //S-Type
    // mem (5 + r4) = r3
    {InstrMem[11], InstrMem[10] , InstrMem[9], InstrMem[8]} = 
    {imm_s[11:5], 5'h3, 5'h4, F3_LW_SW, imm_s[4:0], OP_S};
    
    //I-Type: Load
    // r5 = mem(5 + R(r4))
    {InstrMem[15], InstrMem[14] , InstrMem[13], InstrMem[12]} = 
    {imm_i, 5'h4, F3_LW_SW, 5'h5, OP_I}; 
    
    //B-Type
    // ALU_Result = r5 - r5
    // PC = PC + imm_b
    {InstrMem[19], InstrMem[18] , InstrMem[17], InstrMem[16]} = 
    {imm_b[12], imm_b[10:5], 5'h5, 5'h5, F3_ADD_SUB_BEQ, imm_b[4:1], imm_b[11], OP_B}; 
    
    //J-Type
    // PC = PC + imm32
    {InstrMem[31], InstrMem[30] , InstrMem[29], InstrMem[28]} = 
    {imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12], 5'h9, OP_J};
    
    // dummy 
    {InstrMem[43], InstrMem[42] , InstrMem[41], InstrMem[40]}= 
    32'hA_cafe_fed_a_deaf_cab; 
  end
  
  always_comb 
    Instr_Out = {InstrMem[PC_Out +3], 
                 InstrMem[PC_Out +2], 
                 InstrMem[PC_Out +1], 
                 InstrMem[PC_Out ]} ; 
  
  // in this version of iverilog,
  // always_comb doesn't support register slicing  
  always @(*) begin
  // to RegFile
   rs2 = Instr_Out[24:20];
   rs1 = Instr_Out[19:15];
   rd  = Instr_Out[11:7] ;

  // to ALU_Ctl, Control_Unit
   opcode = opcode_e'(Instr_Out[6:0]); 
   funct3 = funct3_e'(Instr_Out[14:12]); 

  // to ALU_Ctl 
   funct7 = funct7_e'(Instr_Out[31:25]); 
  end
endmodule