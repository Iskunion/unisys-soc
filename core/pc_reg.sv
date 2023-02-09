`ifndef _PC_REG
`define _PC_REG
`include "common.sv"

module pc_generator(
  input wire clk,
  input wire rst,
  input wire isjalr,
  input wire branch,
  input wire `WIDE(`XLEN) offset,
  input wire `WIDE(`XLEN) jalr_reg,
  output wire `WIDE(`XLEN) pc_out
);

  reg `WIDE(`XLEN) pc;
  wire `WIDE(`XLEN) pc_base, pc_addition;

  assign pc_base = isjalr ? jalr_reg : pc;
  assign pc_addition = branch ? offset : 32'h4;

endmodule

`endif