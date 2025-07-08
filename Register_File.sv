`timescale 1ns/1ps
import riscv_pkg::*;

module Register_File (  
  input clk,
  // control signal
  input RegWrite,
  // from InstrFile
  input reg_idx_t rs1, rs2, rd, // "r" denotes index
  // from DataFle->MUX_MReg
  input `reg_size Rd,		  // "R" denotes value 
  // to ALU
  output logic `reg_size Rs1, Rs2  // "R" denotes value 
);
  
  // create a memory array 
  logic [31:0] RegMem `reg_size;
  initial
    foreach (RegMem[i])
      RegMem[i] = i; 
  
  // Read
  always_comb begin
    Rs1 = RegMem[rs1];
    Rs2 = RegMem[rs2]; 
  end
  
  // Write
  always_ff @(posedge clk) begin
    if (RegWrite) 
      RegMem[rd] <= Rd;
  end

endmodule
