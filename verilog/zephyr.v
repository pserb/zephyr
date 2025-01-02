module zephyr (
    input CLK,
    input RESET
  );

  reg [3:0] PC;  // program counter
  reg [7:0] IR;  // instruction register
  reg [1:0] OP;  // opcode

  // internal state machine with additional states for LOAD
  reg [3:0] zstate;
  localparam FETCH        = 4'b0000;
  localparam DECODE       = 4'b0001;
  localparam EXECUTE      = 4'b0010;
  localparam FETCH_DATA_B = 4'b0011; // New state to fetch DATA_B
  localparam ALU_EXECUTE  = 4'b0100; // New state to execute ALU operation
  localparam ALU_WRITEBACK= 4'b0101; // New state to write back the result
  localparam MEMREAD      = 4'b0110; // Updated state codes
  localparam MEMWRITE     = 4'b0111;
  localparam REGWRITE     = 4'b1000; // Adjusted for new state codes

  // Register
  reg [7:0] ZREG_IN;
  reg ZREG_OP;
  reg [1:0] ZREG_SEL;
  wire [7:0] ZREG_OUT;

  zregister register_file (
    .IN(ZREG_IN),
    .OPCODE(ZREG_OP),
    .REG_SEL(ZREG_SEL),
    .OUT(ZREG_OUT)
  );

  // RAM
  reg [3:0] RAM_ADDR;
  reg RAM_OP;
  reg [7:0] RAM_DATA_IN;
  wire [7:0] RAM_DATA_OUT;

  ram ram_inst (
    .ADDRESS (RAM_ADDR),
    .OPCODE  (RAM_OP),
    .DATA_IN (RAM_DATA_IN),
    .DATA_OUT(RAM_DATA_OUT)
  );

  // ALU
  reg [1:0] ALU_OPCODE;
  reg [7:0] ALU_DATA_A;
  reg [7:0] ALU_DATA_B;
  wire [7:0] ALU_DATA_OUT;
  alu alu_inst (
    .OPCODE(ALU_OPCODE),
    .DATA_A(ALU_DATA_A),
    .DATA_B(ALU_DATA_B),
    .DATA_OUT(ALU_DATA_OUT)
  );

  // control logic (fetch, decode, execute)
  always @(posedge CLK or posedge RESET) begin
    if (RESET) begin
      PC <= 4'b0;
      IR <= 8'b0;
      // Set up initial values for ram
      RAM_OP <= 1'b0;  // read
      RAM_ADDR <= 4'b0;
      RAM_DATA_IN <= 8'b0;

      // Set up initial values for zregister
      ZREG_OP <= 1'b0;  // read
      ZREG_SEL <= 2'b0;
      ZREG_IN <= 8'b0;

      // Set up initial values for ALU
      ALU_OPCODE <= 2'b0;
      ALU_DATA_A <= 8'b0;
      ALU_DATA_B <= 8'b0;

      OP <= 2'b0;  // reset opcode

      zstate <= FETCH;
    end else begin
      case (zstate)
        FETCH: begin
          RAM_OP   <= 1'b0;  // read
          RAM_ADDR <= PC;
          ZREG_OP  <= 1'b0;  // default to read
          zstate   <= DECODE;
        end

        DECODE: begin
          IR <= RAM_DATA_OUT;  // store fetched instruction
          OP <= RAM_DATA_OUT[7:6];  // extract opcode
          zstate <= EXECUTE;
        end

        EXECUTE: begin
          case (OP)
            2'b00: begin  // NOP
              PC <= PC + 1;
              zstate <= FETCH;
            end

            2'b01: begin  // LOAD
              // Set up the memory read
              RAM_ADDR <= IR[3:0];  // Get target address from instruction
              RAM_OP   <= 1'b0;  // Read operation
              ZREG_SEL <= IR[5:4];  // Select target register
              zstate   <= MEMREAD;  // Go to memory read state
            end

            2'b10: begin  // STR
              // Add store logic here
              // bits 5:4 of IR are the register to store
              // bits 3:0 of IR are the ram address to store to
              // example: STR R0 14 == 10001110
              // Store logic
              // bits 5:4 of IR are the register to store
              // bits 3:0 of IR are the RAM address to store to
              RAM_ADDR <= IR[3:0];  // Set RAM address from instruction
              RAM_OP <= 1'b1;  // Write operation
              ZREG_SEL <= IR[5:4];  // Select source register
              ZREG_OP <= 1'b0;  // Read from register
              zstate <= MEMWRITE;  // Go to memory read state
            end

            2'b11: begin  // ALU
              // Add ALU logic here
              // bits 5:4 of IR are the alu operation to perform
              ALU_OPCODE <= IR[5:4];  // Set ALU operation from instruction
              // bits 3:2 of IR are the source register A
              ZREG_SEL <= IR[3:2];  // Select source register A
              ZREG_OP <= 1'b0;  // Read from register

              zstate <= FETCH_DATA_B;  // Go to fetch data B state
            end

            default: begin
              PC <= PC + 1;
              zstate <= FETCH;
            end
          endcase
        end

        FETCH_DATA_B: begin
          ALU_DATA_A <= ZREG_OUT;  // Get data from register A

          ZREG_SEL <= IR[1:0];  // Select source register B
          ZREG_OP <= 1'b0;  // Read from register

          zstate <= ALU_EXECUTE;  // Go to ALU execute state
        end

        ALU_EXECUTE: begin
          ALU_DATA_B <= ZREG_OUT;  // Get data from register B

          zstate <= ALU_WRITEBACK;  // Go to ALU writeback state
        end

        ALU_WRITEBACK: begin
          ZREG_IN <= ALU_DATA_OUT;  // Set ALU result to register
          ZREG_SEL <= IR[3:2];  // write to register A
          ZREG_OP <= 1'b1;  // Prepare for write

          zstate <= REGWRITE;  // Go to register write state
        end

        MEMREAD: begin
          ZREG_IN <= RAM_DATA_OUT;  // Get data from RAM
          ZREG_OP <= 1'b1;  // Prepare for write
          zstate  <= REGWRITE;  // Go to register write state
        end

        MEMWRITE: begin
          // Write data from register to RAM
          RAM_DATA_IN <= ZREG_OUT;  // Set data from register
          // ZREG_OP  <= 1'b0;  // Read from register
          // ZREG_SEL <= IR[5:4];  // Select source register
          PC          <= PC + 1;  // Increment PC
          zstate      <= FETCH;  // Return to fetch state
        end

        REGWRITE: begin
          // Register write is complete
          ZREG_OP <= 1'b0;  // Return to read mode
          PC      <= PC + 1;  // Increment PC
          zstate  <= FETCH;  // Back to fetch
        end

        default: zstate <= FETCH;
      endcase
    end
  end
endmodule
