# zephyr
zephyr is an 8 bit CPU

### building
create a program
```
cd zephyr
vim asm/file.asm
```
assemble it
```
make assemble FILE=file.asm
```
copy outputted Verilog into `testbench/zephyr_tb.v` ~line 44 \
compile and run the testbench
```
make
```

### supported instructions
- LOAD
- STR

### example usage
`LOAD R0, [15]`
"load into register R0 the value at memory location 15 (0xF)"
in binary, this instruction is `01 00 1111`
- `LOAD = 01`
- `RO = 00`
- `[15] = 1111`
