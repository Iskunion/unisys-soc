










  
  


  
  






















module core(
  input   wire                  clk,
  input   wire                  rst,
  input   wire                  intr,
  output  wire                  mem_wen,
  output  wire  [(3)-1:0]        mem_mode,
  output  wire  [(32)-1:0]    mem_addr,  
  input   wire  [(32)-1:0]    mem_dat_i,
  output  wire  [(32)-1:0]    mem_dat_o,
  input   wire                  mem_ready
);


endmodule























  
  


  
  


  
  


  
  


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
  input   wire  [(3)-1:0]                    mem_mode,
  input   wire  [(32)-1:0]                mem_addr,
  input   wire  [(32)-1:0]                mem_dat_i,
  output  wire  [(32)-1:0]                mem_dat_o,
  output  wire                              bus_ready_o,
  //bus side
  input   wire  [(32)-1:0]                bus_dat_i,
  output  wire  [(32)-1:0]                bus_dat_o,
  output  wire  [(32 - 3)-1:0] bus_addr,
  output  wire  [(3)-1:0]         bus_num,
  output  wire                              bus_req,
  output  wire                              bus_wen,
  output  wire  [(3)-1:0]                    bus_mode,
  input   wire                              bus_ready_i
);
  assign bus_wen      =   mem_wen;
  assign bus_req      =   1'b1;
  assign bus_mode     =   mem_mode;
  assign bus_ready_o  =   bus_ready_i;
  assign bus_dat_o    =   mem_dat_i;
  assign mem_dat_o    =   bus_dat_i;
  assign bus_num      =   mem_addr[32-1:32 - 3];
  assign bus_addr     =   mem_addr[32 - 3-1:0];
endmodule

//cpu: core with mmu integrated
module cpu(
  input   wire                              clk,
  input   wire                              rst,
  input   wire                              intr,
  input   wire  [(32)-1:0]                bus_dat_i,
  output  wire  [(32)-1:0]                bus_dat_o,
  output  wire  [(32 - 3)-1:0] bus_addr,
  output  wire  [(3)-1:0]         bus_num,
  output  wire                              bus_req,
  output  wire                              bus_wen,
  output  wire  [(3)-1:0]                    bus_mode,
  input   wire                              bus_ready
);

  //core output/mmu input signals
  wire mem_wen;
  wire [(3)-1:0] mem_mode;
  wire [(32)-1:0] mem_addr, bus_dat_w;

  //mmu output/core input signals
  wire mem_ready;
  wire [(32)-1:0] bus_dat_r;

  core core_0(
    .clk(clk),
    .rst(rst),
    .intr(intr),
    .mem_wen(mem_wen),
    .mem_mode(mem_mode),
    .mem_addr(mem_addr),
    .mem_dat_i(bus_dat_r),
    .mem_dat_o(bus_dat_w),
    .mem_ready(mem_ready)
  );

  mmu mmu_0(
    .mem_wen(mem_wen),
    .mem_mode(mem_mode),
    .mem_addr(mem_addr),
    .mem_dat_i(bus_dat_w),
    .mem_dat_o(bus_dat_r),
    .bus_ready_o(mem_ready),
    .bus_dat_i(bus_dat_i),
    .bus_dat_o(bus_dat_o),
    .bus_addr(bus_addr),
    .bus_num(bus_num),
    .bus_req(bus_req),
    .bus_wen(bus_wen),
    .bus_mode(bus_mode),
    .bus_ready_i(bus_ready)
  );

endmodule


















//A simple bus interface for devices
module uib(
  //master side
  input   wire  [(2**1)-1:0] [(32)-1:0]              master_dat_i,
  output  reg   [(2**1)-1:0] [(32)-1:0]              master_dat_o,
  input   wire  [(2**1)-1:0] [(32-3)-1:0] master_addr,
  input   wire  [(2**1)-1:0] [(3)-1:0]       master_num,
  input   wire  [(2**1)-1:0]                           master_req,
  input   wire  [(2**1)-1:0]                           master_wen,
  input   wire  [(2**1)-1:0] [(3)-1:0]                  master_mode,
  output  reg   [(2**1)-1:0]                           master_ready,
  //slave side
  input   wire  [(2**3)-1:0]  [(32)-1:0]              slave_dat_i,
  output  reg   [(2**3)-1:0]  [(32)-1:0]              slave_dat_o,
  output  reg   [(2**3)-1:0]  [(32-3)-1:0] slave_addr,
  output  reg   [(2**3)-1:0]                            slave_req,
  output  reg   [(2**3)-1:0]                            slave_wen,
  output  reg   [(2**3)-1:0]  [(3)-1:0]                  slave_mode,
  input   wire  [(2**3)-1:0]                            slave_ready
);

  reg [(2**1)-1:0] [(32)-1:0] master_dat_r;
  reg [(2**3)-1:0]  [(32)-1:0] slave_dat_r;

  //only for the cpu now
  wire [(1)-1:0] curmaster = 1'h0;
  wire [(3)-1:0] curslave = master_num[curmaster];

  integer i;

  always @(*) begin
    for (i = 0; i < 2**3; i = i + 1) begin
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
    for (i = 0; i < 2**1; i = i + 1) begin
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







module unisys(
  input   wire    clk,
  input   wire    rst
);

  //master busio
  wire [(2**1)-1:0] [(32)-1:0] master_dat_i, master_dat_o;
  wire [(2**1)-1:0] [(32 - 3)-1:0] master_addr;
  wire [(2**1)-1:0] [(3)-1:0] master_num;
  wire [(2**1)-1:0] [(3)-1:0] master_mode;
  wire [(2**1)-1:0] master_wen, master_req, master_ready;

  //slave busio
  wire [(2**3)-1:0] [(32)-1:0] slave_dat_i, slave_dat_o;
  wire [(2**3)-1:0] [(32 - 3)-1:0] slave_addr;
  wire [(2**3)-1:0] [(3)-1:0] slave_mode;
  wire [(2**3)-1:0] slave_wen, slave_req, slave_ready;

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
    .bus_dat_i(master_dat_o[0]),
    .bus_dat_o(master_dat_i[0]),
    .bus_addr(master_addr[0]),
    .bus_num(master_num[0]),
    .bus_req(master_req[0]),
    .bus_wen(master_wen[0]),
    .bus_mode(master_mode[0]),
    .bus_ready(master_ready[0])
  );

endmodule