# 8-Bit MightyController

A complete 8-bit CPU implementation with GUI interface, custom assembler, SystemVerilog hardware description, and simulation tools.

## Quick Start

1. **Launch the GUI:**
   ```powershell
   python "MightyController GUI.py"
   ```

2. **Select your assembly file** (.asm)
3. **Assemble code** to binary
4. **Compile & simulate** 
5. **View waveforms** in GTKWave

## Project Structure

```
8-But MightyController/
├── MightyController GUI.py           # Main GUI application
├── ROM Programs/                     # Assembly programs
│   ├── asm/                         
│   │   ├── blink.asm                # LED blink demo
│   │   └── fibo.asm                 # Fibonacci sequence demo
│   └── build/                       # Compiled binaries
│       ├── blink.bin
│       ├── fibo.bin
│       └── tb.out
├── software/                     
│   └── assembler.py                 # Python assembler
├── verilog/                        
│   ├── computer.sv                  # Top-level system
│   ├── cpu.sv                       # CPU core
│   ├── ALU.sv                       # Arithmetic Logic Unit
│   ├── control_unit.sv              # Control unit
│   ├── data_path.sv                 # Data path
│   └── Memory.sv                    # Memory subsystem
├── testbench/                       
│   └── computer_TB.sv               # Main testbench
├── Documentation/                  
    ├── 8_But_MightyController_Companion_Document.pdf
    |── State Machine Diagrams
    |── ROM Programs Waveform
    └── MicroController Schematics/
```

## 🛠️ Prerequisites

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

## 📝 Supported Instructions

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
| `INC` | IMP | `INC` | Increment accumulator |
| `DEC` | IMP | `DEC` | Decrement accumulator |
| `BRA` | REL | `BRA loop` | Branch always |
| `BNE` | REL | `BNE loop` | Branch if not equal |
| `BEQ` | REL | `BEQ loop` | Branch if equal |

**Addressing Modes:**
- **IMP**: Implied (no operand)
- **IMM**: Immediate (`#$42`)
- **DIR**: Direct (`$80`)
- **REL**: Relative (labels)

## 🔧 Memory Map

| Address Range | Description |
|---------------|-------------|
| `$00-$7F` | ROM (128 bytes) |
| `$80-$DF` | RAM (96 bytes) |
| `$F0-$FF` | I/O Ports (16 bytes) |

## Sample Programs

### Blink Program (`ROM Programs/asm/blink.asm`)
```assembly
LDA  #$01      ; Load pattern 1 (LED on)
loop:
    STAA $F0   ; Output to LED port
    LDA  #$00  ; Load pattern 0 (LED off)  
    STAA $F0   ; Output to LED port
    BRA  loop  ; Continue forever
```

### Fibonacci Program (`ROM Programs/asm/fibo.asm`)
Calculates Fibonacci sequence: 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233...

## GTKWave Signals

When viewing waveforms, look for these key signals:

**Program Monitoring:**
- `fibonacci_output` - Fibonacci sequence values
- `blink_output` - LED blink patterns
- `fibonacci_valid` - Fibonacci test active
- `blink_valid` - Blink test active

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
| GUI won't start | Install PyQt6: `pip install PyQt6` |
| Assembly errors | Check syntax in companion document |
| Simulation fails | Verify Icarus Verilog installation |
| No waveform | Ensure simulation completes successfully |
| GTKWave won't open | Check `waves.vcd` exists and GTKWave is installed |

## Development Workflow

### Using the GUI (Recommended)
1. **Launch:** `python "MightyController GUI.py"`
2. **Write** your assembly code in `ROM Programs/asm/`
3. **Select** your .asm file in the GUI
4. **Assemble** your code (creates .bin file)
5. **Compile & Simulate** (runs testbench)
6. **View Waveforms** (opens GTKWave)
7. **Debug** and iterate

### Command Line (Advanced)
```powershell
# Assemble
python software/assembler.py assemble "ROM Programs/asm/program.asm" -o "ROM Programs/build/program.bin"

# Compile simulation
iverilog -g2012 -s computer_TB -o "ROM Programs/build/tb.out" verilog/*.sv testbench/computer_TB.sv

# Run simulation
vvp -n "ROM Programs/build/tb.out"

# View waveforms
gtkwave waves.vcd
```

## Documentation

- **Assembly Reference**: `Documentation/8_But_MightyController_Companion_Document.pdf`
- **Hardware Schematics**: `Documentation/MicroController Schematics/`
- **Instruction Set**: See table above
- **Sample Code**: `ROM Programs/asm/` directory

