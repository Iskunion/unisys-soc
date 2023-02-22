`include "cpu.sv"
`include "uib.sv"
`include "perfs.sv"
`include "uibi.sv"
`include "mainmem.sv"
`include "uart.sv"
`include "gmem.sv"
`include "timer.sv"

module clock_generator # (
  parameter targetfreq = `SYS_FREQ
)(
  input wire o_clk,
  output reg n_clk
);

  localparam clock_nr = 50000000 / targetfreq - 1;

  reg `WIDE(`XLEN) cnt;

  initial begin
    cnt <= '0;
    n_clk <= '0;
  end

  always_ff @(posedge o_clk) begin
    if (cnt == clock_nr) begin
      cnt <= '0;
      n_clk <= ~n_clk;
    end
    else cnt <= cnt + `XLEN'b1;
  end

endmodule


module numScreen(
    input wire clock,
    input wire rst,
    input wire [7:0] en,
    input wire [7:0][3:0] display,
    input wire [7:0] dots,
    output wire [7:0] targeten,
    output wire [7:0] targetdisplay
);
    wire [7:0][7:0] monitorDisplay;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1)
            begin: seggroups
            seg7 myseg7(
                .N(display[i]), 
                .dot(dots[i]),
                .target(monitorDisplay[i])
            );
        end
    endgenerate

    ledmonitor mainmonitor(
        .clock(clock),
        .en(en),
        .rst(rst),
        .display(monitorDisplay),
        .targeten(targeten),
        .targetdisplay(targetdisplay)
    );

endmodule


module seg7(
    input wire [3:0] N,
    input wire dot,
    output wire [7:0] target
);
    reg [6:0] body;

    always @(N, dot) begin
        casex (N)
            4'hf: body = 7'b0001110;
            4'he: body = 7'b0000110;
            4'hd: body = 7'b0100001;
            4'hc: body = 7'b1000110;
            4'hb: body = 7'b0000011;
            4'ha: body = 7'b0001000;
            4'h9: body = 7'b0010000;
            4'h8: body = 7'b0000000;
            4'h7: body = 7'b1111000;
            4'h6: body = 7'b0000010;
            4'h5: body = 7'b0010010;
            4'h4: body = 7'b0011001;
            4'h3: body = 7'b0110000;
            4'h2: body = 7'b0100100;
            4'h1: body = 7'b1111001;
            4'h0: body = 7'b1000000;
            default: body = 7'b1111111;
        endcase
    end

    assign target = {~dot, body};
endmodule

module ledmonitor(
    input wire clock,
    input wire rst,
    input wire [7:0] en,
    input wire [7:0][7:0] display,
    output wire [7:0] targeten,
    output wire [7:0] targetdisplay
);

    reg [2:0] select;

    assign targeten = (8'b11111111 ^ (8'b1 << select)) | (~en);
    assign targetdisplay = display[select];

    always @(posedge clock, negedge rst) begin
        if (!rst)
            select <= 0;
        else begin
            if (select == 7)
                select <= 0;
            else
                select <= (select + 1);
        end
    end

endmodule

module unisys(
  input   wire    ext_clock,
  input   wire    rst,
  input   wire    uart_rx,
  output  wire    uart_tx,
  output  wire  [15:0] LED,
  output  wire  [7:0]  HEX,
  output  wire  [7:0]  AN
);

  assign LED[0] = uart_tx;

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

`ifdef _IMPLEMENT
  wire clk;
  clock_generator clock_generator_0 (ext_clock, clk);
`endif

`ifdef _SIMULATE
  wire clk = ext_clock;
`endif

  //intr
  wire intr;

  //gpu
  wire `WIDE(`GMEM_WIDTH) vgactl_addr;
  wire `WIDE(`COLOR_WIDTH) vgactl_dat;

  //debug
  wire clk_10KHz;
  clock_generator #(.targetfreq(10000)) clock_generator_1 (ext_clock, clk_10KHz);
  wire `WIDE(`XLEN) debug_content;
  numScreen numScreen_0(
    .clock(clk_10KHz),
    .rst(rst),
    .en(8'hff),
    .display(debug_content),
    .dots(8'h0),
    .targeten(AN),
    .targetdisplay(HEX)
  );

  //the bus
  uib uib_0 (.*);

  //masters

  //cpu
  cpu cpu_0(
    .clk(clk),
    .rst(rst),
    //never trigger interuption
    .intr(intr),
    `STDMASTER(CPU),
    .pc_debug(debug_content)
  );

  //slaves
  mainmem mainmem_0(
    .clk(~clk),
    .rst(rst),
    `STDSLAVE(MAINMEM)
  );

  uart uart_0(
    .clk(~clk),
    .rst(rst),
    .tx_line(uart_tx),
    .rx_line(uart_rx),
    `STDSLAVE(UART)
  );

  timer timer_0(
    .clk(~clk),
    .rst(rst),
    .intr(intr),
    `STDSLAVE(TIMER)
  );

  gmem gmem_0(
    .clk(~clk),
    .rst(rst),
    .vgactl_addr(vgactl_addr),
    .vgactl_dat(vgactl_dat),
    `STDSLAVE(GMEM)
  );

endmodule