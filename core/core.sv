`ifndef _CORE
`define _CORE
`include "common.sv"
`include "alu.sv"
`include "decode.sv"
`include "pc_reg.sv"
`include "gprfile.sv"

module core(
  input   wire                  clk,
  input   wire                  rst,
  input   wire                  intr,
  output  reg                   mem_wen,
  output  reg   `WIDE(3)        mem_mode,
  output  reg   `WIDE(`XLEN)    mem_addr,  
  input   wire  `WIDE(`XLEN)    mem_dat_i,
  output  reg   `WIDE(`XLEN)    mem_dat_o,
  input   wire                  mem_ready
);

  typedef enum bit `WIDE(5) {
    INST_FETCH    =   5'b00001,
    INST_DECODE   =   5'b00010,
    EXECUTE       =   5'b00100,
    MEMORY        =   5'b01000,
    WRITE_BACK    =   5'b10000,
    INITIAL       =   5'b00000
  } cpu_state;

  cpu_state current_state;

  //IF
  wire pcg_isjalr, pcg_branch; 
  wire `WIDE(`XLEN) pcg_offset, pcg_jalr_reg, pc_out, pc_now;

  pc_reg pc_reg_0(.*);

  //ID
  reg `WIDE(`XLEN) inst;
  wire `WIDE(`XLEN) imm;
  wire `WIDE(5) reg_anum, reg_bnum, reg_wnum;
  wire `WIDE(3) ALUctr, mem_opt, branch;
  wire `WIDE(2) alu_sela, alu_selb;
  wire ALUext, mem_wr, reg_wr, mem_load, mem_signed;
  decode decode_0(.*);

  wire `WIDE(`XLEN) radata, rbdata;
  reg `WIDE(`XLEN) rwdata;
  reg reg_wen;
  gprfile gprfile_0(.*);

  //EX
  reg `WIDE(`XLEN) dataa, datab;
  wire less, zero;
  wire `WIDE(`XLEN) aluresult;
  alu alu_0(.*);

  `ALWAYS_CR begin
    if (~rst) begin
      current_state <= INITIAL;
    end
    else begin
      case (current_state)
        INITIAL: begin
          current_state <=    INST_DECODE;
          mem_wen       <=    1'b0;
          mem_mode      <=    3'b111;
          mem_addr      <=    '0;
          mem_dat_o     <=    '0;
        end
        INST_FETCH: begin
          current_state <=    INST_DECODE;
          mem_wen       <=    1'b0;
          mem_mode      <=    3'b111;
          mem_addr      <=    pc_out;
        end
        INST_DECODE: begin
          current_state <=    EXECUTE;
          inst          <=    mem_dat_i;
        end
        EXECUTE: begin
          case (alu_sela)
            `ALU_A_PC:    dataa <= pc_now;
            `ALU_A_ZERO:  dataa <= '0;
            `ALU_A_REG:   dataa <= radata;
          endcase
          case (alu_selb)
            `ALU_B_FOUR:  datab <= 32'h4;
            `ALU_B_IMM:   datab <= imm;
            `ALU_B_REG:   datab <= rbdata;
          endcase
          current_state <=    MEMORY;
        end
        MEMORY: begin
          mem_dat_o     <=    rbdata;
          mem_addr      <=    aluresult;
          mem_mode      <=    mem_opt;
          mem_wen       <=    mem_wr;
          current_state <=    WRITE_BACK;
        end
        WRITE_BACK: begin
          if (mem_load) begin
            //todo mem_signed
            reg_wen   <=    1'b1;
            rwdata    <=    mem_dat_i;
          end
          else if(reg_wr) begin
            reg_wen   <=    1'b1;
            rwdata    <=    aluresult;
          end
          //todo pc
          current_state <=    INST_FETCH;
        end
      endcase
    end
  end

endmodule

`endif