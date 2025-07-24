`timescale 1ns/1ps
import riscv_pkg::*;

module Hazard_Unit (
  // from ID_EX
  input MReg_sel_e MReg, // if from_DataMem, then LW
  input reg_idx_t rd,
  // from IF_ID
  input reg_idx_t rs1, rs2,

  // direct wired-connection
  output logic Stall
);

  always_comb begin
    Stall = 0;
    if (MReg == from_DataMem)
      if (rd != 0 && ((rd == rs1) || (rd == rs2)))
        Stall = 1;
  end 

endmodule