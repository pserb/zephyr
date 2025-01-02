module zregister_tb;

  reg [7:0] IN;
  reg OPCODE;
  reg [1:0] REG_SEL;
  wire [7:0] OUT;

  zregister uut (
      .IN(IN),
      .OPCODE(OPCODE),
      .REG_SEL(REG_SEL),
      .OUT(OUT)
  );

  initial begin
    // Initialize Inputs
    IN = 8'b0;
    OPCODE = 1'b0;  // read
    REG_SEL = 2'b00;  // R0


    // write 10101010 to R0
    IN = 8'b10101010;
    OPCODE = 1'b1;  // write
    REG_SEL = 2'b00;  // R0
    #10;

    // write 11001100 to R1
    IN = 8'b11001100;
    REG_SEL = 2'b01;  // R1
    #10;

    // write 11110000 to R2
    IN = 8'b11110000;
    REG_SEL = 2'b10;  // R2
    #10;

    // write 00001111 to R3
    IN = 8'b00001111;
    REG_SEL = 2'b11;  // R3
    #10;

    // Test reading from each register
    $display("Starting Read Tests");

    OPCODE  = 1'b0;  // read

    // read from R0
    REG_SEL = 2'b00;  // R0
    #10;
    $display("%b", OUT);

    // read from R1
    REG_SEL = 2'b01;  // R1
    #10;
    $display("%b", OUT);

    // read from R2
    REG_SEL = 2'b10;  // R2
    #10;
    $display("%b", OUT);

    // read from R3
    REG_SEL = 2'b11;  // R3
    #10;
    $display("%b", OUT);

    // end of test
    $display("Test Complete");
    $finish;
  end

endmodule
