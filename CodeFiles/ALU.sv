`timescale 1ns/1ps
import riscv_pkg::*;

module ALU (
    // from ID_EX
    input is_R, 
    input opcode_e opcode,
    input `reg_size Rs1, Rs2_imm32, // Rs2 & imm32 multiplexed into one
    input alu_op_e ALU_Op,
    // for forwarding
    input fwd_e ForwardA, ForwardB,
    input `reg_size ex_mem_A, mem_wb_A, ex_mem_B, mem_wb_B,
    // to PC
    output logic is_equal,		// not passed thru a pipeline-reg
    `// to PC, EX_MEM
    output logic `reg_size ALU_Result // needs to be logic, used inside always_comb
);
  logic `reg_size ALU_inA, ALU_inB;
  
  always_comb begin
    case (ForwardA)
      from_Reg   : ALU_inA = Rs1;
      from_ex_mem: ALU_inA = ex_mem_A;
      from_mem_wb: ALU_inA = mem_wb_A;
    endcase
    
    if (opcode == OP_S)
        ALU_inB = Rs2_imm32; 
    else
      case (ForwardB)
          from_Reg   : ALU_inB = Rs2_imm32;
          from_ex_mem: ALU_inB = ex_mem_B;
          from_mem_wb: ALU_inB = mem_wb_B;
      endcase
  end
  
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
