`timescale 1ns/1ps
import riscv_pkg::*;

module InstrFile (
  // from PC
  input `reg_size PC_Out,
  // to IF_ID
  output logic `reg_size Instr_Out
);

  // create Instruction Memory
  logic [7:0] InstrMem [47:0];

  always_comb 
    Instr_Out = {InstrMem[PC_Out +3], 
                 InstrMem[PC_Out +2], 
                 InstrMem[PC_Out +1], 
                 InstrMem[PC_Out ]} ; 

  logic [11:0] imm_i1 = 12'hb;
  logic [11:0] imm_s = 12'hc;
  logic [11:0] imm_i2 = 12'hc;
  logic [12:1] imm_b = 12'h6; // 6 <<< 1 = 12
  logic [11:0] imm_i3 = 12'h8;
  logic [11:0] imm_i4 = 12'h9;
  logic signed [20:1] imm_j = -2; // -2 <<< 1 = -4

  // ----------------------- //
  // READ THE DOCUMENTATION! //
  // ----------------------- //

  initial begin
    //1. I-Type: Add
    // r1 = r0 + 11 -> ALU = 11
    {InstrMem[3], InstrMem[2] , InstrMem[1], InstrMem[0]} = 
    {imm_i1, {5'h0}, F3_ADD_SUB_BEQ, 5'h1, OP_I};

    //2. R-Type: Add 
    // r3 = r1 + r2 -> ALU = 13
    {InstrMem[7], InstrMem[6] , InstrMem[5], InstrMem[4]} = 
    {F7_ADD, 5'h2, 5'h1, F3_ADD_SUB_BEQ, 5'h3, OP_R};

    //3. R-Type: Add 
    // r4 = r3 + r1 -> ALU = 24
    {InstrMem[11], InstrMem[10] , InstrMem[9], InstrMem[8]} = 
    {F7_ADD, 5'h3, 5'h1, F3_ADD_SUB_BEQ, 5'h4, OP_R}; 

    //4. S-Type  
    // mem(12 + r0) = r4-> 24; ALU = 12
    {InstrMem[15], InstrMem[14] , InstrMem[13], InstrMem[12]} = 
    {imm_s[11:5], 5'h4, 5'h0, F3_LW_SW, imm_s[4:0], OP_S}; 

    //5. I-Type: Load
    // r5 = mem(12 + r0) -> 24; ALU = 12
    {InstrMem[19], InstrMem[18] , InstrMem[17], InstrMem[16]} = 
    {imm_i2, 5'h0, F3_LW_SW, 5'h5, OP_I};  

    //6. B-Type
    // beq r5, r6, 12 (B1)
    // NOT TAKEN
    {InstrMem[23], InstrMem[22], InstrMem[21], InstrMem[20]} = 
    {imm_b[12], imm_b[10:5], 5'h5, 5'h6, F3_ADD_SUB_BEQ, imm_b[4:1], imm_b[11], OP_B};
    // B1: SHOULD EXECUTE
    // I-Type: Add
    // r7 = r0 + 8 = 8
    {InstrMem[27], InstrMem[26], InstrMem[25], InstrMem[24]} = 
    {imm_i3, {5'h0}, F3_ADD_SUB_BEQ, 5'h7, OP_I};
    // B1: SHOULD EXECUTE
    // I-Type: OR
    // r7 = r0 + 9 = 9 
    {InstrMem[31], InstrMem[30], InstrMem[29], InstrMem[28]} = 
    {imm_i4, {5'h0}, F3_OR, 5'h7, OP_I}; 

    // 8. B-Type
    // beq r4, r4, 12 (B2)
    // TAKEN
    // now, beq r4, r0, 12 (B3)
    // NOT TAKEN
    {InstrMem[35], InstrMem[34], InstrMem[33], InstrMem[32]} = 
    {imm_b[12], imm_b[10:5], 5'h4, 5'h0, F3_ADD_SUB_BEQ, imm_b[4:1], imm_b[11], OP_B}; 

    // B2: SHOULDN'T EXECUTE
    // J, B3: SHOULD EXECUTE
    // NOP: add r0, r1, r1
    {InstrMem[39], InstrMem[38], InstrMem[37], InstrMem[36]} = 
    {F7_ADD, 5'h1, 5'h1, F3_ADD_SUB_BEQ, 5'h0, OP_R}; 

    // J-Type
    // j -4 (jal r0, -4)
    {InstrMem[43], InstrMem[42], InstrMem[41], InstrMem[40]} = 
    {imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12], 5'h0, OP_J}; 

    // B2: SHOULD EXECUTE
    // J: SHOULDN'T EXECUTE
    // R-Type: Add
    // add r8, r8, r8
    {InstrMem[47], InstrMem[46] , InstrMem[45], InstrMem[44]} = 
    {F7_ADD, 5'h8, 5'h8, F3_ADD_SUB_BEQ, 5'h8, OP_R};  

  end 

endmodule
