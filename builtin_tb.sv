`include "unisys.sv"

`ifndef SIMTIME
`define SIMTIME 1000000
`endif

`timescale 1ns/1ps

module unisys_bench();

reg ps2_clk;
reg ps2_data;

initial ps2_clk = 1'b1;

parameter [31:0] kbd_clk_period = 60;

task kbd_sendcode;
  input [7:0] code; // key to be sent
  integer i;
  reg[10:0] send_buffer;
  begin
    send_buffer[0] = 1'b0;
    // start bit
    send_buffer[8:1] = code;
    // code
    send_buffer[9] = ~(^code); // odd parity bit
    send_buffer[10] = 1'b1;
    // stop bit
    i = 0;
    while( i < 11) begin
    // set kbd_data
      ps2_data = send_buffer[i];
      #(kbd_clk_period/2) ps2_clk = 1'b0;
      #(kbd_clk_period/2) ps2_clk = 1'b1;
      i = i + 1;
    end
  end
endtask

reg clk = 0;
always #5
  clk = ~clk;

reg rst = 1;
initial begin
  #10
  rst = 0;
  #10
  rst = 1;
  #`SIMTIME
  $finish;
end

integer ix;

initial begin
  #10000
  kbd_sendcode(8'haa);
  #10000
  kbd_sendcode(8'h52);
  #10000
  kbd_sendcode(8'hf0);
  #10000
  kbd_sendcode(8'h52);
end

unisys unisys_1(
  .ext_clock(clk),
  .rst(rst),
  .uart_rx(1'b0),
  .ps2_clk(ps2_clk),
  .ps2_data(ps2_data)
);

initial begin
  $dumpfile("build/wave.vcd");
  $dumpvars;
end

integer i;
`ALWAYS_CR begin
  if (unisys_1.cpu_0.core_0.current_state == 5'b00001) begin
    $display("pc: %h", unisys_1.cpu_0.core_0.pc_now);
  end
end

endmodule

// module cpu_bench();

// reg clk = 0;
// always #5
//   clk = ~clk;

// reg rst = 1;
// initial begin
//   #10
//   rst = 0;
//   #10
//   rst = 1;
//   #100000
//   $finish;
// end

// initial begin
//   // $dumpfile("build/wave.vcd");
//   // $dumpvars;
// end

// wire `WIDE(`XLEN) bus_dat_w, bus_dat_r;
// wire bus_req, bus_wen, bus_ready;
// wire `WIDE(3) bus_mode;
// wire `WIDE(`XLEN-`SLAVE_WIDTH) bus_addr;
// wire `WIDE(`SLAVE_WIDTH) bus_num;

// cpu cpu_1(
//   .clk(clk),
//   .rst(rst),
//   .intr(1'b0),
//   .bus_dat_o(bus_dat_w),
//   .bus_dat_i(bus_dat_r),
//   .bus_addr(bus_addr),
//   .bus_num(bus_num),
//   .bus_req(bus_req),
//   .bus_wen(bus_wen),
//   .bus_mode(bus_mode),
//   .bus_ready(bus_ready)
// );

// integer i;

// `ALWAYS_CR begin
//   if (cpu_1.core_0.current_state == 5'b00001) begin
//     $display("pc: %h", cpu_1.core_0.pc_now);
//     // for (i = 0; i < 32; i = i + 1)
//     //   $display("reg %d : %h", i, cpu_1.core_0.gprfile_0.gprs[i]);
//   end
// end

// mainmem mainmem_1(
//   .clk(~clk),
//   .rst(rst),
//   .bus_dat_i(bus_dat_w),
//   .bus_dat_o(bus_dat_r),
//   .bus_addr(bus_addr),
//   .bus_req(bus_req),
//   .bus_wen(bus_wen),
//   .bus_mode(bus_mode),
//   .bus_ready(bus_ready)
// );

// endmodule