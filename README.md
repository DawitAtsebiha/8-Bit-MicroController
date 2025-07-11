# 8-Bit MicroController Project

A complete 8-bit CPU implementation with custom assembler, Verilog hardware description, and simulation tools.

## Overview

This project includes:
- **Custom 8-bit CPU** implemented in SystemVerilog
- **Assembly language** with support for loads, stores, branches, and ALU operations
- **Python assembler** for converting assembly code to binary ROM images
- **Comprehensive testbenches** for simulation and verification
- **Sample programs** demonstrating CPU capabilities

## Project Structure

```
├── 8_But_MightyController_Companion_Document.pdf  # Assembly programming reference
├── asm/                                           # Assembly source files
│   ├── blink.asm                                 # LED blink demo
│   └── fibo.asm                                  # Fibonacci sequence demo
├── build/                                        # Compiled binaries and simulation outputs
│   ├── blink.bin
│   ├── fibo.bin
│   └── tb.out
├── software/                                     # Development tools
│   └── assembler.py                             # Python assembler
├── verilog/                                     # Hardware description files
│   ├── computer.sv                              # Top-level computer module
│   ├── cpu.sv                                   # CPU implementation
│   ├── ALU.sv                                   # Arithmetic Logic Unit
│   ├── control_unit.sv                          # Control unit
│   ├── data_path.sv                             # Data path
│   ├── Memory.sv                                # Memory subsystem
│   └── *.sv                                     # Additional modules
├── testbench/                                   # Simulation testbenches
│   ├── computer_TB_simple.sv                   # Basic testbench
│   └── computer_TB_advanced.sv                 # Advanced testbench
├── MicroController Schematics/                  # Circuit diagrams and documentation
└── waves.vcd                                    # Waveform output file
```

## Prerequisites

Before running this project, ensure you have the following tools installed:

- **Python 3.7+** with the `click` library
- **Icarus Verilog** (iverilog) for simulation
- **GTKWave** for waveform visualization
- **Text editor** or IDE for writing assembly code

### Installing Dependencies

```bash
# Install Python dependencies
pip install click

# On Windows, you may need to install:
# - Icarus Verilog: http://bleyer.org/icarus/
# - GTKWave: https://gtkwave.sourceforge.net/
```

## Getting Started

### Step 1: Learn the Assembly Language

Before writing code, consult the **8-But MightyController Companion Document** (`8_But_MightyController_Companion_Document.pdf`) to understand:
- Supported instructions and addressing modes
- Register usage and memory layout
- Programming examples and best practices

### Step 2: Write Assembly Code

1. Create a new assembly file or use existing demos:
   - `asm/blink.asm` - Simple LED blink program
   - `asm/fibo.asm` - Fibonacci sequence calculator

2. Assembly syntax examples:
   ```assembly
   ; Load immediate value
   LDA #$42        ; Load 0x42 into accumulator A
   
   ; Store to memory
   STAA $80        ; Store accumulator A to address 0x80
   
   ; Branch operations
   loop:
       INC         ; Increment accumulator
       BNE loop    ; Branch if not zero
   
   ; ALU operations
   ADD             ; Add B to A
   SUB             ; Subtract B from A
   ```

### Step 3: Compile Assembly to Binary

Use the Python assembler to convert your assembly code to a binary ROM image:

```bash
python software/assembler.py assemble asm/[your_code].asm -o build/[output_name].bin
```

**Examples:**
```bash
# Compile blink demo
python software/assembler.py assemble asm/blink.asm -o build/blink.bin

# Compile Fibonacci demo
python software/assembler.py assemble asm/fibo.asm -o build/fibo.bin

# Compile with custom names
python software/assembler.py assemble asm/my_program.asm -o build/my_program.bin
```

### Step 4: Compile Simulation

Compile the Verilog simulation using Icarus Verilog:

```bash
iverilog -g2012 -s computer_tb_pro -o build/tb.out verilog/*.sv testbench/computer_TB_advanced.sv
```

**Alternative testbench:**
```bash
# Use simple testbench instead
iverilog -g2012 -s computer_tb_simple -o build/tb.out verilog/*.sv testbench/computer_TB_simple.sv
```

### Step 5: Run Simulation

Execute the compiled simulation:

```bash
vvp -n build/tb.out
```

This will:
- Load your compiled binary into the CPU's ROM
- Run the simulation
- Generate timing and signal data
- Create the `waves.vcd` waveform file

### Step 6: Analyze Results

View the simulation waveforms using GTKWave:

```bash
gtkwave waves.vcd
```

In GTKWave, you can:
- Examine CPU signals (clock, reset, program counter, etc.)
- View memory contents and register values
- Analyze instruction execution timing
- Debug your assembly programs

## Sample Programs

### Blink Demo (`asm/blink.asm`)
A simple program that toggles an LED output, demonstrating basic I/O operations.

### Fibonacci Demo (`asm/fibo.asm`)
Calculates Fibonacci numbers, showcasing arithmetic operations and memory usage.

## Supported Instructions

| Instruction | Modes | Description |
|-------------|-------|-------------|
| `LDA` | IMM, DIR | Load accumulator A |
| `LDAB` | IMM, DIR | Load accumulator B |
| `STAA` | DIR | Store accumulator A |
| `STAB` | DIR | Store accumulator B |
| `ADD` | IMP | Add B to A |
| `SUB` | IMP | Subtract B from A |
| `AND` | IMP | Logical AND |
| `OR` | IMP | Logical OR |
| `INC` | IMP | Increment accumulator |
| `DEC` | IMP | Decrement accumulator |
| `BRA` | REL | Branch always |
| `BNE` | REL | Branch if not equal |
| `BEQ` | REL | Branch if equal |

### Addressing Modes
- **IMP**: Implied (no operand)
- **IMM**: Immediate (`#$42`)
- **DIR**: Direct (`$80`)
- **REL**: Relative (labels, `*` for self-branch)

## Troubleshooting

### Common Issues

1. **Assembler errors**: Check syntax against the companion document
2. **Simulation won't start**: Verify all Verilog files are present
3. **No waveform output**: Ensure simulation completes successfully
4. **GTKWave won't open**: Check that `waves.vcd` file exists and is not empty

### Getting Help

1. Review the **8-But MightyController Companion Document**
2. Check the sample assembly files for reference
3. Examine the Verilog source code for hardware details
4. Look at the schematic PDFs in `MicroController Schematics/`

## Development Workflow

1. **Plan** your program using the instruction set reference
2. **Write** assembly code in the `asm/` folder
3. **Assemble** to binary using the Python assembler
4. **Simulate** using Icarus Verilog
5. **Debug** using GTKWave waveform analysis
6. **Iterate** until your program works correctly

## License

This project is for educational purposes. Please refer to individual file headers for specific licensing information.
