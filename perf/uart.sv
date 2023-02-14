`ifndef _UART
`define _UART

`include "uibi.sv"

`define UART_ADDR `BITRANGE(bus_addr, 5, 2)

module uart #
(
  parameter clock_freq = `SYS_FREQ,
  parameter baud_rate = 115200,
  parameter baud_clock_nr = clock_freq / baud_rate
)(
  input   wire  clk,
  input   wire  rst,
  input   wire  rx_line,
  output  wire  tx_line,
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

  //rw ctrl[0]: tx ctrl 1 valid
  //rw ctrl[1]: rx ctrl 1 valid
  reg `WIDE(`XLEN) uart_ctrl;
  
  //ro status[0]: tx status 1 busy
  //rw status[1]: rx status 1 ready
  reg uart_status_tx, uart_status_rx;
  wire `WIDE(`XLEN) uart_status = {30'b0, uart_status_rx, uart_status_tx};
  
  //rw baud_clock_nr
  reg `WIDE(`XLEN) uart_baud;

  //wo txdata
  reg `WIDE(`XLEN) uart_txdata;
  reg tx_valid, tx_ready;

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
      uart_baud   <= baud_clock_nr;
      uart_txdata <= '0;
      uart_status_rx <= '0;
    end else if(bus_req && bus_wen) begin
      case (`UART_ADDR)
        UART_CTRL: uart_ctrl <= bus_dat_i;
        UART_STATUS: uart_status_rx <= bus_dat_i[1];
        UART_BAUD: uart_baud <= bus_dat_i;
        UART_TXDATA: begin 
          if (uart_ctrl[0] && ~uart_status_tx) begin
            `RECEIVE_BUS_DATA(uart_txdata)
            //set tx busy
          end
        end
        default: ;
      endcase
    end
  end

  //tx busy
  `ALWAYS_CR begin
    if (~rst) begin
      uart_status_tx <= '0;
    end else if(bus_wen && bus_req) begin
      if((`UART_ADDR == UART_TXDATA) && uart_ctrl[0] && ~uart_status_tx)
        uart_status_tx <= 1'b1;
      else if (tx_ready) uart_status_tx <= 1'b0;
    end
    else if (tx_ready) uart_status_tx <= 1'b0;
  end

  //tx valid
  `ALWAYS_CR begin
    if (~rst) begin
      tx_valid <= '0;
    end else if(bus_wen && bus_req) begin
      if((`UART_ADDR == UART_TXDATA) && uart_ctrl[0] && ~uart_status_tx)
        tx_valid <= 1'b1;
      else tx_valid <= 1'b0;
    end
    else tx_valid <= 1'b0;
  end

  //tx stm
  //set tx_reg
  reg `WIDE(16) cycle_cnt;
  reg tx_reg;
  reg `WIDE(4) bit_cnt;
  `ALWAYS_CR begin
    if (~rst) begin
      state     <= BUS_IDLE;
      cycle_cnt <= '0;
      bit_cnt   <= '0;
      tx_reg    <= '1;
      tx_ready  <= '0;
    end else begin
      if (state == BUS_IDLE) begin
        tx_ready <= 1'b0;
        if (tx_valid == 1'b1) begin
          state     <=  BUS_START;
          cycle_cnt <=  '0;
          bit_cnt   <=  '0;
          tx_reg    <=  '0;
        end
        else tx_reg <= 1'b1;
      end else begin
        cycle_cnt <= cycle_cnt + 16'd1;
        //some error here but just ignore it
        if (cycle_cnt == `BITRANGE(uart_baud, 16, 0)) begin
          cycle_cnt <= 16'd0;
          case (state)
            BUS_START: begin
              tx_reg  <=  uart_txdata[bit_cnt];
              state   <=  BUS_SEND_BYTE;
              bit_cnt <=  bit_cnt + 4'd1;
            end 
            BUS_SEND_BYTE: begin
              bit_cnt <=  bit_cnt + 4'd1;
              if (bit_cnt == 4'd8) begin
                state   <= BUS_STOP;
                tx_reg  <= 1'b1;
              end else
                tx_reg  <= uart_txdata[bit_cnt];
            end
            BUS_STOP: begin
              tx_reg <= 1'b1;
              state <= BUS_IDLE;
              tx_ready <= 1'b1;
            end
          endcase
        end
      end
    end
  end

  //send tx_reg
  assign tx_line = tx_reg;

  //rx line sampling
  reg rx_q0, rx_q1;
  `ALWAYS_CR begin
    if (~rst) begin
      rx_q0 <= '0;
      rx_q1 <= '0;
    end else begin
      rx_q0 <= rx_line;
      rx_q1 <= rx_q0;
    end 
  end

  //check negedge
  wire rx_nsample = rx_q1 && ~rx_q0;

  reg rx_reg, rx_start;
  reg `WIDE(16) rx_clk_cnt, rx_div_cnt;
  reg `WIDE(4) rx_clk_edge_cnt;
  reg rx_done, rx_over, rx_clk_edge_level;

  `ALWAYS_CR begin
    if (~rst) rx_clk_cnt <= '0;
    else if(rx_start) begin
      //some error here but just ignore it
      if (rx_clk_cnt == rx_div_cnt)
        rx_clk_cnt <= '0;
      else rx_clk_cnt <= rx_clk_cnt + 1'b1;
    end
    else rx_clk_cnt <= '0;
  end

  `ALWAYS_CR begin
    if (~rst) begin
      rx_div_cnt <= '0;
    end else begin
      if (rx_start && rx_clk_edge_cnt == 4'h0)
        rx_div_cnt <= {1'b0, `BITRANGE(uart_baud, 16, 1)};
      else rx_div_cnt <= `BITRANGE(uart_baud, 16, 0);
    end
  end

  `ALWAYS_CR begin
    if (~rst) rx_start <= '0;
    else begin
      if (uart_ctrl[1]) begin
        if (rx_nsample) begin
          rx_start <= 1'b1;
        end else if (rx_clk_edge_cnt == 4'd9) begin
          rx_start <= 1'b0;
        end
      end
      else rx_start <= 1'b0;
    end
  end

  `ALWAYS_CR begin
    if (~rst) begin
      rx_clk_edge_cnt   <=  '0;
      rx_clk_edge_level <=  '0;
    end else if (rx_start) begin
      if (rx_clk_cnt == rx_div_cnt) begin
        if (rx_clk_edge_cnt == 4'd9) begin
          rx_clk_edge_cnt   <= '0;
          rx_clk_edge_level <= '0;
        end else begin
          rx_clk_edge_cnt <= rx_clk_edge_cnt + 4'b1;
          rx_clk_edge_cnt <= 1'b1;
        end
      end else rx_clk_edge_level <= 1'b0;
    end
  end

  `ALWAYS_CR begin
    if (~rst) begin
      uart_rxdata <= '0;
      rx_over     <= '0;
    end else begin
      if (rx_start) begin
        if (rx_clk_edge_level) begin
          case (rx_clk_edge_cnt)
            2, 3, 4, 5, 6, 7, 8, 9: begin
              uart_rxdata <= uart_rxdata | (rx_line << (rx_clk_edge_cnt - 2));
              if (rx_clk_edge_cnt == 4'h9) rx_over <= 1'b1;
            end
            default: ;
          endcase
        end
      end else begin
        uart_rxdata <= '0;
        rx_over <= '0;
      end
    end
  end

endmodule

`endif