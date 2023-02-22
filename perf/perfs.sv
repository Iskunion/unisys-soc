`ifndef _PERFS
`define _PERFS

`include "common.sv"

`AMOUNT(COLOR, 8)

//masters
`define CPU_NO 0

//slaves
`define MAINMEM_NO `SLAVE_SIZE/2
`define KBD_NO      0
`define UART_NO     1
`define TIMER_NO    2
`define VGA_NO      3
`define GMEM_NO     5
`define SD_NO       6
`define AUDIO_NO    7


`endif