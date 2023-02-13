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

  `CONVERT_BUS_MODE

  genvar i;
  generate
    for (i = 0; i < `SLICE_NR_SIZE; i = i + 1) begin: ram
      ram #(
        .width(`DAT_WIDTH),
        .size(`SLICE_SIZE),
        .addr_width(`SLICE_WIDTH),
        .ram_no(i)
      ) internal_ram(
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
    parameter addr_width  =   `SLICE_WIDTH,
    parameter ram_no      =   0
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
        case (ram_no)
          0: $readmemh("C:/Users/Bardi/Work/Hardware/Shadow/memories/image/tests/data0.txt", memory, 0, size-1);
          1: $readmemh("C:/Users/Bardi/Work/Hardware/Shadow/memories/image/tests/data1.txt", memory, 0, size-1);
          2: $readmemh("C:/Users/Bardi/Work/Hardware/Shadow/memories/image/tests/data2.txt", memory, 0, size-1);
          3: $readmemh("C:/Users/Bardi/Work/Hardware/Shadow/memories/image/tests/data3.txt", memory, 0, size-1);
          default: ;
        endcase
    end
endmodule

`endif