module zephyr (
    input CLK,
    input RESET
);

  reg [3:0] PC;  // program counter
  reg [7:0] IR;  // instruction register
  reg [1:0] OP;  // opcode

  // internal state machine with additional states for LOAD
  reg [2:0] zstate;
  localparam logic [2:0] FETCH = 3'b000;
  localparam logic [2:0] DECODE = 3'b001;
  localparam logic [2:0] EXECUTE = 3'b010;
  localparam logic [2:0] MEMREAD = 3'b011;  // New state for memory read
  localparam logic [2:0] REGWRITE = 3'b100;  // New state for register write

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
  wire [7:0] RAM_DATA_OUT;

  ram ram_inst (
      .ADDRESS (RAM_ADDR),
      .OPCODE  (RAM_OP),
      .DATA_OUT(RAM_DATA_OUT)
  );

  // ALU
  //   alu alu_inst ();

  // control logic (fetch, decode, execute)
  always @(posedge CLK or posedge RESET) begin
    if (RESET) begin
      PC <= 4'b0;
      IR <= 8'b0;
      RAM_OP <= 1'b0;  // read
      RAM_ADDR <= 4'b0;
      ZREG_OP <= 1'b0;  // read
      ZREG_SEL <= 2'b0;
      ZREG_IN <= 8'b0;
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
              zstate   <= MEM_READ;  // Go to memory read state
            end

            2'b10: begin  // STR
              // Add store logic here
              PC <= PC + 1;
              zstate <= FETCH;
            end

            2'b11: begin  // ALU
              // Add ALU logic here
              PC <= PC + 1;
              zstate <= FETCH;
            end

            default: begin
              PC <= PC + 1;
              zstate <= FETCH;
            end
          endcase
        end

        MEMREAD: begin
          // Data from RAM is now ready
          ZREG_IN <= RAM_DATA_OUT;  // Get data from RAM
          ZREG_OP <= 1'b1;  // Prepare for write
          zstate  <= REG_WRITE;  // Go to register write state
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
