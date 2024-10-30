module zephyr_tb;

  // Signals for the CPU
  reg clk;
  reg reset;

  // For state display
  parameter integer NCharsInStateString = 8;
  reg [8*NCharsInStateString:1] state_string;

  // Instantiate the zephyr CPU
  zephyr cpu (
      .CLK  (clk),
      .RESET(reset)
  );

  // Clock Generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 10ns period clock
  end

  // Convert state to string for display
  always @(*) begin
    case (cpu.zstate)
      2'b00:   state_string = "FETCH   ";
      2'b01:   state_string = "DECODE  ";
      2'b10:   state_string = "EXECUTE ";
      3'b011:  state_string = "MEMREAD ";
      3'b100:  state_string = "MEMWRITE";
      3'b101:  state_string = "REGWRITE";
      default: state_string = "UNKNOWN ";
    endcase
  end

  // Test Procedure
  initial begin
    $dumpfile("out/zephyr_tb.vcd");
    $dumpvars(0, zephyr_tb);

    // cpu.ram_inst.registers[0] = 8'h00;  // NOP
    cpu.ram_inst.registers[0]  = 8'b01001111;  // LOAD R0 15 (#FF)
    cpu.ram_inst.registers[1]  = 8'b10001101;  // STR R0 13
    cpu.ram_inst.registers[2]  = 8'b01011110;  // LOAD R1 14 (#FA)
    cpu.ram_inst.registers[3]  = 8'b10011100;  // STR R1 12

    cpu.ram_inst.registers[14] = 8'hFA;  // variable (NOP)
    cpu.ram_inst.registers[15] = 8'hFF;  // variable (NOP)

    $display("\n---------------------------------------------------");
    $display("Starting Program Memory:");
    for (integer i = 0; i < 16; i = i + 4) begin
      // Display RAM contents
      $display("RAM [%02d-%02d]: %h  %h  %h  %h", i, i + 3, cpu.ram_inst.registers[i],
               cpu.ram_inst.registers[i+1], cpu.ram_inst.registers[i+2],
               cpu.ram_inst.registers[i+3]);
    end
    $display("---------------------------------------------------");

    // Initialize testbench
    reset = 1;
    @(posedge clk);
    reset = 0;

    // Monitor for 18 clock cycles (enough for 6 instructions)
    repeat (4 * 5) begin
      @(posedge clk);

      // Display cycle information
      $display("Cycle: %0t | State: %s | PC: %h | IR: %b | RAM_ADDR: %h", $time, state_string,
               cpu.PC, cpu.IR, cpu.RAM_ADDR);

      // Display ZRegister contents
      $display("ZREG[00-03]: %h  %h  %h  %h", cpu.register_file.registers[0],
               cpu.register_file.registers[1], cpu.register_file.registers[2],
               cpu.register_file.registers[3]);

      // Display RAM contents in multiple columns
      // $display("RAM Contents:");
      for (integer i = 0; i < 16; i = i + 4) begin
        // Display RAM contents
        $display("RAM [%02d-%02d]: %h  %h  %h  %h", i, i + 3, cpu.ram_inst.registers[i],
                 cpu.ram_inst.registers[i+1], cpu.ram_inst.registers[i+2],
                 cpu.ram_inst.registers[i+3]);

        // Display Marker Line
        $display("             %s  %s  %s  %s", (i == cpu.PC) ? "^^" : "",
                 (i + 1 == cpu.PC) ? "^^" : "", (i + 2 == cpu.PC) ? "^^" : "",
                 (i + 3 == cpu.PC) ? "^^" : "");
      end

      $display("---------------------------------------------------");
    end

    // End of test
    $display("\nTest Complete");
    $finish;
  end

endmodule
