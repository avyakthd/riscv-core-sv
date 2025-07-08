// Code your testbench here
// or browse Examples
`timescale 1ns/1ps
import riscv_pkg::*;

//`include "alu_tb.sv"
module tb;
  
  // inputs and outputs
  logic clk;
  PC_sel_e PC_sel;
  logic is_equal; 
  logic `reg_size Rs1, Rs2, imm32; 
  logic `reg_size PC_Out; 
  
  logic `reg_size Instr_Out;
  reg_idx_t rs1, rs2, rd; 
  opcode_e opcode;
  funct7_e funct7;
  funct3_e funct3;
  
  logic RegWrite; 
  DataMem_sel_e DataMem_RW;
  MReg_sel_e MReg; 
  logic is_R; 
  
  logic `reg_size Rd;
  
  alu_op_e ALU_Op; 
  
  logic `reg_size ALU_Result;  
  
  
  // module instantiation
  ALU_Ctl u1 (.opcode(opcode), .funct7(funct7), .funct3(funct3), .ALU_Op(ALU_Op));
  
  ALU u2 (.Rs1(Rs1), .Rs2(Rs2), .imm32(imm32), .is_R(is_R), .ALU_Op(ALU_Op), .ALU_Result(ALU_Result), .is_equal(is_equal));
  
  PC u3 (.clk(clk), .PC_sel(PC_sel), .imm32 (imm32 ), .PC_Out (PC_Out), .is_equal(is_equal)); 
  Register_File u4(.clk(clk), .RegWrite(RegWrite), .rs1(rs1), .rs2(rs2), .rd(rd), .Rd(Rd), .Rs1(Rs1), .Rs2(Rs2));
  
  InstrFile u5 (.PC_Out (PC_Out ), .Instr_Out (Instr_Out ), .rs1(rs1), .rs2(rs2), .rd(rd), .opcode(opcode), .funct3(funct3), .funct7(funct7));
  
  imd_gen u6 (.Instr_Out(Instr_Out), .imm32(imm32));
  
  Control_Unit u7 (.opcode(opcode), .funct3(funct3), .RegWrite(RegWrite), .DataMem_RW(DataMem_RW), .MReg(MReg), .PC_sel(PC_sel), .is_R(is_R));
  
  DataFile u8 (.clk(clk), .DataMem_RW(DataMem_RW), .MReg(MReg), .ALU_Result(ALU_Result), .Rs2(Rs2), .Rd(Rd));
  
  //initial begin
  //  $dumpfile("dump.vcd"); 
  //  $dumpvars(0, tb); // 0 -> dump every signal in the module 
  //end
  
  initial clk = 1;
  always #5 clk = ~clk;
  
  // for debugging
  string Instr_str, PC_sel_str, DataMem_str, MReg_str, opcode_str;
  always_comb begin
    
    case (opcode)
      OP_R: opcode_str = "R-Type";
      OP_I: opcode_str = "I-Type"; 
      OP_S: opcode_str = "S-Type"; 
      OP_B: opcode_str = "B-Type"; 
	  OP_J: opcode_str = "J-Type"; 
    endcase
        
    case (ALU_Op)
      ADD: 		Instr_str  = "ADD";
      SUB: 		Instr_str  = "SUB";
      AND: 		Instr_str  = "AND"; 
      OR : 		Instr_str  = "OR" ; 
      XOR: 		Instr_str  = "XOR"; 
      //default: 	Instr_str  = "???";
    endcase
    
    case (PC_sel)	
      PC_4	:  PC_sel_str = "PC_4"	  ;
      PC_BEQ:  PC_sel_str = "PC_BEQ_J";
      PC_J  :  PC_sel_str = "PC_J"    ;
    endcase
    
    case (DataMem_RW)
      Read : DataMem_str = "Read" ;
      Write: DataMem_str = "Write";
    endcase
    
    case (MReg)
      from_ALU	  : MReg_str = "from ALU"	 ;
      from_DataMem: MReg_str = "from DataMem";
    endcase
  end
	
  // testcases
  initial begin
  	// case 0: begin
    #10;
    // case 1
    $display("[%0d] initial PC = %0d", $time, PC_Out); 
    $display("Instruction: %b, is_R: %h", Instr_Out, is_R);
	$display("Opcode = %s, ALU_Op = %s", opcode_str, Instr_str);  
    $display("imm_r (default) = %h", imm32); 
    $display("R[%0d] = R[%0d] + R[%0d] = %0d + %0d = %0d", rd, rs1, rs2, Rs1, Rs2, ALU_Result);
    $display("");
    #10;
    //case 2
    $display("[%0d] PC=%0d", $time, PC_Out);
    $display("Instruction: %b, is_R: %h", Instr_Out, is_R);  
	$display("Opcode = %s, ALU_Op = %s", opcode_str, Instr_str);  
    $display("imm_i = %h", imm32); 
    $display("R[%0d] = R[%0d] | imm_i = %h | %h = %h", rd, rs1, Rs1, imm32, ALU_Result);
    $display(""); 
    #10;
    //case 3
    $display("[%0d] PC=%0d", $time, PC_Out);  
    $display("Instruction: %b, is_R: %h", Instr_Out, is_R);     	$display("Opcode = %s, ALU_Op = %s", opcode_str, Instr_str); 
    $display("imm_s = %h", imm32); 
    $display("Mem[imm_s + R[%0d]] = Mem[%0h + %0h] = Mem[%0h] = R[%0d] = %0h", rs1, imm32, Rs1, ALU_Result, rs2, Rs2);
    $display(""); 
    #10;
    // case 4
    $display("[%0d] PC=%0d", $time, PC_Out);  
    $display("Instruction: %b, is_R: %h", Instr_Out, is_R);  
	$display("Opcode = %s, ALU_Op = %s", opcode_str, Instr_str);  
    $display("imm_i = %h", imm32); 
    $display("R[%0d] = Mem[imm_i + R[%0d]] = Mem[%0h + %0h] = Mem[%0h] = %0h", rd, rs1, imm32, Rs1, ALU_Result, Rd);
    $display(""); 
    #10;
    // case 5
    $display("[%0d] PC=%0d", $time, PC_Out);  
    $display("Instruction: %b, is_R: %h", Instr_Out, is_R);  
	$display("Opcode = %s, ALU_Op = %s", opcode_str, Instr_str);  
    $display("imm_b = %h", imm32);
    $display("ALU_Result = R[%0d] - R[%0d] = %h - %h = %0h",rs1, rs2, Rs1, Rs2, ALU_Result);
    $display("Expected PC = %0d", PC_Out + imm32); 
    $display(""); 
    #10;
    // case 6
    $display("[%0d] PC=%0d, imm32=%0d", $time, PC_Out, imm32);
    $display("Instruction: %b, is_R: %h", Instr_Out, is_R);  
	$display("Opcode = %s, ALU_Op = %s", opcode_str, Instr_str);  
    $display("imm_j = %h", imm32); 
    $display("Expected PC = %0d", PC_Out + imm32);
    $display(""); 
    #10;
    // case 7: end
    $display("[%0d] Final PC = %0d", $time, PC_Out); 
    $display("Instruction: %h_%h_%h, is_R: %h", Instr_Out[31:28], Instr_Out[27:12], Instr_Out[11:0], is_R);  
	$display("Opcode = %s, ALU_Op = %s", opcode_str, Instr_str);  
    $display(""); 
	$finish;
  end
endmodule 