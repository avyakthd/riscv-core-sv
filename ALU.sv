`timescale 1ns/1ps
import riscv_pkg::*;

module ALU (
    // control signal
  	input is_R, 
  	// from RegFile, imd_gen
    input `reg_size Rs1, Rs2, imm32,
  	// from ALU_Ctl
    input alu_op_e ALU_Op,
    // to PC
    output logic is_equal,
  	// to DataFile, DataFile->MUX_MReg
    output logic `reg_size ALU_Result // needs to be logic, used inside always_comb
);
  wire `reg_size ALU_inA, ALU_inB;
  assign ALU_inA = Rs1;
  assign ALU_inB = is_R ? Rs2 : imm32;
  
  always_comb begin
    case (ALU_Op)
      ADD : ALU_Result = ALU_inA + ALU_inB;
      SUB : begin
        ALU_Result = ALU_inA - ALU_inB;
        is_equal = (ALU_Result == 0) ? 1 : 0;
      end
      AND : ALU_Result = ALU_inA & ALU_inB;
      OR  : ALU_Result = ALU_inA | ALU_inB;
      XOR : ALU_Result = ALU_inA ^ ALU_inB;
    endcase 
  end
  
endmodule   