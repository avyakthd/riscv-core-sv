# RV32I Single-cycle processor
## My Goal
- To implement a basic set of Arithmetic and Load/Store operations:
	- ALU Operations: `ADD`, `SUB`, `AND`, `OR`, `XOR`
	- Immediate Operations: `ADDI`, `ANDI`, `ORI`, `XORI`
	- Load/Store: `LW`, `SW`
	- Branches: `BEQ`, `J` (Unconditional Branch)
- What I can work with: 32 x `32b` registers, Instruction and Data Memories, a main Control-Unit and other sub-components
- A sample testbench that you can use to evaluate these on your own is provided in [single_cycle_tb.sv](single_cycle_tb.sv)

## The ISA
I shall be using the `R-`, `I-`, `S-`, `B-`, and `J-Type` formats to implement the mentioned instructions.


###  R-Type
![R-Type Instruction Encoding](Images/R_Type.jpg)
- covers `ADD`, `SUB`, `AND`, `OR`, `XOR`

1. `opcode` → `7’b0110011`
2. `funct3` → `000` for ADD/SUB, `111` for AND, `110` for OR, `100`for XOR.
3. `funct7` → distinguishes between ADD/SUB (`0000000` for ADD, `0100000` for SUB)

- Sample Instruction: `add r2, r0, r1`;

## I-Type
![I-Type Instruction Encoding](Images/I_Type.jpg)
- covers `ADDI`, `ANDI`, `ORI`, `XORI`, `LW` (`SUBI` is just `ADDI` with a -ve `imm_i`).
- LW format: `mem[R[rs1]+offset] → R[rs2]`

1. `opcode` → `7’b0010011`
2. `funct3` → specifies which immediate operation it is. ADDI: `000`, ANDI: `111`, LW: `010`, XORI: `100`, ORI: `110`

- Sample Instructions: `ori r3, r2, imm_i`, `lw r5, r4, imm_i`
## S-Type
![S-Type Instruction Encoding](Images/S_Type.jpg)
→ covers SW. performs `mem[R[rs1] + offset] ← R[rs2]`. The reason that offset isn’t word (`32b`) assigned mandatorily is since the same `opcode` accommodates SH and SB, too. Memory is byte-addressable.
3. `opcode` → S-Type → `7’b0100011`
4. `funct3`→ `010` for SW. Other combinations for SH, SB.
- I’m assuming the immediate value is split into `imm[11:5]` and `imm[4:0]` to ensure that `rs2`, `rs1`, and `funct3` occupy the same bit-numbers.
→ Test Instruction: 
`wire [11:0] imm = 12’h5;`
`{imm[11:5], 5’h5, 5’h6, F3_LW_SW, imm[4:0], OP_S}`
## B-Type
![B-Type Instruction Encoding](Images/B_Type.jpg)
→ covers BEQ → `funct3 = 000`
→ `opcode[6:0]` → `7’b1100011`
- This utilises most of the architecture from the S-Type Instruction.  Let the input to the ALU be in. In that case, since `opcode[S]` and `opcode[B]` are mutually exclusive,
	1. `in[31:12]` = `instr[31]` → in both cases, `[31]` is the MSB and Sign-bit
	2. `in[11]` = `is_S_type ? instr[31] : instr[7]` → **additional MUX**
	3. `in[10:5]` = `instr[20:25]`, `in[4:1]` = `instr[11:8]` →  in both cases
	4. `in[0]` = `is_S_type ? instr[7] : 0` →  **additional MUX**

This gives us `13b`, i.e., $\pm$ 4kB of locations to access. This happens to be the page-size in a standard OS, so the designers decided not to include another Branch (`B2`) for the *RV32I* ISA, separately, in an attempt to use the same core for both the compressed (`16b`) and `32b` ISAs. 
Can it be done, however? Absolutely- [[B2 for the RV32I ISA]]
→  Test Instruction:
`wire [12:1] imm = 12’h5;`
`{imm[12], imm[10:5], 5’h7, 5’h8, F3_ADD_SUB_BEQ, imm[4:1], imm[11], OP_B}`
## J-Type
![J-Type Instruction Encoding](Images/J_Type.jpg)
→ set the value of `rd` to `6’b0` (`x0`)- interpreted as an unconditional branch
→ `opcode` → `7’b1101111`
- The placement of bits again was to reuse every possible pre-existing connection:
	1. `imm[20]` = `instr[31]` →  again, MSB → sign-bit
	2. `imm[10:1]` = `instr[30:21]`→ shares that part in common with I-Type’s `imm[11:0]`
	3. `imm[19:12]` = `instr[19:12]` →  shares this in common with U-type’s `imm[31:12]`
	4. `rd (instr[11:7]), opcode[6:0]`→ same for all instructions
	5. `imm[11] = instr[20]` → remaining bit- inserted in the empty slot
This gives us a range of $\pm$ 1MB of locations to access. 
→ Test instruction:
`wire [20:1] imm = 20’h5;`
`{imm[20], imm[10:1], imm[11], imm[19:12], 5’h9, OP_J}`

