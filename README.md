# 5-stage RV32I Pipelined Processor
## My Goal
- To implement a basic set of Arithmetic, Load/Store, and Branch operations:
	- ALU Operations: `ADD`, `SUB`, `AND`, `OR`, `XOR`
	- Immediate Operations: `ADDI`, `ANDI`, `ORI`, `XORI`
	- Load/Store: `LW`, `SW`
	- Branches: `BEQ`, `J` (Unconditional Branch)
- To implement Data-forwarding from both the `EX-MEM` and `MEM-WB` stages to reduce stalls and improve throughput
- To implement a Hazard-unit to prevent Load-use (`RAW`) hazards following `LW` instructions not solved by Data-forwarding
- To provide a [sample testbench](CodeFiles/testbench.sv) to verify the core on a comprehensive instruction set, with step-by-step output for easy understanding. More on this [later](#testbenchsv).

## The ISA
I shall be using the `R-`, `I-`, `S-`, `B-`, and `J-Type` formats to implement the mentioned instructions.


###  R-Type
![R-Type Instruction Encoding](Images/R_Type.jpg)
- covers `ADD`, `SUB`, `AND`, `OR`, `XOR`

1. `opcode` → `7’b0110011`
2. `funct3` → `3'b000` for `ADD`/`SUB`, `111` for `AND`, `110` for `OR`, `100`for `XOR`.
3. `funct7` → distinguishes between `ADD`/`SUB` (`7'b0000000` for `ADD`, `7'b0100000` for `SUB`).

- Sample Instruction: `add r2, r0, r1`

### I-Type
![I-Type Instruction Encoding](Images/I_Type.jpg)
- covers `ADDI`, `ANDI`, `ORI`, `XORI`, `LW` (`SUBI` is just `ADDI` with a -ve `imm_i`).
- LW format: `mem[R[rs1]+offset] → R[rs2]`

1. `opcode` → `7’b0010011`
2. `funct3` → specifies which immediate operation it is. `ADDI`: `3'b000`, `ANDI`: `3'b111`, `LW`: `3'b010`, `XORI`: `3'b100`, `ORI`: `3'b110`

- Sample Instructions: `ori r3, r2, imm_i`, `lw r5, r4, imm_i`. `imm_i` is of size `[11:0]`.

### S-Type
![S-Type Instruction Encoding](Images/S_Type.jpg)
→ covers `SW`. Performs `mem[R[rs1] + offset] ← R[rs2]`. The reason that offset isn’t word (`32b`) assigned mandatorily is since the same `opcode` accommodates `SH` and `SB`, too (memory is byte-addressable). However, I shall only use `SW`.

1. `opcode` → S-Type → `7’b0100011`
2. `funct3`→ `3'b010` for `SW`. Other combinations for `SH`, `SB`.

- Sample Instruction: `sw r3, r4, imm_s`. `imm_s` is of size `[11:0]`.

### B-Type
![B-Type Instruction Encoding](Images/B_Type.jpg)
- covers `BEQ`

 1. `opcode` → `7’b1100011`
 2. `funct3` → `3'b000`. Other combinations for the other branch-variants.

- This utilises most of the architecture from the `S-Type` Instruction. Let the input to the ALU be `in`. In that case, since `opcode[S]` and `opcode[B]` are mutually exclusive,
	1. `in[31:12]` = `instr[31]` → in both cases, `[31]` is the MSB and Sign-bit
	2. `in[11]` = `is_S_type ? instr[31] : instr[7]` → **additional MUX required**
	3. `in[10:5]` = `instr[20:25]`, `in[4:1]` = `instr[11:8]` →  in both cases
	4. `in[0]` = `is_S_type ? instr[7] : 1'b0` →  **additional MUX required**

This gives us `13b`, i.e., ±4kB of locations to access. This happens to be the page-size in a standard OS, so the designers decided not to include another Branch (`B2`) for the *RV32I* ISA, separately, in an attempt to use the same core for both the compressed (`16b`) and `32b` ISAs. 
Can it be done, however? Absolutely- [B2 for the RV32I ISA](https://github.com/avyakthd/riscv-core-sv/tree/single-cycle-working/B2_instr.md)

- Sample Instruction: `beq r5, r5, imm_b`. `imm_b` is of size `[12:1]`, but undergoes an implicit `<<1` for `16b`-alignemnt

### J-Type
![J-Type Instruction Encoding](Images/U_J_Type.png)

- covers `J`. This is actually the instruction format for `JAL` (Jump and Link), but if we set the value of the link-register (`rd`) to `0`, i.e., if the link-register is `r0`, then it would be interpreted as an unconditional-branch by the compiler.

 1. `opcode` → `7’b1101111` 
 2. No `funct3`

- The placement of bits, again, was to reuse every possible pre-existing connection (from `U-Type`, this time):
	1. `imm[20]` = `instr[31]` →  again, MSB → sign-bit
	2. `imm[10:1]` = `instr[30:21]`→ shares that part in common with I-Type’s `imm[11:0]`
	3. `imm[19:12]` = `instr[19:12]` →  shares this in common with U-type’s `imm[31:12]`
	4. `rd (instr[11:7]), opcode[6:0]`→ same for all instructions
	5. `imm[11] = instr[20]` → remaining bit- inserted in the empty slot

This gives us a range of ±1MB of locations to access. 

- Sample instruction: `j imm_j`. `imm_j` is of size `[20:1]`, but undergoes an implicit `<<1` for `16b`-alignment

## Instruction Flow and Expected Behaviour
This section described the rationale behind the set of chosen instructions to verify the pipeline-implementation, which cover arthimetic- and logical-operations, `Load`/`Store` hazards, branching (with +ve and -ve offsets), forwarding, stalls, and special cases like writing to `r0`

The [testbench](CodeFiles/testbench.sv) outputs are designed to highlight important pipeline signals per instruction cycle, allowing step-by-step tracing of register values, forwarding decisions, stalls, and flushes.

Note that all `RegMem[i]` and `DataMem[i]` have been initialised to `i` @ `t = 0`.

- **`addi r1, r0, 11;`** → r1 = r0 + 11 → 11. No hazards.
- **`add r3, r1, r2;`** → Checks for `EX_MEM_R` data forwarding; r3 = 13.
- **`add r4, r3, r1;`** → Checks both `EX_MEM_R` and `MEM_WB_R` data forwarding to different inputs; r4 = 24.
- **`sw r4, 12(r0);`** → `mem[12 + r0]` = `mem[12]` = r4 = 24.
- **`lw r5, 12(r0);`** → r5 = `mem[12 + r0]` = `mem[12]` = 24.
- **`beq r5, r6, 12;`** → Source register rs2 (`r5`) matches `LW`'s destination rd (`r5`) → Stall, then proceed. r5 = 24, r6 = 6 → `branch_taken` = 0 (not taken).
- **`addi r7, r0, 8;`** → Executes since branch is not taken; r7 = 8.
- **`ori r7, r0, 9;`** → Executes since branch is not taken; r7 = 9.
- **`beq r4, r4, 12; (B1)`** or **`beq r4, r0, 12; (B2)`** → Test taken/not taken branches. B1 is taken; B2 is not. Modify `InstrMem` code to switch between cases.
- **`add r0, r1, r1;`** → NOP. Executes if B2 (not taken) or after `J`; skipped if B1 (taken). Tests r0 write (should remain unchanged, as r0 is hardwired to 0).
- **`j -4;`** or **`jal r0, -4;`** → Jumps back to the previous NOP instruction.
- **`add r8, r8, r8;`** → Executes if B1 (taken); skipped otherwise.

This sequence comprehensively tests forwarding paths, stalls, flushes, branch resolution, and register behaviors.

## The Modules
All modules can be run and tested on [EDAPlayground](https://edaplayground.com/x/YtNt), or using any software of your choice (code available [here](CodeFiles)).
### `design.sv`
This is merely an aggregate of all the modules I've used, and is the only module that EDAPlayground compiled by default, along with `testbench.sv`.
### `riscv_pkg.sv`
This defines various `enums` and `types`, along with the pipeline-registers, for convenience and increased readability throughout the code base.
### `PC.sv`
This instantiates the `PC` (Program Counter), and updates it with the input `PC_in` it gets from `Top.sv` at every `posedge clk`, if `Stall` is not asserted.

> Clock-triggered
### `InstrFile.sv`
This instantiates the byte-addressable Instruction-Memory, which outputs a `32b` instruction indexed by `PC_Out`. 

> Purely combinational
### `Top.sv`
This module:
- declares all the pipeline-registers (defined in `riscv_pkg.sv`), and coordinates their updates (`posedge clk` triggered).
- instantiates all design files.
- decodes the Instruction received from `IF_ID_R`, generating `rs1`, `rs2`, `rd`, `opcode`, `funct3`, `funct7`.
- selects between `Rs2` and `imm32` for the second `ALU` input based on the `is_R` signal.
- implements the logic for pipeline-flushing (`Flush`), and `PC` update/branching.
  
> Clock-triggered
### `Control_Unit.sv`
This module generates the following control signals:

`RegWrite` : `Register-File` write-enable signal; set to `0` if `Stall` is asserted.
`is_R` : selects between `imm32` or `R[rs2]` for the second `ALU` input.
`PC_sel`: PC-MUX selector (`PC_4`/`PC_BEQ`/`PC_J`), determined based on the `opcode`.
`DataMem_RW`: Data-Memory Operation (`Read`/`Write`); set to `Read` is `Stall` is asserted.
`MReg` : determines whether the input to the write-port of `Register_File` would be from `DataMem` or `ALU`.

> Purely combinational
### `ALU_Ctl.sv`
This module generates the control signal `ALU_Op` based on `opcode`, `funct3`, and `funct7` (only for `ADD`/`SUB`). This operation can be `ADD`, `SUB`, `AND`, `OR`, `XOR`. 

> Purely combinational
### `imd_gen.sv`
This helper-module extracts the *immediate* values from the `I-`, `S-`, `B-`, and `J-Type` instructions, sign-extends them to `32b`, and gives a single output based on the opcode (e.g., only `imm_b`, if `opcode == OP_B`). 

> Purely combinational
### `Register_File.sv`
This module initialises 32 x `32b` registers, as per the convention in RV32I. The read operation is purely combinational, whereas the write operation is triggered at posedge clk, if the RegWrite signal is enabled. The debug-signal `debug_addr_RF`, and its output `debug_data_RF` would help us evaluate our design.

> Read: Purely Combinational  
> Write: Clock-triggered
### `Hazard_Unit.sv`
A Load-use (`RAW`) hazard occurs when a `Load` instruction is followed by any instruction that depends on its destination register (`rd`). This cannot be resolved by simple Data-Forwarding, and would require a `Stall`, during which the `Load` proceeds through the pipeline, while the dependent instruction is halted. 

This module implements that hazard-detection by asserting `Stall` when the `rd` from `ID_EX_R` matches with the source registers from `IF_ID_R`

> Purely Combinational
### `Forwarding_Unit.sv`
`RAW` hazards can occur when a subsequent instruction requires the value of the destination-register (`R[rd]`), before that value has been written back (in the `WB` stage). To resolve this without `Stall`s, we forward the `ALU_Result` directly from the `EX_MEM_R` and `MEM_WB_R` pipeline-registers to the `ALU`'s inputs.

This module checks the dependencies between the source-registers (`rs1`, `rs2`) and destination-registers (`EX_MEM_R.rd` and `MEM_WB_R.rd`) and asserts the forwarding signals to the `ALU` (`ForwardA`, `ForwardB`). 

> Purely Combinational
### `ALU.sv`
This module performs arithemtic- and logical-operations based on `ALU_Op`. It takes inputs from:
- `ID_EX_R`: `Rs1`, `Rs2_imm32` (multiplexed based on whether `Rs2` or `imm32` is needed), `ocpode`, and `is_R`
- `EX_MEM_R`, `MEM_WB_R`: `ALU_Result` for Data-Forwarding
- `Forwarding_Unit`: forwarding-signals (`ForwardA`/`ForwardB`)

The inputs are selected based on the forwarding-signals, which resolve data-hazards by choosing the most recent valid operand from the pipeline-registers. The module then computes `ALU_Result` and `is_equal`, which is used by the PC-control unit to determine whether or not the branch is taken (if `BEQ`).

**Special Handling**: for `S-Type` instructions, although the forwarding-signal might indicate forwarding for the second `ALU` input (`ForwardB`), we *must* choose the *immediate* value, and not the register `R[rs2]`. To avoid incorrect forwarding, this module includes an override forwarding and select the *immediate* value when needed.

> Purely combinational
### `DataFile.sv`
This module takes the following inputs from the `EX_MEM_R` pipeline-register:
- `ALU_Result`: serves as the memory-address in case of `SW`/`LW`, and is forwarded to `MEM_WB_R` if not accessing the memory.
- `DataMem_RW`: Read/Write control signal (`Write` if Store, `Read` if Load)
- `Rs2`: data from the `R[rs2]` register; for `S-Type` instructions
- `MReg`: determines whether the value written back to `Register_File` (`Rd`) is from `DataMem` or the `ALU_Result`
- `rd`: destination-register index

Similar to `Register_File`, the *read* operation is purely combinational, whereas the *write* operation is triggered at `posedge clk`, if `DataMem_RW == Write`.

The debug-signal `debug_addr_DF`, and its output `debug_data_DF` would help us evaluate our design.

> Read: Purely Combinational  
> Write: Clock-triggered
### `testbench.sv`
This module instantiates `Top.sv` and generates the global clock-signal (`clk`).
The simulation outputs can be viewed graphically:
- on *EDAPlayground* by enabling `Tools & Simulators -> Open EPWave after Run`, or
- by using any waveform-viewer (e.g., *GTKWave*) and opening the generated waveform-file

The testbench is designed to display all the relevant values of each instruction in a step-by-step, readable format. 
#### Usage Notes
- Vary the initial delay (currently `#0`) in steps of 2 to view the outputs of the next instruction. For example, to view the 3rd instruction, set the delay to `#4`.
- This `$display` line prints the register-indices for the current instruction:
```Verilog
$display("[%0d] rs1 = %0h, rs2 = %0d, rd = %0d", $time,  uTop.ID_EX_R.rs1,  uTop.ID_EX_R.rs2,  uTop.ID_EX_R.rd);
```
For `I-Type` and `S-Type` instructions, replace `rs2` with `imm32` (*immediate*), and `uTop.ID_EX_R.rs2` with `uTop.ID_EX_R.imm32`, or **replace** the line above with the following code-snippet:
```Verilog
$display("[%0d] rs1 = %0h, imm32 = %0d, rd = %0d", $time,  uTop.ID_EX_R.rs1,  uTop.ID_EX_R.imm32,  uTop.ID_EX_R.rd);
```
- To view `Register_File` contents:  
  Set `rf_debug_addr_w` to the `RegMem` index you would like to access. The corresponding output would be displayed by `rf_debug_data_w`.
- Similarly, to view `DataFile` contents:  
  Set `df_debug_addr_w` to the `DataMem` index you would like to access. The corresponding output would be displayed by `debug_data_w`. Note that in the code these are currently `rf_debug_addr_w` and `rf_debug_data_w`- change them if needed.

In case you are unable to follow this, the `testbench.sv` file includes these instructions inline comments beside the sections that you might need to tweak.
