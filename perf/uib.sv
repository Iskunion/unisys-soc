`ifndef _UIB
`define _UIB
`include "common.sv"

//A simple bus interface for devices
module uib(
  //master side
  input   wire  `WIDE(`MASTER_SIZE) `WIDE(`XLEN)              master_dat_i,
  output  reg   `WIDE(`MASTER_SIZE) `WIDE(`XLEN)              master_dat_o,
  input   wire  `WIDE(`MASTER_SIZE) `WIDE(`XLEN-`SLAVE_WIDTH) master_addr,
  input   wire  `WIDE(`MASTER_SIZE) `WIDE(`SLAVE_WIDTH)       master_num,
  input   wire  `WIDE(`MASTER_SIZE)                           master_req,
  input   wire  `WIDE(`MASTER_SIZE)                           master_wen,
  input   wire  `WIDE(`MASTER_SIZE) `WIDE(3)                  master_mode,
  output  reg   `WIDE(`MASTER_SIZE)                           master_ready,
  //slave side
  input   wire  `WIDE(`SLAVE_SIZE)  `WIDE(`XLEN)              slave_dat_i,
  output  reg   `WIDE(`SLAVE_SIZE)  `WIDE(`XLEN)              slave_dat_o,
  output  reg   `WIDE(`SLAVE_SIZE)  `WIDE(`XLEN-`SLAVE_WIDTH) slave_addr,
  output  reg   `WIDE(`SLAVE_SIZE)                            slave_req,
  output  reg   `WIDE(`SLAVE_SIZE)                            slave_wen,
  output  reg   `WIDE(`SLAVE_SIZE)  `WIDE(3)                  slave_mode,
  input   wire  `WIDE(`SLAVE_SIZE)                            slave_ready
);

  reg `WIDE(`MASTER_SIZE) `WIDE(`XLEN) master_dat_r;
  reg `WIDE(`SLAVE_SIZE)  `WIDE(`XLEN) slave_dat_r;

  //only for the cpu now
  wire `WIDE(`MASTER_WIDTH) curmaster = `MASTER_WIDTH'h0;
  wire `WIDE(`SLAVE_WIDTH) curslave = master_num[curmaster];

  integer i;

  always @(*) begin
    for (i = 0; i < `SLAVE_SIZE; i = i + 1) begin
      if (i == curslave) begin
        slave_dat_o[i]      =   master_dat_i[curmaster];
        slave_req[i]        =   master_req[curmaster];
        slave_mode[i]       =   master_mode[curmaster];
        slave_wen[i]        =   master_wen[curmaster];
        slave_addr[i]       =   master_addr[curmaster];
      end
      else begin
        slave_dat_o[i]      =   '0;
        slave_req[i]        =   '0;
        slave_mode[i]       =   '0;
        slave_wen[i]        =   '0;
        slave_addr[i]       =   '0;
      end
    end
  end

  always @(*) begin
    for (i = 0; i < `MASTER_SIZE; i = i + 1) begin
      if (i == curmaster) begin
        master_ready[i] = slave_ready[curslave];
        master_dat_o[i] = slave_dat_i[curslave];
      end
      else begin
        master_ready[i] = '0;
        master_dat_o[i] = '0;
      end
    end
  end

endmodule

`endif