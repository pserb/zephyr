// RAM with 16 8-bit registers
// can be read from or written to
// takes input address and data
// outputs data

module ram (
    input [3:0] ADDRESS,
    input [7:0] DATA_IN,
    input OPCODE,  // reading or writing

    output reg [7:0] DATA_OUT
);

  reg [7:0] registers[15:0];

  always @(*) begin
    case (OPCODE)
      1'b0:  // read
      DATA_OUT = registers[ADDRESS];
      1'b1:  // write
      registers[ADDRESS] = DATA_IN;
      default: DATA_OUT = 8'b0;
    endcase
  end

endmodule
