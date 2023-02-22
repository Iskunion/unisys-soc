//a uib-standard slave device
`ifndef _GMEM
`define _GMEM

`ifndef _GMEMDIR   
`define _GDATA0 `"C:/Users/Bardi/Work/Hardware/Shadow/memories/image/tests/gdata-0.txt`"
`define _GDATA1 `"C:/Users/Bardi/Work/Hardware/Shadow/memories/image/tests/gdata-1.txt`"
`define _GDATA2 `"C:/Users/Bardi/Work/Hardware/Shadow/memories/image/tests/gdata-2.txt`"
`define _GDATA3 `"C:/Users/Bardi/Work/Hardware/Shadow/memories/image/tests/gdata-3.txt`"
`endif

`include "uibi.sv"
`include "perfs.sv"
`include "mainmem.sv"

`define GMEM_WIDTH 17
`define GMEM_SIZE 76800
`define GDAT_WIDTH 8
`AMOUNT(GSLICE_NR, 2)

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

  wire `WIDE(`GSLICE_NR_SIZE) `WIDE(`XLEN/`GSLICE_NR_SIZE) mem_cell_out;

  `ALWAYS_CR if (~rst) begin
    vgactl_dat <= '0;
  end else vgactl_dat <= mem_cell_out[`BITRANGE(vgactl_addr, `GSLICE_NR_WIDTH, 0)];

  genvar i;
  generate
    for (i = 0; i < `GSLICE_NR_SIZE; i = i + 1) begin: gram
      gram #(
        .width(`GDAT_WIDTH),
        .size(`GMEM_SIZE/`GSLICE_NR_SIZE),
        .addr_width(`GMEM_WIDTH-`GSLICE_NR_WIDTH),
        .gram_no(i)
      ) internal_gram(
        .bus_addr(`BITRANGE(bus_addr, `GMEM_WIDTH , `GSLICE_NR_WIDTH)),
        .vgactl_addr(`BITRANGE(vgactl_addr, `GMEM_WIDTH, `GSLICE_NR_WIDTH)),
        .datain(`BITRANGE(bus_dat_i, (i+1)*`GDAT_WIDTH, i*`GDAT_WIDTH)),
        .dataout(mem_cell_out[i]),
        .memclk(clk),
        .en(1'b1),
        .wen(bus_wen & rl_mode[i])
      );
    end
  endgenerate

endmodule


module gram #(
    parameter width       =   `GDAT_WIDTH,
    parameter size        =   `GMEM_SIZE / `GSLICE_NR_SIZE,
    parameter addr_width  =   `GMEM_WIDTH - `GSLICE_NR_WIDTH,
    parameter gram_no      =   0
)(
    input   wire    `WIDE(addr_width)   bus_addr,
    input   wire    `WIDE(addr_width)   vgactl_addr,
    input   wire    `WIDE(width)        datain,
    input   wire                        memclk,
    input   wire                        en,
    input   wire                        wen,
    output  reg     `WIDE(width)        dataout
);

    reg `WIDE(width) memory `WIDE(size);

    initial begin
        dataout <= 0;
    end
    
    always @(posedge memclk) begin
      if (en) begin
        if (wen) begin
          memory[bus_addr] <= datain;
          dataout <= '0;
        end
        else begin
          dataout <= memory[vgactl_addr];
        end
      end
    end

    initial begin
        case (gram_no)
          0: $readmemh(`_GDATA0, memory, 0, size-1);
          1: $readmemh(`_GDATA1, memory, 0, size-1);
          2: $readmemh(`_GDATA2, memory, 0, size-1);
          3: $readmemh(`_GDATA3, memory, 0, size-1);
          default: ;
        endcase
    end
endmodule


`endif