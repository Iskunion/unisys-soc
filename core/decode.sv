`ifndef _DECODE
`define _DECODE

`include "common.sv"
`include "coredefs.sv"

//decode module
module decode(
  input  wire `WIDE(`XLEN) inst,
  output reg  `WIDE(`XLEN) imm,
  output wire `WIDE(5)     reg_anum,
  output wire `WIDE(5)     reg_bnum,
  output wire `WIDE(5)     reg_wnum,
  output reg  `WIDE(3)     ALUctr,
  output reg               ALUext,
  output reg  `WIDE(2)     alu_sela,
  output reg  `WIDE(2)     alu_selb,
  output reg               mem_wr,
  output reg               reg_wr,
  output wire              mem_load,
  output reg  `WIDE(3)     mem_opt,
  output reg               mem_signed,
  output reg  `WIDE(3)     branch
);

  wire `WIDE(7) op = inst[6:0];

  //imm
  always @(*) begin
    case (op)
      `INST_TYPE_I, `INST_TYPE_L:
        imm = {{21{inst[31]}}, inst[30:20]};
      `INST_LUI, `INST_AUIPC:
        imm = {inst[31:12], 12'h0};
      `INST_JAL, `INST_JALR:
        imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
      `INST_TYPE_R_M:
        imm = '0;
      `INST_TYPE_B:
        imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
      `INST_TYPE_S:
        imm = {{21{inst[31]}}, inst[30:25], inst[11:7]};
      default:
        imm = '0;
    endcase
  end

  //ra, rb, rd
  assign reg_anum = inst[19:15];
  assign reg_bnum = inst[24:20];
  assign reg_wnum = inst[11:7];

  //alu
  always @(*) begin
    case (op)
      `INST_TYPE_R_M, `INST_TYPE_I: begin
        ALUctr = inst[14:12];
        ALUext = inst[30];
      end
      `INST_TYPE_B: begin
        ALUctr = (inst[14:13] == 2'b11) ? `ALU_SLTU : `ALU_SLT;
        ALUext = '0;
      end
      default: begin
        ALUctr = `ALU_ADD;
        ALUext = '0;
      end
    endcase
  end

  //aluasel
  always @(*) begin
    case (op)
      `INST_AUIPC, `INST_JAL, `INST_JALR:
        alu_sela = `ALU_A_PC;
      `INST_LUI:
        alu_sela = `ALU_A_ZERO;
      default:
        alu_sela = `ALU_A_REG;
    endcase
  end
  
  //alubsel
  always @(*) begin
    case (op)
      `INST_JAL, `INST_JALR:
        alu_selb = `ALU_B_FOUR;
      `INST_TYPE_S, `INST_TYPE_L, `INST_TYPE_I:
        alu_selb = `ALU_B_IMM;
      default:
        alu_selb = `ALU_B_REG;
    endcase
  end

  //mem_load
  assign mem_load = (op == `INST_TYPE_L) ? 1'b1 : 1'b0;

  //mem_wr
  assign mem_wr  = (op == `INST_TYPE_S) ? 1'b1 : 1'b0;

  //reg_wr
  always @(*) begin
    case (op)
      `INST_TYPE_L, `INST_TYPE_R_M, `INST_TYPE_I, `INST_JAL, `INST_JALR:
        reg_wr = 1'b1;
      default:
        reg_wr = 1'b0;
    endcase
  end

  //mem_signed
  always @(*) begin
    if (op == `INST_TYPE_L && inst[14:13] == 2'b00)
      mem_signed = 1'b1;
    else mem_signed = 1'b0;
  end

  //mem_opt
  always @(*) begin
    if (op == `INST_TYPE_S || op == `INST_TYPE_L) begin
      case (inst[13:12])
        `MEM_BYTE: mem_opt = 3'b001;
        `MEM_HALF: mem_opt = 3'b011;
        `MEM_WORD: mem_opt = 3'b111;
        default:   mem_opt = '0;
      endcase
    end
  end

  //branch
  always @(*) begin
    case (op)
      `INST_JAL:
        branch = `BRANCH_JAL;
      `INST_JALR:
        branch = `BRANCH_JALR;
      `INST_TYPE_B: begin
        case (inst[14:12])
          `INST_BEQ:
            branch = `BRANCH_BEQ;
          `INST_BNE:
            branch = `BRANCH_BNE;
          `INST_BLT, `INST_BLTU:
            branch = `BRANCH_BLT;
          `INST_BGE, `INST_BGEU:
            branch = `BRANCH_BGE;
        endcase
      end
    endcase
  end

endmodule

`endif