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




