import re
import sys


def parse_mif_file(filename):
    try:
        with open(filename, "r") as file:
            content = file.read()
    except FileNotFoundError:
        print(f"Error: The file '{filename}' was not found.")
        sys.exit(1)
    except IOError:
        print(f"Error: Unable to read the file '{filename}'.")
        sys.exit(1)

    # Extract width and depth
    width_match = re.search(r"WIDTH=(\d+);", content)
    depth_match = re.search(r"DEPTH=(\d+);", content)

    if not width_match or not depth_match:
        print("Error: WIDTH or DEPTH not found in the MIF file.")
        sys.exit(1)

    width = int(width_match.group(1))
    depth = int(depth_match.group(1))

    # Extract content
    content_match = re.search(r"CONTENT BEGIN(.*?)END;", content, re.DOTALL)
    if not content_match:
        print("Error: Could not find CONTENT section in MIF file.")
        sys.exit(1)

    content_lines = content_match.group(1).strip().split("\n")

    # Parse content
    memory = {}
    for line in content_lines:
        line = line.split("--")[0].strip()  # Remove comments
        if ":" in line:
            address, value = line.split(":")
            address = address.strip()
            value = value.strip("; ")

            if ".." in address:
                start, end = re.findall(r"[0-9A-Fa-f]+", address)
                start, end = int(start, 16), int(end, 16)
                for addr in range(start, end + 1):
                    memory[addr] = value
            else:
                memory[int(address, 16)] = value

    return width, depth, memory


def generate_verilog_code(memory):
    verilog_code = []
    for address, value in memory.items():
        verilog_code.append(f"cpu.ram_inst.registers[{address}] = 8'h{value};")
    return "\n".join(verilog_code)


# Main code
if len(sys.argv) < 2:
    print("Usage: python script_name.py <mif_filename>")
    print(
        "Error: No MIF file specified. Please provide a .mif file as a command-line argument."
    )
    sys.exit(1)

mif_filename = sys.argv[1]
width, depth, memory = parse_mif_file(mif_filename)
verilog_code = generate_verilog_code(memory)

print(verilog_code)
