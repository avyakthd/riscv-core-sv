`timescale 1ns/1ps
import riscv_pkg::*;

module imd_gen (
  // from IF_ID
  input `reg_size Instr_Out,
  // to ID_EX
  output logic signed `reg_size imm32
) ;
  
  // slicing the lists externally, as 
  //always_comb doesn't support slicing in this version of iverilog. 
  //also, the intent is clearer this way
  wire [11:0] imm_I = Instr_Out [31:20];
  wire [11:0] imm_S = {Instr_Out [31:25], Instr_Out [11:7]};
  wire [12:0] imm_B = {Instr_Out [31], Instr_Out [7], Instr_Out [30:25], Instr_Out [11:8], 1'b0};
  wire [20:0] imm_J = {Instr_Out [31], Instr_Out [19:12], Instr_Out [20], Instr_Out [30:21], 1'b0};

  always @(*) begin // implicit sign-extension
    case (opcode_e'(Instr_Out[6:0]))
      OP_I: imm32   = $signed(imm_I);
      OP_S: imm32   = $signed(imm_S);
      OP_B: imm32   = $signed(imm_B);
      OP_J: imm32   = $signed(imm_J); 
      default: imm32   = 32'h12;
    endcase
  end
  
endmodule
