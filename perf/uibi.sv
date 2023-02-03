`ifndef _UIBI
`define _UIBI

`include "common.sv"

//bus_mode:
//111: all bytes
//011: half bytes
//001: one fourth bytes

`define UIBI_MASTER\
  input   wire  `WIDE(`XLEN)                bus_dat_i,\
  output  wire  `WIDE(`XLEN)                bus_dat_o,\
  output  wire  `WIDE(`XLEN-`SLAVE_WIDTH)   bus_addr,\
  output  wire  `WIDE(`SLAVE_WIDTH)         bus_num,\
  output  wire                              bus_req,\
  output  wire                              bus_wen,\
  output  wire  `WIDE(3)                    bus_mode,\
  input   wire                              bus_ready\

`define UIBI_SLAVE\
  input   wire  `WIDE(`XLEN)                bus_dat_i,\
  output  wire  `WIDE(`XLEN)                bus_dat_o,\
  input   wire  `WIDE(`XLEN - `SLAVE_WIDTH) bus_addr,\
  input   wire                              bus_req,\
  input   wire                              bus_wen,\
  input   wire  `WIDE(3)                    bus_mode,\
  output  wire                              bus_ready\

`define STDMASTER(NAME)\
  .bus_dat_i(master_dat_o[`NAME``_NO]),\
  .bus_dat_o(master_dat_i[`NAME``_NO]),\
  .bus_addr(master_addr[`NAME``_NO]),\
  .bus_num(master_num[`NAME``_NO]),\
  .bus_req(master_req[`NAME``_NO]),\
  .bus_wen(master_wen[`NAME``_NO]),\
  .bus_mode(master_mode[`NAME``_NO]),\
  .bus_ready(master_ready[`NAME``_NO])

`define STDSLAVE(NAME)\
  .bus_dat_i(slave_dat_o[`NAME``_NO]),\
  .bus_dat_o(slave_dat_i[`NAME``_NO]),\
  .bus_addr(slave_addr[`NAME``_NO]),\
  .bus_req(slave_req[`NAME``_NO]),\
  .bus_wen(slave_wen[`NAME``_NO]),\
  .bus_mode(slave_mode[`NAME``_NO]),\
  .bus_ready(slave_ready[`NAME``_NO])

`endif