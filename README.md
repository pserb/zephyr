# zephyr
zephyr is an 8 bit CPU

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
