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
  output  wire  `WIDE(`XLEN)    pc_debug,
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
  reg pcg_isjalr, pcg_branch, pc_reg_en; 
  wire `WIDE(`XLEN) pcg_offset, pcg_jalr_reg, pc_out, pc_now;
  assign pc_debug = pc_now;

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

  assign pcg_jalr_reg = radata;
  assign pcg_offset = imm;

  //EX
  reg `WIDE(`XLEN) dataa, datab;
  wire less, zero;
  wire `WIDE(`XLEN) aluresult;
  alu alu_0(.*);

  wire `WIDE(`XLEN) mem_dat_o_w;
  save_sext save_sext_0(
    .current(rbdata),
    .mem_mode(mem_opt),
    .low_addr(`BITRANGE(aluresult, 2, 0)),
    .target(mem_dat_o_w)
  );

  //M
  wire `WIDE(`XLEN) mem_dat_i_w;
  load_sext load_sext_0(
    .current(mem_dat_i),
    .mem_mode(mem_opt),
    .low_addr(`BITRANGE(aluresult, 2, 0)),
    .mem_signed(mem_signed),
    .target(mem_dat_i_w)
  );

  `ALWAYS_CR begin
    if (~rst) begin
      current_state <= INITIAL;
      mem_wen       <= '0;
      mem_mode      <= '0;
      mem_addr      <= '0;
      mem_dat_o     <= '0;
      inst          <= '0;
      dataa         <= '0;
      datab         <= '0;
      pc_reg_en     <= '0;
      pcg_isjalr    <= '0;
      pcg_branch    <= '0;
      reg_wen       <= '0;
      rwdata        <= '0;
    end
    else begin
      case (current_state)
        INITIAL: begin
          current_state <=    INST_DECODE;
          mem_wen       <=    1'b0;
          reg_wen       <=    1'b0;
          mem_mode      <=    3'b111;
          mem_addr      <=    32'h80000000;
          mem_dat_o     <=    '0;
        end
        INST_FETCH: begin
          current_state <=    INST_DECODE;
          mem_wen       <=    1'b0;
          reg_wen       <=    1'b0;
          mem_mode      <=    3'b111;
          mem_addr      <=    pc_now;
        end
        INST_DECODE: begin
          current_state <=    EXECUTE;
          inst          <=    mem_dat_i;
        end
        EXECUTE: begin
          current_state <= MEMORY;
          case (alu_sela)
            `ALU_A_PC:    dataa <= pc_now;
            `ALU_A_ZERO:  dataa <= '0;
            `ALU_A_REG:   dataa <= radata;
            default:      dataa <= '0;
          endcase
          case (alu_selb)
            `ALU_B_FOUR:  datab <= 32'h4;
            `ALU_B_IMM:   datab <= imm;
            `ALU_B_REG:   datab <= rbdata;
            default:      datab <= '0;
          endcase
        end
        MEMORY: begin
          current_state <=    WRITE_BACK;
          mem_dat_o     <=    mem_dat_o_w;
          mem_addr      <=    aluresult;
          mem_mode      <=    mem_opt;
          mem_wen       <=    mem_wr;
          //pc options
          pc_reg_en <= 1'b1;
          if (branch == `BRANCH_JALR)
            pcg_isjalr <= 1'b1;
          else pcg_isjalr <= 1'b0;
          case (branch)
            `BRANCH_JAL, `BRANCH_JALR:
              pcg_branch <= 1'b1;
            `BRANCH_BEQ:
              pcg_branch <= zero;
            `BRANCH_BNE:
              pcg_branch <= ~zero;
            `BRANCH_BLT:
              pcg_branch <= less;
            `BRANCH_BGE:
              pcg_branch <= ~less;
            default: pcg_branch <= 1'b0;
          endcase
        end
        WRITE_BACK: begin
          current_state <= INST_FETCH;
          mem_wen <= 1'b0;
          pc_reg_en <= 1'b0;
          if (mem_load) begin
            //todo mem_signed
            reg_wen <= 1'b1;
            rwdata <= mem_dat_i_w;
          end
          else if(reg_wr) begin
            reg_wen <= 1'b1;
            rwdata  <= aluresult;
          end
        end
      endcase
    end
  end

endmodule

`endif