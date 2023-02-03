`ifndef _MMU
`define _MMU
`include "common.sv"

`define MMIO(name, value)\
  `define name``_MARK value\
  `define name``_BASE {name``_MARK, 28'h0}

`MMIO(IMEM,   4'h0)
`MMIO(DMEM,   4'h8)
`MMIO(FB,     4'hc)
`MMIO(DEVICE, 4'ha)

// `define DEVREG(name, value)\
//   `define name``_REG (`DEVICE_BASE + value)

// `DEVREG(KBD,      32'h00000060)
// `DEVREG(RTC,      32'h00000048)
// `DEVREG(VGA_INFO, 32'h00000100)
// `DEVREG(UART_RX,  32'h0000000c)
// `DEVREG(UART_TX,  32'h00000010)

//mmio mmu without virtual memory
module mmu (
  //cpu side
  input   wire                              mem_wen,
  input   wire  `WIDE(3)                    mem_mode,
  input   wire  `WIDE(`XLEN)                mem_addr,
  input   wire  `WIDE(`XLEN)                mem_dat_i,
  output  wire  `WIDE(`XLEN)                mem_dat_o,
  output  wire                              bus_ready_o,
  //bus side
  input   wire  `WIDE(`XLEN)                bus_dat_i,
  output  wire  `WIDE(`XLEN)                bus_dat_o,
  output  wire  `WIDE(`XLEN - `SLAVE_WIDTH) bus_addr,
  output  wire  `WIDE(`SLAVE_WIDTH)         bus_num,
  output  wire                              bus_req,
  output  wire                              bus_wen,
  output  wire  `WIDE(3)                    bus_mode,
  input   wire                              bus_ready_i
);
  assign bus_wen      =   mem_wen;
  assign bus_req      =   1'b1;
  assign bus_mode     =   mem_mode;
  assign bus_ready_o  =   bus_ready_i;
  assign bus_dat_o    =   mem_dat_i;
  assign mem_dat_o    =   bus_dat_i;
  assign bus_num      =   `BITRANGE(mem_addr, `XLEN, `XLEN - `SLAVE_WIDTH);
  assign bus_addr     =   `BITRANGE(mem_addr, `XLEN - `SLAVE_WIDTH, 0);
endmodule
`endif