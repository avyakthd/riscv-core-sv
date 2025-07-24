`timescale 1ns/1ps
`include "riscv_pkg.sv"        // package compiled first
							   // for the modules to use
`include "ALU_Ctl.sv"          
`include "ALU.sv"
`include "PC.sv"
`include "Register_File.sv"
`include "InstrFile.sv"
`include "imd_gen.sv"
`include "Control_Unit.sv"
`include "DataFile.sv"
`include "Forwarding_Unit.sv"
`include "Hazard_Unit.sv"