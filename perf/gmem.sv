//a uib-standard slave device
`ifndef _GMEM
`define _GMEM

`include "uibi.sv"
`include "perfs.sv"

`define GMEM_WIDTH 17
`define GMEM_SIZE 76800
`define GDAT_WIDTH 8

module gmem (
  input wire clk,
  input wire rst,
  //busside
  `UIBI_SLAVE,
  input wire `WIDE(`GMEM_WIDTH) vgactl_addr,
  output reg `WIDE(`COLOR_WIDTH) vgactl_dat
);

  `CONVERT_BUS_MODE

  //block bus read
  assign bus_dat_o = '0;

  reg `WIDE(`GDAT_WIDTH) memory `WIDE(`GMEM_SIZE);

  `ALWAYS_CR if (~rst) begin
    vgactl_dat <= '0;
  end else vgactl_dat <= memory[vgactl_addr];

  `ALWAYS_CR if (~rst) begin end
  else if (bus_req && bus_wen) begin
    begin
      if (rl_mode[0])
        memory[{`BITRANGE(bus_addr, `GMEM_WIDTH, 2), 2'b00}] <= `BITRANGE(bus_dat_i, 1*(`XLEN/4), 0*(`XLEN/4));
      if (rl_mode[1])
        memory[{`BITRANGE(bus_addr, `GMEM_WIDTH, 2), 2'b01}] <= `BITRANGE(bus_dat_i, 2*(`XLEN/4), 1*(`XLEN/4));
      if (rl_mode[2])
        memory[{`BITRANGE(bus_addr, `GMEM_WIDTH, 2), 2'b10}] <= `BITRANGE(bus_dat_i, 3*(`XLEN/4), 2*(`XLEN/4));
      if (rl_mode[3])
        memory[{`BITRANGE(bus_addr, `GMEM_WIDTH, 2), 2'b11}] <= `BITRANGE(bus_dat_i, 4*(`XLEN/4), 3*(`XLEN/4));
    end
  end

endmodule

`endif