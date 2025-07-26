`timescale 1ns/1ps
 import riscv_pkg::*;

module Register_File (  
  input clk,
  // from MEM_WB
  input RegWrite, 
  input reg_idx_t rd,               // "r" denotes index             
  input logic `reg_size Rd,         // "R" denotes value  
  // from IF_ID
  input reg_idx_t rs1, rs2,
  // to ID_EX
  output logic `reg_size Rs1, Rs2, 

  // for debugging
  input reg_idx_t debug_addr_RF,
  output `reg_size debug_data_RF
);

  // create a memory array 
  logic [31:0] RegMem `reg_size;

  initial foreach (RegMem[i])
    RegMem[i] = i; 

  // for debugging
  assign debug_data_RF = RegMem[debug_addr_RF];

  // Read
  always_comb begin
    Rs1 = RegMem[rs1];
    Rs2 = RegMem[rs2]; 
  end

  // Write
  always_ff @(posedge clk) begin
    if (RegWrite && (rd != 0)) 
      RegMem[rd] <= Rd;
  end

endmodule
