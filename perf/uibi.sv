//unisys internal bus interface
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

module mode_convertor(
  input wire `WIDE(3) bus_mode,
  input wire `WIDE(2) bus_addr,
  output wire `WIDE(`XLEN/8) rl_mode
);

  wire `WIDE(`XLEN/8) tr_mode;
  assign `BITRANGE(tr_mode, (`XLEN/8),  (`XLEN/16)) = {(`XLEN/16){bus_mode[2]}};
  assign `BITRANGE(tr_mode, (`XLEN/16), (`XLEN/32)) = {(`XLEN/32){bus_mode[1]}};
  assign `BITRANGE(tr_mode, (`XLEN/32), 0)          = {(`XLEN/32){bus_mode[0]}};

  assign rl_mode = tr_mode << ((bus_addr[1] ? (`XLEN/16) : 0) + (bus_addr[0] ? (`XLEN/32) : 0));

endmodule

`define CONVERT_BUS_MODE\
  wire `WIDE(`XLEN/8) rl_mode;\
  mode_convertor convertor_0(bus_mode, `BITRANGE(bus_addr, 2, 0), rl_mode);

//to use this you should have an integer i in the context
`define RECEIVE_BUS_DATA(name)\
  for (i = 0; i < 4; i = i + 1)\
    if (rl_mode[i])\
      `BITRANGE(name, (i+1)*(`XLEN/4), i*(`XLEN/4)) <= `BITRANGE(bus_dat_i, (i+1)*(`XLEN/4), i*(`XLEN/4))

`endif