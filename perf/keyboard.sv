`ifndef _KEYBOARD
`define _KEYBOARD

`include "uibi.sv"

module keyboard (
  input wire clk,
  input wire rst,
  input wire ps2_clk,
  input wire ps2_data,
  `UIBI_SLAVE
);
  `CONVERT_BUS_MODE
  `PROXY_BUS_DATA

  wire ready, overflow;
  wire `WIDE(8) data;

  ps2Keyboard ps2Keyboard_0(
    .clk(clk),
    .clrn(rst),
    .ready(ready),
    .overflow(overflow),
    .ps2_clk(ps2_clk),
    .ps2_data(ps2_data),
    .nextdata_n(~bus_req),
    .data(data)
  );

  reg `WIDE(8) keycode, extcode;

  // typedef enum bit `WIDE(4){
  //   IDLE      = 4'h1,
  //   INITIAL   = 4'h2,
  //   BUS_SEND_BYTE = 4'h4,
  //   BUS_STOP      = 4'h8
  // } bus_state;

  // bus_state state;


  `ALWAYS_CR begin
  end

  always @(*) begin
    if (bus_req && rst)
      bus_dat_o_r = {{(`XLEN-16){1'b0}}, extcode, keycode};
    else bus_dat_o_r = '0;
  end

endmodule


module ps2Keyboard(clk, clrn, ps2_clk, ps2_data, nextdata_n, data, ready, overflow);
    input clk, clrn, ps2_clk, ps2_data;
    input nextdata_n;
    output [7:0] data;
    output reg ready;
    output reg overflow; // fifo overflow
    // internal signal, for test
    reg [9:0] buffer; // ps2_data bits
    reg [7:0] fifo[63:0];// data fifo
    reg [5:0] w_ptr, r_ptr;// fifo write and read pointers
    reg [3:0] count; // count ps2_data bits
    // detect falling edge of ps2_clk
    reg [2:0] ps2_clk_sync;
    
    always @(posedge clk)
        ps2_clk_sync <= {ps2_clk_sync[1:0], ps2_clk};
    
    wire sampling = ps2_clk_sync[2] & ~ps2_clk_sync[1];

    always @(posedge clk, negedge clrn)
    begin
        if (!clrn) begin // reset
            count <= 0;
            w_ptr <= 0;
            r_ptr <= 0;
            overflow <= 0;
            ready <= 0;
        end
        else 
        begin
            if (overflow) begin
                w_ptr <= 0;
                r_ptr <= 0;
                ready <= 0;
                overflow <= 0;
            end
            if (ready) // ready to output next data
                if (!nextdata_n) begin //read next data
                    r_ptr <= r_ptr + 6'b1;
                    if (w_ptr == (r_ptr + 6'b1)) //empty
                        ready <= 0;
                end
            if (sampling) begin
                if (count == 10) begin
                    if ((buffer[0] == 0) && (ps2_data) && (^buffer[9:1])) begin
                        fifo[w_ptr] <= buffer[8:1]; // keyboard scan code
                        w_ptr <= w_ptr + 6'b1;
                        ready <= 1;
                        overflow <= overflow | (r_ptr == (w_ptr + 6'b1));
                    end
                    count <= 0;
                end 
                else begin
                    buffer[count] <= ps2_data; // store ps2_data
                    count <= count + 1;
                end
            end
        end
    end
    assign data = fifo[r_ptr]; //always set output data
endmodule


`endif