`timescale 1ns/1ps;
import riscv_pkg::*;

module Control_Unit (
  // from InstrFile
  input opcode_e opcode, 
  input funct3_e funct3,
  // to RegFile
  output logic RegWrite,
  // to DataFile
  output DataMem_sel_e DataMem_RW, 
  output MReg_sel_e MReg,
  // to PC
  output PC_sel_e PC_sel,
  // to ALU
  output logic is_R
);
  
  always_comb begin
    case (opcode)
      OP_R: begin
        RegWrite = 1;
        DataMem_RW = Read;
        MReg = from_ALU;
        PC_sel = PC_4;
        is_R = 1;
      end
      OP_I: begin
        RegWrite = 1;
        DataMem_RW = Read;
        if (funct3 == F3_LW_SW) 
          MReg = from_DataMem;
        else
          MReg = from_ALU;
        PC_sel = PC_4;
        is_R = 0;
      end 
      OP_S: begin
        RegWrite = 0;
        DataMem_RW = Write;
        MReg = from_ALU; // RegWrite = 0, no harm 
        PC_sel = PC_4;
        is_R = 0; 
      end 
      OP_B: begin
        RegWrite = 0;
        DataMem_RW = Read; // RegWrite = 0, no harm 
        MReg = from_ALU;	   // RegWrite = 0, no harm 
        PC_sel = PC_BEQ;
        is_R = 1; 
      end 
      OP_J: begin
        RegWrite = 0;
        DataMem_RW = Read; // RegWrite = 0, no harm 
        MReg = from_ALU;   // RegWrite = 0, no harm 
        PC_sel = PC_J;
        is_R = 0; 
      end 
      default: begin
      	RegWrite = 0;
        DataMem_RW = Read;
        MReg = from_ALU;
        PC_sel = PC_4; // important to debug, so "x" here alone.
        is_R = 0; 
      end
    endcase
  end

endmodule