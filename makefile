pre-compile:
	@iverilog -Wall -E -I core -I perf -I . -o build/unisys_pre.sv -g2012 unisys.sv
compile:
	@iverilog -Wall -I core -I perf -I . -o build/unisys_pre.vexe -g2012 unisys.sv
count:
	@echo lines: `find . | grep .sv | xargs cat | grep -v // | grep -v ^$$ | wc -l`