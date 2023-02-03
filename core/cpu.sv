`ifndef _CPU
`define _CPU
`include "common.sv"
`include "core.sv"
`include "mmu.sv"

//cpu: core with mmu integrated
module cpu(
  input   wire                              clk,
  input   wire                              rst,
  input   wire                              intr,
  input   wire  `WIDE(`XLEN)                bus_dat_i,
  output  wire  `WIDE(`XLEN)                bus_dat_o,
  output  wire  `WIDE(`XLEN - `SLAVE_WIDTH) bus_addr,
  output  wire  `WIDE(`SLAVE_WIDTH)         bus_num,
  output  wire                              bus_req,
  output  wire                              bus_wen,
  output  wire  `WIDE(3)                    bus_mode,
  input   wire                              bus_ready
);

  //core output/mmu input signals
  wire mem_wen;
  wire `WIDE(3) mem_mode;
  wire `WIDE(`XLEN) mem_addr, bus_dat_w;

  //mmu output/core input signals
  wire mem_ready;
  wire `WIDE(`XLEN) bus_dat_r;

  core core_0(
    .clk(clk),
    .rst(rst),
    .intr(intr),
    .mem_wen(mem_wen),
    .mem_mode(mem_mode),
    .mem_addr(mem_addr),
    .mem_dat_i(bus_dat_r),
    .mem_dat_o(bus_dat_w),
    .mem_ready(mem_ready)
  );

  mmu mmu_0(
    .mem_wen(mem_wen),
    .mem_mode(mem_mode),
    .mem_addr(mem_addr),
    .mem_dat_i(bus_dat_w),
    .mem_dat_o(bus_dat_r),
    .bus_ready_o(mem_ready),
    .bus_dat_i(bus_dat_i),
    .bus_dat_o(bus_dat_o),
    .bus_addr(bus_addr),
    .bus_num(bus_num),
    .bus_req(bus_req),
    .bus_wen(bus_wen),
    .bus_mode(bus_mode),
    .bus_ready_i(bus_ready)
  );

endmodule

`endif