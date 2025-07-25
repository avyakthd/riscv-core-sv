`timescale 1ns/1ps
import riscv_pkg::*;

module Hazard_Unit (
  // from ID_EX
  input MReg_sel_e MReg, // if from_DataMem, then LW
  input reg_idx_t rd,
  // from IF_ID
  input reg_idx_t rs1, rs2,
  // from Top.sv
  input uses_rs1, uses_rs2,
  // direct wired-connection
  output logic Stall
);

  always_comb begin
    Stall = 0;
    if (MReg == from_DataMem && rd != 0) begin
      if (uses_rs1 && (rd == rs1))
        Stall = 1;
      else if (uses_rs2 && (rd == rs2))
        Stall = 1;
    end
  end
  
endmodule
