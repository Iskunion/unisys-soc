`ifndef _TIMER
`define _TIMER

`include "uibi.sv"

`define TIMER_ADDR `BITRANGE(bus_addr, 4, 2)

module timer #
(
  parameter clock_freq = 100000000,
  parameter nr_clock_us = clock_freq / 1000000,
  parameter nr_clock_s  = clock_freq
)(
  input wire clk,
  input wire rst,
  output reg intr,
  `UIBI_SLAVE
);


  `CONVERT_BUS_MODE
  `PROXY_BUS_DATA

  typedef enum bit `WIDE(2) {
    TIMER_NOWTIME     = 2'b00,
    TIMER_STAMP       = 2'b01,
    TIMER_INTR_NR     = 2'b10
  } timer_addr;

  //addr 0x0 rw
  reg `WIDE(`XLEN) nowtime;
  
  //addr 0x4 ro
  reg `WIDE(`XLEN) stamp;

  //addr 0x8 rw
  reg `WIDE(`XLEN) intr_nr;

  //internal count
  reg `WIDE(`XLEN) cnt_us, cnt_s, cnt_intr;

  initial begin
    nowtime <= 32'h63DE120D;
  end

  //one stamp per us
  `ALWAYS_CR begin
    if (~rst) begin
      stamp   <= '0;
      cnt_us  <= '0;
    end else begin
      if (cnt_us == nr_clock_us - 1) begin
        cnt_us <= '0;
        stamp  <= stamp + 32'b1;
      end 
      else cnt_us <= cnt_us + 32'b1;
    end
  end

  //timer interruption
  `ALWAYS_CR begin
    if (~rst) begin
      cnt_intr    <= '0;
      intr        <= '0;
    end
    else if (cnt_us == nr_clock_us - 1) begin
      if (cnt_intr == intr_nr - 32'b1) begin
        cnt_intr  <=  '0;
        intr      <=  1'b1;
      end
      else begin
        cnt_intr  <=  cnt_intr + 32'b1;
        intr      <=  '0;
      end
    end
  end

  //cnt_s
  `ALWAYS_CR begin
    if (~rst)
      cnt_s <= '0;
    else begin
      if (cnt_s == nr_clock_s - 1)
        cnt_s <= '0;
      else cnt_s <= cnt_s + 32'b1;
    end
  end

  //intr_nr writeable
  `ALWAYS_CR begin
    if (~rst)
      intr_nr <= '0;
    else begin
      if (bus_req && bus_wen && (`TIMER_ADDR == TIMER_INTR_NR))
        `RECEIVE_BUS_DATA(intr_nr)
    end
  end

  //nowtime increase 1 per sec and writeable
  `ALWAYS_CR begin
    if (~rst)
      nowtime <= '0;
    else begin
      if (bus_req && bus_wen && (`TIMER_ADDR == TIMER_NOWTIME))
        `RECEIVE_BUS_DATA(nowtime)
      else if (cnt_s == nr_clock_s - 1)
        nowtime <= nowtime + 32'b1;
    end
  end

  //read registers
  `ALWAYS_CR begin
    if (~rst)
      bus_dat_o_r <= '0;
    else if (bus_req) begin
      case (`TIMER_ADDR)
        TIMER_INTR_NR: bus_dat_o_r <= intr_nr;
        TIMER_NOWTIME: bus_dat_o_r <= nowtime;
        TIMER_STAMP:   bus_dat_o_r <= stamp;
        default:       bus_dat_o_r <= '0;
      endcase
    end else
      bus_dat_o_r <= '0;
  end

  assign bus_ready = 1'b1;

endmodule

`endif