`timescale 1ns/1ps

package riscv_pkg;

  // for ease of use
  typedef enum logic[2:0] {
  	
    F3_ADD_SUB_BEQ = 3'b000,
    F3_AND = 3'b111,
    F3_OR = 3'b110,
    F3_XOR = 3'b100,
    F3_LW_SW = 3'b010
    
  } funct3_e;
  
  typedef enum logic [6:0] {
    
    F7_ADD = 7'b0,
    F7_SUB = 7'b0100000 // -> not needed: only 2 mutually excl. choices- ADD, SUB 
    
  } funct7_e;
  
  typedef enum logic [6:0] {
  
  	OP_R = 7'b0110011,
    OP_I = 7'b0010011,
    OP_S = 7'b0100011,
    OP_B = 7'b1100011,
    OP_J = 7'b1101111 // not needed for the ALU
    
  } opcode_e; 
  
  typedef enum logic [2:0] {
  
  	ADD = 3'b000,
    SUB = 3'b001, 
    AND = 3'b010,
    OR  = 3'b011,
    XOR = 3'b100
    
  } alu_op_e;
  
   typedef enum logic [1:0] {

    PC_4   = 2'b0,
    PC_BEQ = 2'b1,
    PC_J   = 2'b10

  } PC_sel_e;

  typedef enum logic {

    Read     = 1'b0,
    Write    = 1'b1

  } DataMem_sel_e; 

  typedef enum logic {

    from_ALU     = 1'b0,
    from_DataMem = 1'b1

  } MReg_sel_e; 
	
  typedef logic [4:0] reg_idx_t;
  
`define reg_size [31:0]
	
endpackage;
