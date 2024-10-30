// this is zephyr's ALU
// it can work with 8 bit numbers (255 in decimal)
// everything is 8 bit, so
// OPCODE is 2 bits

// alu interfaces with registers (4 of them, each 8 bits wide)
// it recieves an instruction that is 6 bits wide
// the first 2 bits are the opcode
// the next 2 bits are the register A
// the last 2 bits are the register B
// the ALU will read the 8 bit numbers stored in the registers
// and perform the operation specified by the opcode
// the result will be stored in the register A

module alu (
    input [1:0] OPCODE,
    input [1:0] REG_A,
    input [1:0] REG_B,
    input [7:0] DATA_A,
    input [7:0] DATA_B,
    output reg [7:0] DATA_OUT
);

  always @(*) begin
    case (OPCODE)
      2'b00:  // Addition
      DATA_OUT = DATA_A + DATA_B;
      2'b01:  // Subtraction
      DATA_OUT = DATA_A - DATA_B;
      2'b10:  // Multiplication
      DATA_OUT = DATA_A * DATA_B;
      2'b11:  // Division
      DATA_OUT = DATA_A / DATA_B;
      default: DATA_OUT = DATA_A + DATA_B;
    endcase
  end


endmodule
