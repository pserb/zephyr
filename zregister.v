// registers that sit inside of the cpu
// there will be 4 of these, each 8 bits wide
// need to be able to select what register to write/read from

module zregister (
    input [7:0] IN,
    input OPCODE,  // reading or writing
    input [1:0] REG_SEL,  // which register to read/write

    output reg [7:0] OUT
);

  // registers 8 bits wide, an array of 4 of them
  reg [7:0] registers[4];

  // reading from the register file
  always @(*) begin
    case (OPCODE)
      0:  // read
      OUT = registers[REG_SEL];
      1:  // write
      registers[REG_SEL] = IN;
      default: OUT = 8'b0;
    endcase
  end

endmodule
