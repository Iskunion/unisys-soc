//a uib-standard slave device
`ifndef _MAINMEM
`define _MAINMEM


`ifndef _MEMDIR   
`define _DATA0 `"C:/Users/Bardi/Work/Hardware/Shadow/memories/image/tests/data-0.txt`"
`define _DATA1 `"C:/Users/Bardi/Work/Hardware/Shadow/memories/image/tests/data-1.txt`"
`define _DATA2 `"C:/Users/Bardi/Work/Hardware/Shadow/memories/image/tests/data-2.txt`"
`define _DATA3 `"C:/Users/Bardi/Work/Hardware/Shadow/memories/image/tests/data-3.txt`"
`endif

`include "uibi.sv"

`AMOUNT(SLICE_NR, 2)
`AMOUNT(SLICE, 17)
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
          0: $readmemh(`_DATA0, memory, 0, size-1);
          1: $readmemh(`_DATA1, memory, 0, size-1);
          2: $readmemh(`_DATA2, memory, 0, size-1);
          3: $readmemh(`_DATA3, memory, 0, size-1);
          default: ;
        endcase
    end
endmodule

`endif