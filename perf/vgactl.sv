`ifndef _VGACTL
`define _VGACTL

`define H_FRONTPROCH (96)
`define H_ACTIVE (144)
`define H_BACKPORCH (784)
`define H_TOTAL (800)
`define V_FRONTPROCH (2)
`define V_ACTIVE (35)
`define V_BACKPORCH (515)
`define V_TOTAL (525)
`define S_WIDTH (640)
`define S_HEIGHT (480)
`define C_FIELD_WIDTH (70)
`define C_FIELD_HEIGHT (30)

`include "uibi.sv"
`include "gmem.sv"

module vgactl(
  input wire clk,
  input wire vgaclk,
  input wire rst,
  `UIBI_SLAVE,
  output  wire  `WIDE(`GMEM_WIDTH) vgactl_addr,
  input   wire  `WIDE(`COLOR_WIDTH) vgactl_dat,
  output  wire  [3:0]  vga_r,
  output  wire  [3:0]  vga_g,
  output  wire  [3:0]  vga_b,
  output  wire         vga_hs,
  output  wire         vga_vs
);
  
  wire [9:0] h_addr, v_addr;
  wire valid;

  vga_interface vga_interface_0 (
    .clk(vgaclk),
    .rst(rst),
    .h_addr(h_addr),
    .v_addr(v_addr),
    .hsync(vga_hs),
    .vsync(vga_vs),
    .valid(valid)
  );

  `CONVERT_BUS_MODE
  `PROXY_BUS_DATA

  assign bus_ready = 1'b1;

  reg `WIDE(`XLEN) vga_ctrl_reg = 32'h14000f0;

  `ALWAYS_CR if (~rst) begin
    vga_ctrl_reg = 32'h14000f0;
  end

  `ALWAYS_CR if (~rst) begin
    bus_dat_o_r <= '0;
  end else if(bus_req) begin
    bus_dat_o_r <= vga_ctrl_reg;
  end else
    bus_dat_o_r <= '0;

  assign vgactl_addr = {v_addr[9:1], 8'b0} + {2'b0, v_addr[9:1], 6'b0} + {8'b0, h_addr[9:1]};

  //256 colors
  assign vga_r = ~valid ? '0 : {`BITRANGE(vgactl_dat, 8, 5), 1'b1};
  assign vga_g = ~valid ? '0 : {`BITRANGE(vgactl_dat, 5, 2), 1'b1};
  assign vga_b = ~valid ? '0 : {`BITRANGE(vgactl_dat, 2, 0), 2'b11};

endmodule

module vga_interface(
    input   wire                clk,
    input   wire                rst,
    output  wire    [9:0]       h_addr,
    output  wire    [9:0]       v_addr,
    output  wire                hsync,
    output  wire                vsync,
    output  wire                valid
);

    parameter h_frontporch = `H_FRONTPROCH;
    parameter h_active = `H_ACTIVE;
    parameter h_backporch = `H_BACKPORCH;
    parameter h_total = `H_TOTAL;

    parameter v_frontporch = `V_FRONTPROCH;
    parameter v_active = `V_ACTIVE;
    parameter v_backporch = `V_BACKPORCH;
    parameter v_total = `V_TOTAL;

    reg [9:0] x_cnt, y_cnt;
    wire h_valid, v_valid;

    assign h_valid = (x_cnt > h_active) & (x_cnt <= h_backporch);
    assign v_valid = (y_cnt > v_active) & (y_cnt <= v_backporch);
    assign valid = h_valid & v_valid;

    assign h_addr = h_valid ? (x_cnt - h_active - 10'b1) : {10{1'b0}};
    assign v_addr = v_valid ? (y_cnt - v_active - 10'b1) : {10{1'b0}};

    assign hsync = (x_cnt > h_frontporch);
    assign vsync = (y_cnt > v_frontporch);

    always @(posedge clk, negedge rst) begin
        if(!rst)
            x_cnt <= 1;
        else begin
            if (x_cnt == h_total)
                 x_cnt <= 1;
            else
                x_cnt <= x_cnt + 10'd1;
        end
    end

    always @(posedge clk, negedge rst) begin
        if(!rst)
            y_cnt <= 1;
        else begin
            if (y_cnt == v_total & x_cnt == h_total)
                y_cnt <= 1;
            else if (x_cnt == h_total)
                y_cnt <= y_cnt + 10'd1;
        end
    end

endmodule

`endif