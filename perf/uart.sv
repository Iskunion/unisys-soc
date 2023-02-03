`ifndef _UART
`define _UART

`include "uibi.sv"

module uart #
(
  parameter clock_freq = 100000000,
  parameter baud_rate = 115200,
  parameter baud_clock_nr = clock_freq / baud_rate
)(
  input wire clk,
  input wire rst,
  `UIBI_SLAVE
);

  `CONVERT_BUS_MODE
  `PROXY_BUS_DATA

  typedef enum bit `WIDE(4){
    BUS_IDLE      = 4'h1,
    BUS_START     = 4'h2,
    BUS_SEND_BYTE = 4'h4,
    BUS_STOP      = 4'h8
  } bus_state;

  bus_state state;

  typedef enum bit `WIDE(3) {
    UART_CTRL     = 3'o0,
    UART_STATUS   = 3'o1,
    UART_BAUD     = 3'o2,
    UART_TXDATA   = 3'o3,
    UART_RXDATA   = 3'o4
  } uart_addr;

  //rw ctrl[0]: tx ctrl 1 vaild
  //rw ctrl[1]: rx ctrl 1 vaild
  reg `WIDE(`XLEN) uart_ctrl;
  
  //ro status[0]: tx status 1 busy
  //rw status[1]: rx status 1 ready
  reg `WIDE(`XLEN) uart_status;
  
  //rw baud_clock_nr
  reg `WIDE(`XLEN) uart_baud;

  //wo txdata
  reg `WIDE(`XLEN) uart_txdata;
  
  //ro rxdata
  reg `WIDE(`XLEN) uart_rxdata;
  

  integer i;

  //dont need to hold on
  assign bus_ready = 1'b1;

  //read registers
  `ALWAYS_CR begin
    if (~rst) begin
    end
    case (`BITRANGE(bus_addr, 5, 2))
      UART_CTRL:    bus_dat_o_r <= uart_ctrl;
      UART_STATUS:  bus_dat_o_r <= uart_status;
      UART_BAUD:    bus_dat_o_r <= uart_baud;
      UART_RXDATA:  bus_dat_o_r <= uart_rxdata;
      default:      bus_dat_o_r <= '0;
    endcase
  end
  
  //write registers
  `ALWAYS_CR begin
    // case (`BITRANGE(bus_addr, 5, 2))
    //   UART_CTRL: 
    //     uart_ctrl <= bus_dat_i;
    //   UART_STATUS: begin `RECEIVE_BUS_DATA(uart_status) end
    //   UART_BAUD: begin `RECEIVE_BUS_DATA(uart_baud) end
    //   UART_TXDATA: begin 
    //     `RECEIVE_BUS_DATA(uart_txdata)
    //   end
    //   default: ;
    // endcase
  end

  always @(posedge clk) begin
    if (~rst) begin
      
    end
  end

endmodule

`endif