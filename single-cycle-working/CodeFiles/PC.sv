`timescale 1ns/1ps
import riscv_pkg::*;

module PC (
  input clk,
  // control signal
  input PC_sel_e PC_sel,
  // from ALU
  input logic branch_taken,
  // from imd_gen
  input `reg_size imm32,
  // to InstrFile
  output wire `reg_size PC_Out
 
  logic `reg_size PC = 0; // set @ initial 
  assign PC_Out  = PC; 
  
  always_ff @(posedge clk) begin
    case (PC_sel) 
      PC_4    : PC <= PC + 4;
      PC_BEQ: begin
        case (branch_taken)
          0: PC <= PC + 4;
          1: PC <= PC + imm32;
        endcase
      end
      PC_J: PC <= PC + imm32;
    endcase
  end
  
endmodule
