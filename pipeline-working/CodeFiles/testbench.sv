`timescale 1ns/1ps
import riscv_pkg::*;
`include "Top.sv"

module tb;

  // ----------------------------------- //
  // UNCOMMENT TO GENERATE WAVEFORM FILE //
  // ----------------------------------- //
	
  //  initial begin
  //    $dumpfile("dump.vcd"); 
  //    $dumpvars(0, tb); // 0 -> dump every signal in the module 
  //  end

  logic clk;
  initial clk = 0;
  always #1 clk = ~clk; 

  Top uTop (.clk(clk), 
            .debug_addr_RF(rf_debug_addr_w), 
            .debug_addr_DF(df_debug_addr_w), 
            .debug_data_RF(rf_debug_data_w), 
            .debug_data_DF(df_debug_data_w));


    
  // FOR DEBUGGING //
  
  reg_idx_t rf_debug_addr_w;
  logic `reg_size rf_debug_data_w, df_debug_addr_w, df_debug_data_w;
  
  string FwdA, FwdB, opcode_str, Instr_str, DataMem_str, MReg_str, PC_sel_str;

  always_comb begin
    case (uTop.uFU.ForwardA)
      from_Reg: FwdA  = "from_Reg";
      from_ex_mem: FwdA  = "from_ex_mem";
      from_mem_wb: FwdA  = "from_mem_wb";
    endcase
    case (uTop.uFU.ForwardB)
      from_Reg: FwdB  = "from_Reg";
      from_ex_mem: FwdB  = "from_ex_mem";
      from_mem_wb: FwdB  = "from_mem_wb";
    endcase 
    case (uTop.ID_EX_R.opcode)
      OP_R: opcode_str = "R-Type";
      OP_I: opcode_str = "I-Type"; 
      OP_S: opcode_str = "S-Type"; 
      OP_B: opcode_str = "B-Type"; 
      OP_J: opcode_str = "J-Type"; 
    endcase 
    case (uTop.ID_EX_R.ALU_Op)
      ADD: 		Instr_str  = "ADD";
      SUB: 		Instr_str  = "SUB";
      AND: 		Instr_str  = "AND"; 
      OR : 		Instr_str  = "OR" ; 
      XOR: 		Instr_str  = "XOR"; 
      //default: 	Instr_str  = "???";
    endcase 
    case (uTop.EX_MEM_R.DataMem_RW)
      Read : DataMem_str = "Read" ;
      Write: DataMem_str = "Write";
    endcase 
    case (uTop.EX_MEM_R.MReg)
      from_ALU	  : MReg_str = "from ALU"	 ;
      from_DataMem: MReg_str = "from DataMem";
    endcase
    case (uTop.ID_EX_R.PC_sel)	
      PC_4	:  PC_sel_str = "PC_4"	  ;
      PC_BEQ:  PC_sel_str = "PC_BEQ_J";
      PC_J  :  PC_sel_str = "PC_J"    ;
    endcase 
  end


  // ----------------------- //
  // READ THE DOCUMENTATION! //
  // ----------------------- //

  // testcases
  initial begin
    #0; // vary this in steps of 2 to follow the outputs of the various instructions (or view the waveform)

    $display("");
    $display("PC debug: ");
    $display("PC_4 = %0d, PC_branch = %0d, PC_sel = %s, branch_taken = %0h, PC_next = %0d, Stall = %0h, Flush = %0h", uTop.PC_4, uTop. PC_branch, PC_sel_str, uTop.branch_taken, uTop.PC_next, uTop.uHU.Stall, uTop.Flush);

    #2;
    $display("");
    $display ("[%0d] PC = %0d, Instr = %h", $time, uTop.IF_ID_R.PC, uTop.IF_ID_R.instr32);
    
    #2;      // change to "rs2" to "imm32" and "uTop.ID_EX_R.rs2" to "uTop.ID_EX_R.imm32" for I-Type and S-Type Instructions 
    $display("[%0d] rs1 = %0h, rs2 = %0d, rd = %0d", $time,  uTop.ID_EX_R.rs1,  uTop.ID_EX_R.rs2,  uTop.ID_EX_R.rd);
    $display("ALUOp = %s, %s", Instr_str, opcode_str);
    $display("Rs1 = %0d, Rs2_imm32 = %0d", uTop.ID_EX_R.Rs1, uTop.Rs2_imm32);
    $display("EX_MEM: A = %0h, B = %0h", uTop.EX_MEM_R.ALU_Result, uTop.EX_MEM_R.ALU_Result);
    $display("MEM_WB: A = %0h, B = %0h", uTop.MEM_WB_R.Rd, uTop.MEM_WB_R.Rd);
    $display("FwdA = %s, FwdB = %s", FwdA, FwdB);
    
    #2;
    $display("[%0d] ALU_Result = %0h, DataMem_RW = %s, MReg = %s", $time, uTop.EX_MEM_R.ALU_Result, DataMem_str, MReg_str);
    
    #2;
    $display("[%0d] Rd = %0d, rd = %0d, RegWrite = %0h", $time, uTop.MEM_WB_R.Rd, uTop.MEM_WB_R.rd, uTop.MEM_WB_R.RegWrite);
    
    #2;
    // view Register_File[rf_debug_addr_w]. 
    // If you want to view DataMem[df_debug_addr_w], then change:
    // "rf_debug_addr_w" to "df_debug_addr_w", and
    // "rf_debug_data_w" to "df_debug_data_w"
    rf_debug_addr_w = 0;
    $display("[%0d] Expected Value: %0d, Actual Value: %0d", $time, 32'd0, rf_debug_data_w);
    $display(""); 
    $finish;
  end
endmodule  
