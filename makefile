MEM_DIR ?= C:/Users/Bardi/Work/Hardware/Shadow/memories/imge/tests
SIMTIME ?= 2500000

$(shell mkdir -p build)

IVERILOG_FLAGS = -Wall -I utils -I testbench -I core -I perf -I . -g2012 -DSIMTIME=$(SIMTIME) -D_MEMDIR \
  -D_DATA0=\`\"$(MEM_DIR)/data-0.txt\`\" \
	-D_DATA1=\`\"$(MEM_DIR)/data-1.txt\`\" \
	-D_DATA2=\`\"$(MEM_DIR)/data-2.txt\`\" \
	-D_DATA3=\`\"$(MEM_DIR)/data-3.txt\`\"

pre-compile:
	@iverilog -E $(IVERILOG_FLAGS) -D_SIMULATE -o build/unisys_pre.sv unisys.sv
compile:
	@iverilog $(IVERILOG_FLAGS) -D_IMPLEMENT -o build/unisys_pre.vexe unisys.sv

TARGET ?= unisys

sim-compile:
	@iverilog $(IVERILOG_FLAGS) -D_IMPLEMENT -DTARGET=$(TARGET) -o build/unisys_sim.vexe builtin_tb.sv

sim: sim-compile
	@vvp build/unisys_sim.vexe > build/result.txt

run: sim
	@gtkwave build/wave.vcd

count:
	@echo lines: `find . | grep .sv | xargs cat | grep -v // | grep -v ^$$ | wc -l`