TESTBENCH = log2_tb
SOURCES = ../../rtl/log2lin.sv \
	  ../../rtl/log2lut.sv \
	  ../../rtl/log2cordic.sv \
	  ../../rtl/normalize.sv

COMPILE_FLAGS = -g2012
PLUSARGS = -fst

.SILENT:

all: clean run

dump: COMPILE_FLAGS += -DDUMP
dump: clean_dump run

plot: COMPILE_FLAGS += -DPLOT
plot: clean_plot run
	gnuplot log2_tb.gp

$(TESTBENCH).vvp: $(SOURCES) $(TESTBENCH).sv
	iverilog $(COMPILE_FLAGS) -o $(TESTBENCH).vvp $(SOURCES) $(TESTBENCH).sv

run: $(TESTBENCH).vvp
	vvp $(TESTBENCH).vvp $(PLUSARGS)

clean_dump:
	rm -rf *.fst

clean_plot:
	rm -rf *.csv
	rm -rf *.png

clean:
	rm -rf *.vvp

clean_all: clean_dump clean_plot clean
