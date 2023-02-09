`ifndef _PC_REG
`define _PC_REG
`include "common.sv"

module pc_reg(
  input wire clk,
  input wire rst,
  input wire pcg_isjalr,
  input wire pcg_branch,
  input wire `WIDE(`XLEN) pcg_offset,
  input wire `WIDE(`XLEN) pcg_jalr_reg,
  output wire `WIDE(`XLEN) pc_out,
  output wire `WIDE(`XLEN) pc_now
);

  reg `WIDE(`XLEN) pc;
  wire `WIDE(`XLEN) pc_base, pc_addition;

  assign pc_base = pcg_isjalr ? pcg_jalr_reg : pc;
  assign pc_addition = pcg_branch ? pcg_offset : 32'h4;

  assign pc_out = pc_base + pc_addition;

endmodule

`endif