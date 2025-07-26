`timescale 1ns/1ps
import riscv_pkg::*;

module Forwarding_Unit (
  
  // from ID_EX
  input reg_idx_t rs1, rs2,
  // from EX_MEM
  input reg_idx_t ex_mem_rd,
  input logic ex_mem_regwrite,
  input MReg_sel_e ex_mem_MReg,
  // from MEM_WB
  input reg_idx_t mem_wb_rd,
  input logic mem_wb_regwrite,
  // to ALU, not thru pipeline-reg
  output fwd_e ForwardA, 
  output fwd_e ForwardB, // for ALU's 2nd input
  output fwd_e ForwardS  // for SW's Rs2 
  
);
      
  // clock-alignment taken care of by the pipeline-registers (Top.sv)
  always_comb begin
    if ((rs1 == ex_mem_rd) & (ex_mem_rd !=0) & (ex_mem_regwrite) & (ex_mem_MReg != from_DataMem))
      ForwardA = from_ex_mem;
    else if ((rs1 == mem_wb_rd) & (mem_wb_rd !=0) & (mem_wb_regwrite))
      ForwardA = from_mem_wb;
    else 
      ForwardA = from_Reg;
    
    if ((rs2 == ex_mem_rd) & (ex_mem_rd !=0) & (ex_mem_regwrite) & (ex_mem_MReg != from_DataMem))
      ForwardB = from_ex_mem;
    else if ((rs2 == mem_wb_rd) & (mem_wb_rd !=0) & (mem_wb_regwrite)) 
      ForwardB = from_mem_wb;
    else 
      ForwardB = from_Reg;
    
    if ((rs2 == ex_mem_rd) & ex_mem_regwrite & (ex_mem_rd !=0) & (ex_mem_MReg != from_DataMem))
      ForwardS = from_ex_mem;
    else if ((rs2 == mem_wb_rd) & (mem_wb_rd !=0) & mem_wb_regwrite)
      ForwardS = from_mem_wb;
    else
      ForwardS = from_Reg; 
  end
  
endmodule
