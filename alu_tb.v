module alu_tb;

  // inputs
  reg  [1:0] OPCODE;
  reg  [1:0] REG_A;
  reg  [1:0] REG_B;
  reg  [7:0] DATA_A;
  reg  [7:0] DATA_B;

  // output
  wire [7:0] DATA_OUT;

  alu uut (
      .OPCODE(OPCODE),
      .REG_A(REG_A),
      .REG_B(REG_B),
      .DATA_A(DATA_A),
      .DATA_B(DATA_B),
      .DATA_OUT(DATA_OUT)
  );

  initial begin
    // Test 1: Addition (OPCODE 00)
    OPCODE = 2'b00;  // Addition
    DATA_A = 8'd15;  // 15
    DATA_B = 8'd10;  // 10
    #10;
    $display("Addition: %d + %d = %d", DATA_A, DATA_B, DATA_OUT);  // Expected output: 25

    // Test 2: Subtraction (OPCODE 01)
    OPCODE = 2'b01;  // Subtraction
    DATA_A = 8'd20;  // 20
    DATA_B = 8'd5;  // 5
    #10;
    $display("Subtraction: %d - %d = %d", DATA_A, DATA_B, DATA_OUT);  // Expected output: 15

    // Test 3: Multiplication (OPCODE 10)
    OPCODE = 2'b10;  // Multiplication
    DATA_A = 8'd4;  // 4
    DATA_B = 8'd5;  // 5
    #10;
    $display("Multiplication: %d * %d = %d", DATA_A, DATA_B, DATA_OUT);  // Expected output: 20

    // Test 4: Division (OPCODE 11)
    OPCODE = 2'b11;  // Division
    DATA_A = 8'd20;  // 20
    DATA_B = 8'd4;  // 4
    #10;
    $display("Division: %d / %d = %d", DATA_A, DATA_B, DATA_OUT);  // Expected output: 5

    // Test 5: Division by zero (OPCODE 11)
    OPCODE = 2'b11;  // Division
    DATA_A = 8'd20;  // 20
    DATA_B = 8'd0;  // 0 (test division by zero)
    #10;
    $display("Division by zero: %d / %d = %d", DATA_A, DATA_B,
             DATA_OUT);  // Expected behavior may vary

    // End of test
    $display("Test Complete");
    $finish;
  end

endmodule
