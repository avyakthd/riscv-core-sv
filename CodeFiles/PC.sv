`timescale 1ns/1ps
import riscv_pkg::*;

module PC (
  input clk,
  // from Hazard Unit
  input PCWrite,
  // from Top
  input `reg_size PC_in,
  // to IF_ID
  output logic `reg_size PC_Out
);
 
  logic `reg_size PC = 0; // set @ initial 
  assign PC_Out = PC; 
  
  always_ff @ (posedge clk) begin
    if (PCWrite)
      PC <= PC_in;
  
endmodule
