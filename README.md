# RV32I Single-cycle processor
## My Goal
- To implement a basic set of Arithmetic, Load/Store, and Branch operations:
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
2. `funct3` → `3'b000` for `ADD`/`SUB`, `111` for `AND`, `110` for `OR`, `100`for `XOR`.
3. `funct7` → distinguishes between ADD/SUB (`7'b0000000` for ADD, `7'b0100000` for SUB).

- Sample Instruction: `add r2, r0, r1`

### I-Type
![I-Type Instruction Encoding](Images/I_Type.jpg)
- covers `ADDI`, `ANDI`, `ORI`, `XORI`, `LW` (`SUBI` is just `ADDI` with a -ve `imm_i`).
- LW format: `mem[R[rs1]+offset] → R[rs2]`

1. `opcode` → `7’b0010011`
2. `funct3` → specifies which immediate operation it is. ADDI: `3'b000`, ANDI: `3'b111`, LW: `3'b010`, XORI: `3'b100`, ORI: `3'b110`

- Sample Instructions: `ori r3, r2, imm_i`, `lw r5, r4, imm_i`. `imm_i` is of size `[11:0]`.

### S-Type
![S-Type Instruction Encoding](Images/S_Type.jpg)
→ covers `SW`. performs `mem[R[rs1] + offset] ← R[rs2]`. The reason that offset isn’t word (`32b`) assigned mandatorily is since the same `opcode` accommodates SH and SB, too (memory is byte-addressable). However, I shall only use `SW`.

1. `opcode` → S-Type → `7’b0100011`
2. `funct3`→ `3'b010` for SW. Other combinations for `SH`, `SB`.

- Sample Instruction: `sw r3, r4, imm_s`. `imm_s` is of size `[11:0]`.

### B-Type
![B-Type Instruction Encoding](Images/B_Type.jpg)
- covers `BEQ`

 1. `opcode` → `7’b1100011`
 2. `funct3` → `3'b000`. Other combinations for the other branc-variants.

- This utilises most of the architecture from the S-Type Instruction. Let the input to the ALU be `in`. In that case, since `opcode[S]` and `opcode[B]` are mutually exclusive,
	1. `in[31:12]` = `instr[31]` → in both cases, `[31]` is the MSB and Sign-bit
	2. `in[11]` = `is_S_type ? instr[31] : instr[7]` → **additional MUX required**
	3. `in[10:5]` = `instr[20:25]`, `in[4:1]` = `instr[11:8]` →  in both cases
	4. `in[0]` = `is_S_type ? instr[7] : 1'b0` →  **additional MUX required**

This gives us `13b`, i.e., ±4kB of locations to access. This happens to be the page-size in a standard OS, so the designers decided not to include another Branch (`B2`) for the *RV32I* ISA, separately, in an attempt to use the same core for both the compressed (`16b`) and `32b` ISAs. 
Can it be done, however? Absolutely- [B2 for the RV32I ISA](B2_instr.md)

- Sample Instruction: `beq r5, r5, imm_b`. `imm_b` is of size `[12:1]`, but undergoes an implicit `<<1` for `16b`-alignemnt

### J-Type
![J-Type Instruction Encoding](Images/U_J_Type.png)

- covers `J`. This is actually the instruction format for `JAL` (Jump and Link), but if we set the value of the link-register (`rd`) to `0`, i.e., if the link-register is `r0`, then it would be interpreted as an unconditional-branch by the compiler.

 1. `opcode` → `7’b1101111`
 2. No `funct3`

- The placement of bits, again, was to reuse every possible pre-existing connection:
	1. `imm[20]` = `instr[31]` →  again, MSB → sign-bit
	2. `imm[10:1]` = `instr[30:21]`→ shares that part in common with I-Type’s `imm[11:0]`
	3. `imm[19:12]` = `instr[19:12]` →  shares this in common with U-type’s `imm[31:12]`
	4. `rd (instr[11:7]), opcode[6:0]`→ same for all instructions
	5. `imm[11] = instr[20]` → remaining bit- inserted in the empty slot

This gives us a range of ±1MB of locations to access. 

- Sample instruction: `j imm_j`. `imm_j` is of size `[20:1]`, but undergoes an implicit `<<1` for `16b`-alignment

## The Modules
### `design.sv`
This is merely an aggregate of all the modules I've used, and is the only module that EDAPlayground compiled by default, along with `testbench.sv`
### `riscv_pkg.sv`
This contains various `enums` and `types` I have defined for convenience and increased readability throughout the code base. 
### `PC.sv`
This module initialises and updates the `PC` register. It takes in the `imm32` value provided by the `imd_gen` module, and the `PC_sel` control signal, and chooses between branching (`PC + imm32`), and moving on to the next instruction (`PC + 4`).
Updates values at every `posedge clk`.
### `InstrFile.sv`
This module initialises the Instruction Memory with aforementioned instructions, and outputs a `32b` instruction when indexed by `PC`. 
Purely Combinational.
### `Control_Unit.sv`
This module generates the following control signals:
- `RegWrite`  : self-explanatory, just an enable signal
- `is_R`      : determines whether the second input to the ALU is `imm32` or `R[rs2]`
- `DataMem_RW`: `Read` and `Write` are mutually-exclusive, so `1b` suffices
- `MReg`      : determines whether the input to the *write-port* of `Register_File` would be from `DataMem` or `ALU`

Purely combinational.
### `Register_File.sv`
This module initialises 32 x `32b` registers, as per the convention in RV32I. 
The *read* operation is purely combinational, whereas the *write* operation is triggered at `posedge clk`, if the `RegWrite` signal is enabled. 
### `imd_gen.sv`
This helper-module extracts the *immediate* values from the `I-`, `S-`, `B-`, and `J-Type` instructions, sign-extends them to `32b`, and gives a single output based on the `opcode` (e.g., only `imm_b`, if `opcode = OP_B`).
Purely combinational.
### `ALU_Ctl.sv`
This module generates the control signal `ALU_Op` based on `opcode`, `funct3`, and `funct7` (only for `add`/`sub`). This operation can be `ADD`, `SUB`, `AND`, `OR`, `XOR`.
Purely combinational.
### `ALU.sv`
This module perform the action specified by `ALU_Op` on the inputs `R[rs1]`, and either of `imm32` and `R[rs2]`, based on `is_R`.
Purely Combinational.
### `DataFile.sv`
This module takes in inputs from the `ALU` and from the `Register_File` modules, and performs either *read* or *write* operations (for `LW` and `SW`) based on the value of `DataMem_RW`. Then, it proceeds to generate a `32b` input to `Register_File`'s *write-port* based on the value of `MReg`: can either be the Data-memory's output or the ALU's output that was provided to it.
Similar to `Register_File`, the *read* operation is purely combinational, whereas the *write* operation is triggered at `posedge clk`, if the `DataMem_RW == Write`.

## Basic Timing Checks
While I have not synthesised this model and run timing-analyses on them myself, these are some back-of-the-envelope checks that you can use to ensure proper functioning. Note that any subscript of `p` would mean it's *propagation-delay* (longest path), and `c` would mean *contamination-delay* (shortest path)
### Max-delay/ Setup-time constraint

This would be the path from `InstrMem` to `Register_File` via `ALU` and `DataFile` during in `LW` instruction.

<p>
Let T<sub>pd_total</sub> = T<sub>pd_InstrMem</sub> + T<sub>pd_RegFile</sub> + T<sub>pd_alu</sub> (includes ALU mux) + T<sub>pd_DataMem</sub> + T<sub>pd_mux</sub> (Mreg-MUX)
</p>
<p>
then,<br>
T<sub>clk</sub> &minus; T<sub>skew</sub> &ge; T<sub>pcq_PC</sub> + T<sub>pd_total</sub> + T<sub>su_RegFile</sub>
</p>
<p>
or,<br>
T<sub>pd_total</sub> &le; T<sub>clk</sub> &minus; T<sub>skew</sub> &minus; (T<sub>pcq_PC</sub> + T<sub>su_RegFile</sub>)
</p>

### Min-delay/ Hold-time constraint

<p>
The shortest path for data to race through would be from <code>PC</code> to itself, i.e., along the <code>PC &larr; PC + 4</code> route. Since this contains only one memory element, there won't be any effect of <i>skew</i>:
</p>
<p>
T<sub>ccq_PC</sub> + T<sub>cd_PC_Adder</sub> &ge; T<sub>hold_PC</sub> + T<sub>skew</sub>
</p>
