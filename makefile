MEM_DIR ?= C:/Users/Bardi/Work/Hardware/Shadow/memories/imge/tests
IVERILOG_FLAGS = -Wall -I core -I perf -I . -g2012 -D_MEMDIR \
  -D_DATA0=\`\"$(MEM_DIR)/data-0.txt\`\" \
	-D_DATA1=\`\"$(MEM_DIR)/data-1.txt\`\" \
	-D_DATA2=\`\"$(MEM_DIR)/data-2.txt\`\" \
	-D_DATA3=\`\"$(MEM_DIR)/data-3.txt\`\"

pre-compile:
	@iverilog -E $(IVERILOG_FLAGS) -o build/unisys_pre.sv unisys.sv
compile:
	@iverilog -Wall -I core -I perf -I . -o build/unisys_pre.vexe -g2012 unisys.sv

sim-compile:
	@iverilog -Wall -I core -I perf -I . -o build/unisys_sim.vexe -g2012 builtin_tb.sv

sim: sim-compile
	@vvp build/unisys_sim.vexe > build/result.txt

run: sim
	@gtkwave build/wave.vcd

count:
	@echo lines: `find . | grep .sv | xargs cat | grep -v // | grep -v ^$$ | wc -l`