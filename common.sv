`ifndef _COMMON
`define _COMMON

`define XLEN 32
`define AMOUNT(name, value)\
  `define name``_WIDTH value\
  `define name``_SIZE (2**value)

`AMOUNT(SLAVE, 3)
`AMOUNT(MASTER, 1)

`AMOUNT(RIBADDR, (`XLEN-`SLAVE_WIDTH))

`define BITRANGE(name, hi, lo) name[((hi)-1):(lo)]
`define SEXT(name, hi, lo, supplement)\
  {{supplement{name[(hi)-1]}}, `BITRANGE(name, hi, lo)}
`define WIDE(xlen) [((xlen)-1):0]

`define ALWAYS_CR always_ff @(posedge clk, negedge rst)
`define ALWAYS_NCR always_ff @(negedge clk, negedge rst)

`endif