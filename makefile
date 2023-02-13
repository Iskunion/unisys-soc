pre-compile:
	@iverilog -Wall -E -I core -I perf -I . -o build/unisys_pre.sv -g2012 unisys.sv
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