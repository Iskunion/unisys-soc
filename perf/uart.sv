`ifndef _UART
`define _UART

`include "uibi.sv"

`define UART_ADDR `BITRANGE(bus_addr, 5, 2)

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
  reg tx_vaild, tx_ready;
  
  //ro rxdata
  reg `WIDE(`XLEN) uart_rxdata;
  

  integer i;

  reg rx_ready;
  //dont need to hold on
  assign bus_ready = bus_wen ? 1'b1 : rx_ready;

  //read registers
  `ALWAYS_CR begin
    if (~rst)
      bus_dat_o_r <= '0;
    else if (~bus_req)
      bus_dat_o_r <= '0; 
    else
      case (`UART_ADDR)
        UART_CTRL:    bus_dat_o_r <= uart_ctrl;
        UART_STATUS:  bus_dat_o_r <= uart_status;
        UART_BAUD:    bus_dat_o_r <= uart_baud;
        UART_RXDATA:  bus_dat_o_r <= uart_rxdata;
        default:      bus_dat_o_r <= '0;
      endcase
  end
  
  //write registers
  `ALWAYS_CR begin
    if (~rst) begin
      uart_ctrl   <= '0;
      uart_status <= '0;
      uart_baud   <= baud_clock_nr;
      uart_rxdata <= '0;
      uart_txdata <= '0;
    end else if(bus_req && bus_wen) begin
      case (`UART_ADDR)
        UART_CTRL: uart_ctrl <= bus_dat_i;
        UART_STATUS: uart_status[1] <= bus_dat_i[1];
        UART_BAUD: uart_baud <= bus_dat_i;
        UART_TXDATA: begin 
          if (uart_ctrl[0] && ~uart_status[0]) begin
            `RECEIVE_BUS_DATA(uart_txdata)
            tx_vaild <= 1'b1;
            //set tx busy
            uart_status[0] <= 1'b1;
          end
        end
        default: ;
      endcase
    end else begin
      tx_vaild <= 1'b0;
      if (tx_ready)
        uart_status[0] <= 1'b0;
      // if (uart_ctrl[1])
    end
    
  end

  //tx valid
  `ALWAYS_CR begin
    if (~rst) begin
      tx_vaild <= '0;
    end else if(bus_wen) begin
      if((`UART_ADDR == UART_TXDATA) && uart_ctrl[0] && ~uart_status[0])
        tx_vaild <= 1'b1;
      else tx_vaild <= 1'b0;
    end
  end

  //tx stm
  reg `WIDE(16) cycle_cnt;
  `ALWAYS_CR begin
    if (~rst) begin
      state <= BUS_IDLE;
      cycle_cnt <= '0;
    end
  end

endmodule

`endif