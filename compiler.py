#!/usr/bin/env python3

import sys
import os
import subprocess
import argparse
from typing import Tuple, Optional


def validate_file_extension(filename: str, expected_ext: str) -> bool:
    """Validate that a filename has the expected extension."""
    _, ext = os.path.splitext(filename)
    return ext.lower() == expected_ext.lower()


def ensure_file_exists(filename: str) -> None:
    """Check if a file exists and is readable."""
    if not os.path.exists(filename):
        raise FileNotFoundError(f"File '{filename}' does not exist")
    if not os.path.isfile(filename):
        raise ValueError(f"'{filename}' is not a regular file")
    if not os.access(filename, os.R_OK):
        raise PermissionError(f"No read permission for '{filename}'")


def run_assembler(input_asm: str, output_mif: str) -> Tuple[bool, Optional[str]]:
    """Run the assembler script and return success status and error message if any."""
    try:
        result = subprocess.run(
            [sys.executable, "assembler.py", input_asm, output_mif],
            capture_output=True,
            text=True,
            check=True,
        )
        return True, None
    except subprocess.CalledProcessError as e:
        return False, f"Assembler error: {e.stderr.strip()}"
    except subprocess.SubprocessError as e:
        return False, f"Failed to run assembler: {str(e)}"


def run_transpiler(input_mif: str) -> Tuple[bool, Optional[str], Optional[str]]:
    """Run the transpiler script and return success status, output, and error message if any."""
    try:
        result = subprocess.run(
            [sys.executable, "transpiler.py", input_mif],
            capture_output=True,
            text=True,
            check=True,
        )
        return True, result.stdout.strip(), None
    except subprocess.CalledProcessError as e:
        return False, None, f"Transpiler error: {e.stderr.strip()}"
    except subprocess.SubprocessError as e:
        return False, None, f"Failed to run transpiler: {str(e)}"


def setup_argument_parser() -> argparse.ArgumentParser:
    """Create and configure the argument parser."""
    parser = argparse.ArgumentParser(
        description="ZASM Compiler - Assembles and transpiles ZASM code",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python compiler.py input.asm output.mif
  python compiler.py --verbose input.asm output.mif
  python compiler.py --no-transpile input.asm output.mif
        """,
    )
    parser.add_argument("input_asm", help="Input assembly file (.asm)")
    parser.add_argument("output_mif", help="Output MIF file (.mif)")
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Enable verbose output"
    )
    parser.add_argument(
        "--no-transpile", action="store_true", help="Skip transpilation step"
    )
    return parser


def verify_dependencies() -> None:
    """Verify that required dependency files exist."""
    required_files = ["assembler.py", "transpiler.py"]
    for file in required_files:
        try:
            ensure_file_exists(file)
        except (FileNotFoundError, ValueError, PermissionError) as e:
            print(f"Error: {str(e)}")
            print(
                f"Please ensure '{file}' is in the current directory and is accessible"
            )
            sys.exit(1)


def main() -> None:
    """Main function that orchestrates the compilation process."""
    parser = setup_argument_parser()
    args = parser.parse_args()

    try:
        # Verify input/output file extensions
        if not validate_file_extension(args.input_asm, ".asm"):
            raise ValueError("Input file must have .asm extension")
        if not validate_file_extension(args.output_mif, ".mif"):
            raise ValueError("Output file must have .mif extension")

        # Check if input file exists and is readable
        ensure_file_exists(args.input_asm)

        # Verify dependencies
        verify_dependencies()

        # Check if output directory is writable
        output_dir = os.path.dirname(args.output_mif) or "."
        if not os.access(output_dir, os.W_OK):
            raise PermissionError(
                f"No write permission for output directory '{output_dir}'"
            )

        if args.verbose:
            print(f"Assembling {args.input_asm}...")

        # Run assembler
        success, error = run_assembler(args.input_asm, args.output_mif)
        if not success:
            raise RuntimeError(error)

        if args.verbose:
            print(f"Successfully created MIF file: {args.output_mif}")

        # Run transpiler unless --no-transpile is specified
        if not args.no_transpile:
            if args.verbose:
                print("Transpiling MIF to Verilog...")

            success, output, error = run_transpiler(args.output_mif)
            if not success:
                raise RuntimeError(error)

            if args.verbose:
                print("Successfully generated Verilog code:")
                print("-" * 40)
            print(output)

    except (ValueError, FileNotFoundError, PermissionError) as e:
        print(f"Error: {str(e)}")
        sys.exit(1)
    except RuntimeError as e:
        print(f"Error: {str(e)}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        if args.verbose:
            import traceback

            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
