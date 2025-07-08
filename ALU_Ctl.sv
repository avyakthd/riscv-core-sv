// Code your design here
`timescale 1ns/1ps
import riscv_pkg::*;

module ALU_Ctl (
  input opcode_e opcode,
  input funct3_e funct3,
  input funct7_e funct7,
  // to ALU
  output alu_op_e ALU_Op
);
  
  always_comb begin
    case (opcode)
      OP_R: begin
          case (funct3)
            F3_ADD_SUB_BEQ : begin
              if (funct7 == F7_ADD) ALU_Op = ADD;
              else					ALU_Op = SUB;
            end
            F3_AND: ALU_Op = AND ;
            F3_OR:  ALU_Op = OR ;
            F3_XOR: ALU_Op = XOR ;
          endcase
        end
      OP_I: 
        case (funct3)
          F3_ADD_SUB_BEQ : ALU_Op = ADD ;
          F3_AND    : ALU_Op = AND ;
          F3_OR		:  ALU_Op = OR ;
          F3_XOR	: ALU_Op = XOR ;
          F3_LW_SW	:  ALU_Op = ADD ;
        endcase
      OP_S: if (funct3 == F3_LW_SW)  		ALU_Op = ADD ;
      OP_B: if (funct3 == F3_ADD_SUB_BEQ)   ALU_Op = SUB ;
   	  // OP_J: not needed
    endcase
  end

endmodule 

