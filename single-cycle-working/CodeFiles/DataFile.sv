`timescale 1ns/1ps
import riscv_pkg::*;

module DataFile (
  input clk,
  // control signal
  input DataMem_sel_e DataMem_RW, 
  input MReg_sel_e MReg,
  // from ALU
  input `reg_size ALU_Result,
  // from RegFile
  input `reg_size Rs2,
 
  // to RegFile, from DataFile->MUX_MReg
  output `reg_size Rd
);
  
  logic `reg_size DataMem_Out;
  
  // initialise the DataMemory
  logic [7:0] DataMem [39:0];  // arbitrary size
  initial begin
    foreach(DataMem[i]) begin
      DataMem[i] = i;
    end
    DataMem_Out = 32'b0; 
  end
     
  always_comb begin
    if (DataMem_RW == Read) begin
      DataMem_Out = {DataMem [ALU_Result +3], 
                     DataMem [ALU_Result +2], 
                     DataMem [ALU_Result +1], 
                     DataMem [ALU_Result ] }; 
    end
  end
  // MUX- MReg
  assign Rd = (MReg == from_DataMem) ? DataMem_Out : ALU_Result;
            
  always_ff @(posedge clk) begin
    if (DataMem_RW == Write) begin
      {DataMem[ALU_Result +3], 
       DataMem[ALU_Result +2], 
       DataMem[ALU_Result +1],
       DataMem[ALU_Result ]}  <= Rs2; // Write_Data
    end
  end
            
endmodule
