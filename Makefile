# Project-level Makefile
# Usage: make lint | make sim | make clean

lint:
	verilator --lint-only -Wall rtl/cpu/fetch/counter.sv

sim:
	$(MAKE) -C tb/cpu/fetch

clean:
	$(MAKE) -C tb/cpu/fetch clean
	rm -rf tb/cpu/fetch/sim_build
	rm -f tb/cpu/fetch/results.xml