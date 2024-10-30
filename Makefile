OUT_DIR = out
TARGET = $(OUT_DIR)/zephyr
SRC = $(filter-out %_tb.v, $(wildcard *.v)) zephyr_tb.v
VCD_FILE = $(OUT_DIR)/zephyr_tb.vcd

all: compile run

compile: $(TARGET)

$(TARGET): $(SRC)
	mkdir -p $(OUT_DIR)
	iverilog -o $(TARGET) $(SRC)

run: $(TARGET)
	vvp $(TARGET)

wave: $(VCD_FILE)
	gtkwave $(VCD_FILE)

clean:
	rm -rf $(OUT_DIR)

.PHONY: all compile run wave clean
