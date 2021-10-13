TESTBENCH = normalize_tb
SOURCES = ../../rtl/normalize.sv

COMPILE_FLAGS = -g2012
PLUSARGS = -fst

.SILENT:

all: clean run

dump: COMPILE_FLAGS += -DDUMP
dump: clean run

$(TESTBENCH).vvp: $(SOURCES) $(TESTBENCH).sv
	iverilog $(COMPILE_FLAGS) -o $(TESTBENCH).vvp $(SOURCES) $(TESTBENCH).sv

run: $(TESTBENCH).vvp
	vvp $(TESTBENCH).vvp $(PLUSARGS)

clean:
	rm -rf *.vvp
	rm -rf *.fst
	rm -rf *.vcd
