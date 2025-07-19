# 8-Bit MightyController
#### Check out active-development to see what new changes are being worked on! (Note: the build might not be stable enough to run properly)

A complete 8-bit CPU implementation with GUI interface, custom assembler, SystemVerilog hardware description, and simulation tools.

## Quick Start

1. **Launch the GUI:**
   ```powershell
   python "MightyController GUI.py"
   ```
2. **Select your assembly file** (.asm) or use **Quick Run** for existing binaries
3. **Assemble code** to binary
4. **Compile & simulate**
5. **View waveforms** in GTKWave

### Quick Run (New!)
- Select a previously assembled program from the dropdown and click **Run** to simulate instantly.

## Project Structure

```
8-But MightyController/
|
├── MightyController GUI.py          # Main GUI application
|
├── ROM Programs/                  
│   ├── asm/                         # Demo assembly test programs
│   └── build/                       # Compiled binaries from assembly test programs
│      
├── software/                     
│   └── assembler.py                 # Assembly to binary assembler
|
├── verilog/                        
│   ├── computer.v                  # Top-level system
│   ├── cpu.v                       # CPU core
│   ├── ALU.v                       # Arithmetic Logic Unit
│   ├── control_unit.v              # Control unit
│   ├── data_path.v                 # Data path
│   ├── memory.v                    # Memory subsystem 
|   ├── ram_96x8.v                   # RAM
│   └── rom_128x8.v                 # ROM
|
├── testbench/                       
│   └── computer_TB.sv               # Main testbench (dynamic ROM loading, debug options)
├── Documentation/                  
    ├── State Machine Diagrams/
    ├── ROM Programs Waveform/
    └── MicroController Schematics/
```

## Prerequisites

**Required Software:**
- **Python 3.7+** with PyQt6 and click
- **Icarus Verilog** (iverilog) for simulation
- **GTKWave** for waveform visualization

**Installation (Windows - Chocolatey recommended):**
```powershell
# Install tools
choco install python iverilog gtkwave

# Install Python packages
pip install PyQt6 click
```

## Supported Instructions

| Instruction | Mode | Example | Description |
|-------------|------|---------|-------------|
| `LDA` | IMM/DIR | `LDA #$42` | Load accumulator A |
| `LDAB` | IMM/DIR | `LDAB $80` | Load accumulator B |
| `STAA` | DIR | `STAA $F0` | Store accumulator A |
| `STAB` | DIR | `STAB $F0` | Store accumulator B |
| `ADD` | IMP | `ADD` | Add B to A |
| `SUB` | IMP | `SUB` | Subtract B from A |
| `AND` | IMP | `AND` | Logical AND |
| `OR` | IMP | `OR` | Logical OR |
| `INCA` | IMP | `INC` | Increment accumulator A |
| `DECA` | IMP | `DEC` | Decrement accumulator A |
| `INCB` | IMP | `INCB` | Increment accumulator B |
| `DECB` | IMP | `DECB` | Decrement accumulator B |
| `BRA` | REL | `BRA loop` | Branch always |
| `BNE` | REL | `BNE loop` | Branch if not equal |
| `BEQ` | REL | `BEQ loop` | Branch if equal |

**Addressing Modes:**
- **IMP**: Implied (no operand)
- **IMM**: Immediate (`#$42`)
- **DIR**: Direct (`$80`)
- **REL**: Relative (labels)

## Memory Map

| Address Range | Description |
|---------------|-------------|
| `$00-$7F` | ROM (128 bytes) |
| `$80-$DF` | RAM (96 bytes) |
| `$F0-$FF` | I/O Ports (16 bytes) |

## Debug Options (GUI)

The GUI now includes advanced debugging options:

| Option | Description |
|--------|-------------|
| **Max Cycles** | Configure simulation length (100-50000 cycles) |
| **Show PC** | Display Program Counter changes |
| **Show IR** | Display Instruction Register changes |
| **Show A Register** | Display A Register changes |
| **Show B Register** | Display B Register changes |
| **Show Memory** | Display Memory access |
| **Show I/O** | Display I/O operations |
| **Show State** | Display CPU state machine |
| **Verbose Mode** | Enable all debug options |
| **Presets** | Quick configuration for common debug scenarios |

## GTKWave Signals

When viewing waveforms, look for these key signals:

**CPU State:**
- `PC` - Program Counter
- `IR` - Instruction Register
- `A_Reg` - Accumulator A
- `B_Reg` - Accumulator B

**I/O Signals:**
- `io_addr` - I/O address
- `io_data` - I/O data
- `io_we` - I/O write enable

## Troubleshooting

| Problem | Solution |
|---------|----------|
| GUI won't start | Ensure that PyQt6 is installed: `pip install PyQt6` |
| Assembly errors | Check syntax in companion document |
| Simulation fails | Verify Icarus Verilog installation |
| No waveform | Ensure simulation completes successfully |
| GTKWave won't open | Check that `waves.vcd` exists and GTKWave is installed |
| B register corruption | Fixed in latest version - B register now works correctly in branch instructions |

## Development Workflow

### Using the GUI (Recommended)
1. **Launch:** `python "MightyController GUI.py"`
2. **Write** your assembly code in `ROM Programs/asm/`
3. **Select** your .asm file in the GUI
4. **Assemble** your code (creates .bin file)
5. **Compile & Simulate** (runs testbench)
6. **View Waveforms** (opens GTKWave)
7. **Debug** and iterate

### Quick Run Feature (New!)
1. **Launch the GUI**
2. **Select** a previously assembled program from the dropdown
3. **Click Run** to immediately simulate
4. **View Waveforms** to analyze results

### Command Line (Advanced)
```powershell
# Assemble
python software/assembler.py assemble "ROM Programs/asm/program.asm" -o "ROM Programs/build/program.bin"

# Compile simulation
iverilog -g2012 -s computer_TB -o "ROM Programs/build/tb.out" verilog/*.sv testbench/computer_TB.sv

# Run simulation with dynamic ROM loading and debug options
vvp -n "ROM Programs/build/tb.out" +ROMFILE="ROM Programs/build/program.bin" +TESTNAME="My Program Test" +CYCLES=1000 +DEBUG +DEBUG_PC +DEBUG_IR +DEBUG_REGS

# View waveforms
gtkwave waves.vcd
```

## Documentation

- **Assembly Reference**: `Documentation/8_But_MightyController_Companion_Document.pdf`
- **Hardware Schematics**: `Documentation/MicroController Schematics/`
- **Instruction Set**: See table above
- **Sample Code**: `ROM Programs/asm/` directory

## Recent Updates

- **Dynamic ROM Loading**: Programs can now be loaded into ROM directly from the GUI without testbench modifications
- **Debug Options**: Added configurable debugging with register visibility controls
- **Quick Run**: Added feature to quickly run previously assembled programs 
- **B Register Fix**: Fixed critical bug that corrupted B register during branch instructions
- **Enhanced GUI**: Improved user interface with better layout and styling

