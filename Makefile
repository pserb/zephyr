OUT_DIR = out
TARGET = $(OUT_DIR)/zephyr
SRC = $(filter-out testbench/*_tb.v, $(wildcard verilog/*.v)) testbench/zephyr_tb.v
VCD_FILE = $(OUT_DIR)/zephyr_tb.vcd

ASM_DIR = asm
MIF_DIR = mif
PYTHON_DIR = python

all: compile run

compile: $(TARGET)

$(TARGET): $(SRC)
	mkdir -p $(OUT_DIR)
	iverilog -o $(TARGET) $(SRC)

run: $(TARGET)
	vvp $(TARGET)

wave: $(VCD_FILE)
	gtkwave $(VCD_FILE)

assemble:
	@if [ -z "$(FILE)" ]; then \
		echo "Error: FILE argument is required. Usage: make assemble FILE=file.asm"; \
		exit 1; \
	fi
	@if [ ! -f $(ASM_DIR)/$(FILE) ]; then \
		echo "Error: $(ASM_DIR)/$(FILE) not found."; \
		exit 1; \
	fi
	python3 $(PYTHON_DIR)/assembler.py $(ASM_DIR)/$(FILE) $(MIF_DIR)/$(FILE:.asm=.mif)
	python3 $(PYTHON_DIR)/transpiler.py $(MIF_DIR)/$(FILE:.asm=.mif)

clean:
	rm -rf $(OUT_DIR)

.PHONY: all compile run wave assemble clean
