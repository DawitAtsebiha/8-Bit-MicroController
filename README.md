# 8-Bit MicroController Project

A complete 8-bit CPU implementation with GUI interface, custom assembler, Verilog hardware description, and simulation tools.

## Overview

This project includes:
- **PyQt6 GUI Application** - User-friendly interface for assembly, simulation, and waveform analysis
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
│   ├── app.py                                   # PyQt6 GUI Application
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

- **Python 3.7+** with PyQt6 and click libraries
- **Icarus Verilog** (iverilog) for simulation 
- **GTKWave** for waveform visualization
*I would recommend using chocolatey to install both Icarus and GTKWave*
- **Text editor** or IDE for writing assembly code

### Installing Dependencies

Using Chocolatey (recommended):
```powershell
# Install all required packages via Chocolatey
choco install python iverilog gtkwave

# Install Python dependencies
pip install PyQt6 click
```

Manual installation:
```bash
# Install Python dependencies
pip install PyQt6 click

# Install Icarus and GTKWave manually from their respective websites
```

## Getting Started

### Quick Start with GUI (Recommended)

The easiest way to use this project is through the graphical interface:

1. **Launch the GUI application:**
   ```powershell
   python software/app.py
   ```

2. **Use the GUI to:**
   - Select your assembly file (.asm)
   - Assemble code to binary
   - Compile and run simulation
   - View waveforms in GTKWave

The GUI provides a streamlined workflow with visual feedback and integrated console output.

### Command Line Usage (Advanced)

For advanced users or automation, you can still use the command-line tools directly.

### Step 1: Get Familiar with 8-Bit Assembly

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

### Step 3: Using the GUI Application

1. **Start the application:**
   ```powershell
   python software/app.py
   ```

2. **Select your assembly file** using the "Select ASM File" button

3. **Assemble your code** using the "Assemble Code" button
   - This converts your .asm file to a .bin file in the build/ directory

4. **Run simulation** using the "Compile & Simulate" button
   - Compiles Verilog code and runs the simulation
   - Generates waves.vcd for waveform analysis

5. **View waveforms** using the "Show Wave Simulation" button
   - Opens GTKWave with the simulation results

### Alternative: Command Line Workflow

#### Manual Assembly Compilation

Use the Python assembler to convert your assembly code to a binary ROM image:

```powershell
python software/assembler.py assemble asm/[your_code].asm -o build/[output_name].bin
```

**Examples:**
```powershell
# Compile blink demo
python software/assembler.py assemble asm/blink.asm -o build/blink.bin

# Compile Fibonacci demo
python software/assembler.py assemble asm/fibo.asm -o build/fibo.bin

# Compile with custom names
python software/assembler.py assemble asm/my_program.asm -o build/my_program.bin
```

#### Manual Simulation Compilation

Compile the Verilog simulation using Icarus Verilog:

```powershell
iverilog -g2012 -s computer_TB -o build/tb.out verilog/*.sv testbench/computer_TB.sv
```

#### Manual Simulation Execution

Execute the compiled simulation:

```powershell
vvp -n build/tb.out
```

This will:
- Load your compiled binary into the CPU's ROM
- Run the simulation
- Generate timing and signal data
- Create the `waves.vcd` waveform file

#### Manual Waveform Analysis

View the simulation waveforms using GTKWave:

```powershell
gtkwave waves.vcd
```

## GUI Features

The PyQt6 GUI application (`software/app.py`) provides:

- **File Selection**: Browse and select assembly files with a clean interface
- **One-Click Assembly**: Convert assembly code to binary with visual feedback
- **Integrated Simulation**: Compile Verilog and run simulation in one step
- **Waveform Integration**: Direct launch of GTKWave for signal analysis
- **Console Output**: Real-time display of all tool outputs and error messages
- **Status Indicators**: Visual feedback on operation progress and results

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

1. **GUI won't start**: 
   - Ensure PyQt6 is installed: `pip install PyQt6`
   - Check Python version (3.7+ required)

2. **Assembler errors**: Check syntax against the companion document

3. **Simulation won't start**: Verify all Verilog files are present and Icarus Verilog is installed

4. **No waveform output**: Ensure simulation completes successfully

5. **GTKWave won't open**: 
   - Check that `waves.vcd` file exists and is not empty
   - Verify GTKWave is installed and in PATH

6. **Python package errors**: Install missing dependencies:
   ```powershell
   pip install PyQt6 click
   ```

### Getting Help

1. Review the **8-But MightyController Companion Document**
2. Check the sample assembly files for reference
3. Examine the Verilog source code for hardware details
4. Look at the schematic PDFs in `MicroController Schematics/`

## Development Workflow

### GUI Workflow (Recommended)
1. **Launch** the GUI: `python software/app.py`
2. **Plan** your program using the instruction set reference
3. **Write** assembly code in the `asm/` folder
4. **Load** your file in the GUI using "Select ASM File"
5. **Assemble** using the "Assemble Code" button
6. **Simulate** using the "Compile & Simulate" button
7. **Debug** using the "Show Wave Simulation" button for GTKWave analysis
8. **Iterate** until your program works correctly

### Command Line Workflow (Advanced)
1. **Plan** your program using the instruction set reference
2. **Write** assembly code in the `asm/` folder
3. **Assemble** to binary using the Python assembler
4. **Simulate** using Icarus Verilog
5. **Debug** using GTKWave waveform analysis
6. **Iterate** until your program works correctly
