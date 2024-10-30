module zephyr_tb;

  // Signals for the CPU
  reg clk;
  reg reset;

  // For state display
  reg [8*6:1] state_string;

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
      2'b00:   state_string = "FETCH ";
      2'b01:   state_string = "DECODE";
      2'b10:   state_string = "EXECUT";
      default: state_string = "UNKNWN";
    endcase
  end

  // Test Procedure
  initial begin
    $dumpfile("zephyr_tb.vcd");
    $dumpvars(0, zephyr_tb);

    // Initialize memory with test program
    // cpu.ram_inst.registers[0] = 'hAA;  // NOP
    // cpu.ram_inst.registers[1] = 'hBB;  // NOP
    // cpu.ram_inst.registers[2] = 'hCC;  // NOP
    // cpu.ram_inst.registers[3] = 'hDD;  // NOP
    // cpu.ram_inst.registers[4] = 'hEE;  // NOP
    // cpu.ram_inst.registers[5] = 'hFF;  // NOP

    cpu.ram_inst.registers[0]  = 8'h00;  // NOP
    cpu.ram_inst.registers[1]  = 8'b01001111;  // LOAD R0 15
    cpu.ram_inst.registers[2]  = 8'b00110011;  // NOP
    cpu.ram_inst.registers[3]  = 8'b00111111;  // NOP
    cpu.ram_inst.registers[15] = 8'hFF;  // NOP

    // Print header for monitoring
    $display("Time\tState\tPC\tIR\tRAM_ADDR");
    $display("----\t-----\t--\t--\t--------");

    // Initialize testbench
    reset = 1;
    @(posedge clk);
    reset = 0;

    // Monitor for 18 clock cycles (enough for 6 instructions)
    repeat (10 * 5) begin
      @(posedge clk);
      //#1;  // Small delay to let signals settle
      $display("%0t\t%s\t%h\t%h\t%h", $time, state_string, cpu.PC, cpu.IR, cpu.RAM_ADDR);
    end

    // End of test
    $display("\nTest Complete");
    $finish;
  end

  // Additional monitoring for debug
  //   initial begin
  //     $monitor("Time=%0t reset=%b state=%s pc=%h ir=%h ram_addr=%h", $time, reset, state_string,
  //              cpu.PC, DBG_IR, cpu.RAM_ADDR);
  //   end

endmodule
