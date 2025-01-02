#!/usr/bin/env python3

import sys
import re

# Define opcode and register mappings
OPCODES = {"LOAD": "01", "STR": "10", "ADD": "1100"}

REGISTERS = {
    "R0": "00",
    "R1": "01",
    "R2": "10",
    "R3": "11",
}

# Enhanced regular expressions for parsing
ORG_REGEX = re.compile(r"^\.ORG\s+(\d+)$", re.IGNORECASE)
DATA_REGEX = re.compile(r"^DATA\s+([A-Za-z]\w*),\s*0x([0-9A-Fa-f]{2})$", re.IGNORECASE)
# Regex for LOAD and STR instructions
INSTR_LOAD_STR_REGEX = re.compile(
    r"^(LOAD|STR)\s+R(\d+),\s*\[([A-Za-z]\w*|\d+)\]$", re.IGNORECASE
)
# Regex for ADD instructions
INSTR_ADD_REGEX = re.compile(r"^ADD\s+R(\d+),\s*R(\d+)$", re.IGNORECASE)


class ZASMAssembler:
    def __init__(self):
        self.memory = {}
        self.variables = {}  # Maps variable names to their addresses
        self.current_address = 0

    def first_pass(self, lines):
        """First pass: collect variable definitions and their addresses"""
        for line_num, line in enumerate(lines, start=1):
            line = line.strip()
            # print("line", line)
            if not line or line.startswith(";"):
                continue

            # Handle .ORG directive
            org_match = ORG_REGEX.match(line)
            if org_match:
                self.current_address = int(org_match.group(1), 10)
                if self.current_address < 0 or self.current_address > 15:
                    raise ValueError(
                        f"Invalid .ORG address on line {line_num}: {self.current_address}"
                    )
                continue

            # Handle DATA directive with variables
            data_match = DATA_REGEX.match(line)
            if data_match:
                var_name, data_value = data_match.groups()
                if var_name in self.variables:
                    raise ValueError(
                        f"Duplicate variable definition '{var_name}' on line {line_num}"
                    )

                self.variables[var_name] = self.current_address
                self.memory[self.current_address] = data_value.upper()
                self.current_address += 1
                if self.current_address > 16:
                    raise ValueError(
                        f"Memory address out of range after line {line_num}"
                    )
                continue

            # Handle LOAD and STR instructions
            instr_load_str_match = INSTR_LOAD_STR_REGEX.match(line)
            if instr_load_str_match:
                self.current_address += 1
                continue

            # Handle ADD instructions
            instr_add_match = INSTR_ADD_REGEX.match(line)
            # print("instr_add_match", instr_add_match)
            if instr_add_match:
                self.current_address += 1
                continue

            if not any([org_match, data_match, instr_load_str_match, instr_add_match]):
                raise ValueError(f"Unrecognized line {line_num}: {line}")

    def second_pass(self, lines):
        """Second pass: resolve variable references and generate machine code"""
        self.current_address = 0
        self.memory = {}  # Reset memory for second pass

        for line_num, line in enumerate(lines, start=1):
            line = line.strip()
            if not line or line.startswith(";"):
                continue

            # Handle .ORG directive
            org_match = ORG_REGEX.match(line)
            if org_match:
                self.current_address = int(org_match.group(1), 10)
                continue

            # Handle DATA directive
            data_match = DATA_REGEX.match(line)
            if data_match:
                var_name, data_value = data_match.groups()
                self.memory[self.current_address] = data_value.upper()
                self.current_address += 1
                continue

            # Handle LOAD and STR instructions
            instr_load_str_match = INSTR_LOAD_STR_REGEX.match(line)
            if instr_load_str_match:
                instr, reg_num, addr = instr_load_str_match.groups()
                instr = instr.upper()
                reg = f"R{reg_num}"

                # Get opcode and register code
                opcode = OPCODES.get(instr)
                reg_code = REGISTERS.get(reg)

                if not opcode:
                    raise ValueError(
                        f"Unknown instruction '{instr}' on line {line_num}"
                    )
                if not reg_code:
                    raise ValueError(f"Unknown register '{reg}' on line {line_num}")

                # Resolve variable reference or direct address
                try:
                    if addr.isdigit():
                        mem_addr = int(addr, 10)
                    else:
                        if addr not in self.variables:
                            raise ValueError(
                                f"Undefined variable '{addr}' on line {line_num}"
                            )
                        mem_addr = self.variables[addr]
                except ValueError:
                    raise ValueError(
                        f"Invalid address or variable '{addr}' on line {line_num}"
                    )

                if mem_addr < 0 or mem_addr > 15:
                    raise ValueError(
                        f"Invalid memory address '{mem_addr}' on line {line_num}"
                    )

                # Construct the 8-bit machine code
                machine_code_bin = opcode + reg_code + f"{mem_addr:04b}"
                machine_code_hex = f"{int(machine_code_bin, 2):02X}"
                self.memory[self.current_address] = machine_code_hex
                self.current_address += 1
                continue

            # Handle ADD instructions
            instr_add_match = INSTR_ADD_REGEX.match(line)
            if instr_add_match:
                dest_reg_num, src_reg_num = instr_add_match.groups()
                dest_reg = f"R{dest_reg_num}"
                src_reg = f"R{src_reg_num}"

                # Get opcode and register codes
                opcode = OPCODES.get("ADD")
                dest_reg_code = REGISTERS.get(dest_reg)
                src_reg_code = REGISTERS.get(src_reg)

                if not opcode:
                    raise ValueError(f"Unknown instruction 'ADD' on line {line_num}")
                if not dest_reg_code or not src_reg_code:
                    raise ValueError(
                        f"Unknown register in ADD instruction on line {line_num}"
                    )

                # Construct the 8-bit machine code: opcode (4 bits) + dest reg (2 bits) + src reg (2 bits)
                machine_code_bin = opcode + dest_reg_code + src_reg_code
                machine_code_hex = f"{int(machine_code_bin, 2):02X}"
                self.memory[self.current_address] = machine_code_hex
                self.current_address += 1
                continue

    def generate_mif(self, depth=16, width=8):
        """Generate MIF file content from assembled memory"""
        mif = []
        mif.append(f"WIDTH={width};")
        mif.append(f"DEPTH={depth};\n")
        mif.append("ADDRESS_RADIX=HEX;")
        mif.append("DATA_RADIX=HEX;\n")
        mif.append("CONTENT BEGIN")

        # Initialize all addresses with '00'
        content = {addr: "00" for addr in range(depth)}
        content.update(self.memory)

        # Sort addresses and prepare MIF content
        sorted_addresses = sorted(content.keys())
        address_ranges = []
        if sorted_addresses:  # Check if there are any addresses
            start = prev = sorted_addresses[0]
            current_data = content[start]

            for addr in sorted_addresses[1:]:
                data = content[addr]
                if data == current_data and addr == prev + 1:
                    prev = addr
                else:
                    address_ranges.append((start, prev, current_data))
                    start = prev = addr
                    current_data = data
            # Append the last range
            address_ranges.append((start, prev, current_data))

        # Format the MIF content
        for start, end, data in address_ranges:
            if start == end:
                mif.append(f"    {start:X}: {data};")
            else:
                mif.append(f"    [{start:X}..{end:X}]: {data};")

        mif.append("END;")
        return "\n".join(mif)


def main():
    if len(sys.argv) != 3:
        print("Usage: python zasm_to_mif.py <input.asm> <output.mif>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    try:
        with open(input_file, "r") as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: File '{input_file}' not found.")
        sys.exit(1)

    try:
        assembler = ZASMAssembler()
        assembler.first_pass(lines)
        assembler.second_pass(lines)
        mif_content = assembler.generate_mif()
    except ValueError as e:
        print(f"Error parsing assembly: {e}")
        sys.exit(1)

    try:
        with open(output_file, "w") as f:
            f.write(mif_content)
    except IOError as e:
        print(f"Error writing MIF file: {e}")
        sys.exit(1)

    print(f"MIF file '{output_file}' generated successfully.")


if __name__ == "__main__":
    main()
