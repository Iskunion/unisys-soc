//a uib-standard slave device
`ifndef _MAINMEM
`define _MAINMEM

`include "uibi.sv"

`AMOUNT(SLICE_NR, 2)
`AMOUNT(SLICE, 16)
`AMOUNT(MEM, (`SLICE_WIDTH+`SLICE_NR_WIDTH))
`define DAT_WIDTH (`XLEN/`SLICE_NR_SIZE)

module mainmem (
  input wire clk,
  input wire rst,
  //busside
  `UIBI_SLAVE
);

  wire `WIDE(`XLEN/8) tr_mode;
  assign `BITRANGE(tr_mode, (`XLEN/8),  (`XLEN/16)) = {(`XLEN/16){bus_mode[2]}};
  assign `BITRANGE(tr_mode, (`XLEN/16), (`XLEN/32)) = {(`XLEN/32){bus_mode[1]}};
  assign `BITRANGE(tr_mode, (`XLEN/32), 0)          = {(`XLEN/32){bus_mode[0]}};

  wire `WIDE(`XLEN/8) rl_mode;
  assign rl_mode = tr_mode << ((bus_addr[1] ? (`XLEN/16) : 0) + (bus_addr[0] ? (`XLEN/32) : 0));

  genvar i;
  generate
    for (i = 0; i < `SLICE_NR_SIZE; i = i + 1) begin: ram
      ram internal_ram(
        .addr(`BITRANGE(bus_addr, `MEM_WIDTH , `SLICE_NR_WIDTH)),
        .datain(`BITRANGE(bus_dat_i, (i+1)*`DAT_WIDTH, i*`DAT_WIDTH)),
        .dataout(`BITRANGE(bus_dat_o, (i+1)*`DAT_WIDTH, i*`DAT_WIDTH)),
        .memclk(clk),
        .en(bus_req & rl_mode[i]),
        .wen(bus_wen & rl_mode[i])
      );
    end

  endgenerate

endmodule


module ram #(
    parameter width       =   `DAT_WIDTH,
    parameter size        =   `SLICE_SIZE,
    parameter addr_width  =   `SLICE_WIDTH
)(
    input   wire    `WIDE(addr_width)   addr,
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
    
    always @(posedge memclk)
        if (en)
            dataout <= memory[addr];
        else
            dataout <= 0;

    always @(posedge memclk)
        if (en && wen)
            memory[addr] <= datain;
    initial begin
        $readmemh("C:/Users/Bardi/Work/Hardware/Shadow/memories/VRAM_templates/shizuku1.memory", memory, 0, size - 1);
    end
endmodule

`endif