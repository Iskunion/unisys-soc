`include "cpu.sv"
`include "uib.sv"
`include "perfs.sv"

module unisys(
  input   wire    clk,
  input   wire    rst
);

  //master busio
  wire `WIDE(`MASTER_SIZE) `WIDE(`XLEN) master_dat_i, master_dat_o;
  wire `WIDE(`MASTER_SIZE) `WIDE(`XLEN - `SLAVE_WIDTH) master_addr;
  wire `WIDE(`MASTER_SIZE) `WIDE(`SLAVE_WIDTH) master_num;
  wire `WIDE(`MASTER_SIZE) `WIDE(3) master_mode;
  wire `WIDE(`MASTER_SIZE) master_wen, master_req, master_ready;

  //slave busio
  wire `WIDE(`SLAVE_SIZE) `WIDE(`XLEN) slave_dat_i, slave_dat_o;
  wire `WIDE(`SLAVE_SIZE) `WIDE(`XLEN - `SLAVE_WIDTH) slave_addr;
  wire `WIDE(`SLAVE_SIZE) `WIDE(3) slave_mode;
  wire `WIDE(`SLAVE_SIZE) slave_wen, slave_req, slave_ready;

  //the bus
  uib uib_0(
    .master_dat_i(master_dat_i),
    .master_dat_o(master_dat_o),
    .master_addr(master_addr),
    .master_num(master_num),
    .master_req(master_req),
    .master_wen(master_wen),
    .master_mode(master_mode),
    .master_ready(master_ready),
    .slave_dat_i(slave_dat_i),
    .slave_dat_o(slave_dat_o),
    .slave_addr(slave_addr),
    .slave_req(slave_req),
    .slave_wen(slave_wen),
    .slave_mode(slave_mode),
    .slave_ready(slave_ready)
  );

  //masters

  //cpu
  cpu cpu_0(
    .clk(clk),
    .rst(rst),
    //never trigger interuption
    .intr(1'b0),
    .bus_dat_i(master_dat_o[`CPU_NO]),
    .bus_dat_o(master_dat_i[`CPU_NO]),
    .bus_addr(master_addr[`CPU_NO]),
    .bus_num(master_num[`CPU_NO]),
    .bus_req(master_req[`CPU_NO]),
    .bus_wen(master_wen[`CPU_NO]),
    .bus_mode(master_mode[`CPU_NO]),
    .bus_ready(master_ready[`CPU_NO])
  );

endmodule