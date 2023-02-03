`ifndef _CORE
`define _CORE
`include "common.sv"

module core(
  input   wire                  clk,
  input   wire                  rst,
  input   wire                  intr,
  output  wire                  mem_wen,
  output  wire  `WIDE(3)        mem_mode,
  output  wire  `WIDE(`XLEN)    mem_addr,  
  input   wire  `WIDE(`XLEN)    mem_dat_i,
  output  wire  `WIDE(`XLEN)    mem_dat_o,
  input   wire                  mem_ready
);


endmodule

`endif