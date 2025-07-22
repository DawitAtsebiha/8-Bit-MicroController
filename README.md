# 8-But MightyController

> A learning-oriented 8-bit CPU with modern development workflow  
> GUI • Custom two-pass assembler • Verilog RTL • Icarus/GTKWave simulation

---

## Overview

**8-But MightyController** is an 8-bit CPU that I started working on to learn more about MicroControllers and low-level assembly and Digital Logics! If you have any feature/performance improvement suggestions I would be more than happen to implement them, also make sure to check the wiki where I document major changes!

### Key Features
* **16 general-purpose registers** (A-P) with comprehensive ALU operations
* **Two-pass assembler** with label resolution and branch offset calculation
* **Integrated GUI workflow** covering assembly → compile → simulate → debug
* **Comprehensive test suite** with detailed debugging capabilities
* **GTKWave integration** for signal inspection and timing analysis

---

## Quick Start

```bash
# 1. Clone & enter
git clone https://github.com/DawitAtsebiha/8-But-MightyController.git
cd 8-But-MightyController

# 2. Install dependencies
pip install -r requirements.txt   # PyQt6 click

# 3. Launch the assembler/simulator
python "MightyController.py"
```

**Using the GUI:**
1. **Load** an `.asm` program from `Programs/asm/`  
2. Click **Assemble** → **Compile & Simulate**  
3. GTKWave opens with the waveform trace; inspect `PC`, `IR`, `io_data`, etc.

**Command Line Alternative:**
```bash
python software/assembler.py assemble Programs/asm/test.asm -o Programs/build/test.bin
iverilog -g2012 -s computer_TB -o build/tb.out verilog/*.sv testbench/computer_TB.sv
vvp -n build/tb.out +ROMFILE=build/test.bin +DEBUG +CYCLES=500
gtkwave waves.vcd
```

---

## Architecture

### CPU Core Components
* **Registers** — 16 general-purpose 8-bit registers (`A..P`) exposed to the ISA
* **ALU** — Supports ADD, SUB, AND, OR, XOR, INC, DEC with flag updates and overflow detection
* **Control Unit** — Enhanced 6-state FSM with improved branch handling
* **Branch Logic** — PC-relative branching with ±127 byte range using signed 8-bit offsets

### Memory System
| Range | Size | Purpose |
|-------|------|---------|
| `$00-$7F` | 128 bytes | On-chip ROM |
| `$80-$DF` | 96 bytes | RAM |
| `$F0-$FF` | 16 bytes | Memory-mapped I/O |

### I/O Mapping
| Address | Purpose |
|---------|---------|
| `$F0` | LED output / GPIO |
| `$F1-$FF` | Reserved for expansion |

### State Machine
The CPU uses a **6-stage finite state machine** for instruction execution:

| Stage | Purpose |
|-------|---------|
| **Fetch** | Multi-cycle instruction fetch (3 bytes) |
| **Decode** | Determine instruction type & addressing mode |
| **Execute** | Setup ALU operations & condition evaluation |
| **LoadStore** | Memory operations (LD/ST instructions) |
| **Data** | ALU execution & register write-back |
| **Branch** | PC-relative branch calculation & execution |

---

## Instruction Set Architecture

### Addressing Modes
All instructions use consistent 3-byte encoding for simplified control logic:

| Mode | Syntax | Format | Description |
|------|--------|--------|-------------|
| **IMP** | `INC A` | opcode + reg + padding | Implied operand |
| **IMM** | `LD A, #$7F` | opcode + reg + literal | Immediate value |
| **DIR** | `ST B, $80` | opcode + reg + address | Direct memory |
| **REG** | `ADD A, B` | opcode + reg1 + reg2 | Register-to-register |
| **REL** | `BRA loop` | opcode + offset + padding | PC-relative branch |

### Complete Instruction Reference

| Mnemonic | Modes | Description | Opcodes |
|----------|-------|-------------|---------|
| **Data Movement** | | | |
| `LD` | IMM, DIR | Load register from immediate or memory | 0x80, 0x81 |
| `ST` (not currently functional) | DIR | Store register to memory | 0x82 |
| **Arithmetic & Logic** | | | |
| `ADD` | REG | Add registers: A = A + B | 0x90 |
| `SUB` | REG | Subtract registers: A = A - B | 0x91 |
| `AND` | REG | Bitwise AND: A = A & B | 0x92 |
| `OR` | REG | Bitwise OR: A = A \| B | 0x93 |
| `XOR` | REG | Bitwise XOR: A = A ^ B | 0x94 |
| `INC` | IMP | Increment register: A = A + 1 | 0xA0 |
| `DEC` | IMP | Decrement register: A = A - 1 | 0xA1 |
| **Control Flow** | | | |
| `BRA` | REL | Unconditional branch | 0x20 |
| `BNE` | REL | Branch if not equal (Z=0) | 0x23 |
| `BEQ` | REL | Branch if equal (Z=1) | 0x24 |

**Branch Instructions:**
- Use PC-relative addressing with ±127 byte range
- Branch offset calculated as: `target_address - (PC_after_instruction)`
- BNE/BEQ test the Zero flag from the last ALU operation

---

## Sample Programs

### Basic Load/Store Testing
```assembly
// test1(LD).asm - Load Instruction Testing
LD A, #$42          // Load immediate
LD B, #$7F          // Load immediate  
ST A, $80           // Store to memory
LD C, $80           // Load from memory
```

### Arithmetic Operations
```assembly
// test2(ALU).asm - ALU Testing  
LD A, #$0F
LD B, #$03
ADD A, B            // A = A + B
SUB A, B            // A = A - B  
AND A, B            // A = A & B
OR A, B             // A = A | B
XOR A, B            // A = A ^ B
```

### Branch Control Flow
```assembly
// test4(BNE_BEQ).asm - Branch Testing
LD F, #$03          // Load counter

LOOP:
    DEC F           // Decrement counter
    BNE LOOP        // Branch back if F ≠ 0

// Test equality branching  
LD G, #$42
LD H, #$42
SUB G, H            // G = 0, sets Zero flag
BEQ SUCCESS         // Branch if equal

LD B, #$FF          // Error path
SUCCESS:
LD C, #$AA          // Success path
```

---

## Testing & Debugging

### Test Suite
The repository includes comprehensive test programs:

* **test1(LD).asm** - Load instruction testing with immediate and direct addressing
* **test2(ALU).asm** - Complete ALU operation validation  
* **test3(INC_DEC).asm** - Increment/decrement functionality
* **test4(BNE_BEQ).asm** - Branch instruction testing with loop control

### Debug Features
Enable targeted logging with plusargs:

| Flag | Effect |
|------|--------|
| `+DEBUG_PC` | Print PC each cycle |
| `+DEBUG_STATE` | Decode FSM to mnemonic |
| `+DEBUG_MEM` | Show RAM writes |
| `+DEBUG_REG` | Show register file contents |
| `+DEBUG_INNER` | Show detailed CPU operations |
| `+CYCLES=N` | Set maximum simulation cycles |

### GTKWave Signals
Key signals for inspection:
* `PC`, `IR` — instruction flow and branch targets
* `Reg_A…Reg_P` — all 16 working registers  
* `io_data`, `io_we` — external interface  
* `dut.cpu1.control_unit1.state` — current FSM state
* `dut.cpu1.data_path1.alu_result` — ALU computation results

---

## Module Architecture

| File | Responsibilities | Dependencies |
|------|-----------------|--------------|
| **computer.sv** | System top-level, instantiates CPU and memory, routes I/O bus | `cpu.sv`, `Memory.sv` |
| **cpu.sv** | Combines data path and control unit with external handshake | `data_path.sv`, `control_unit.sv` |
| **data_path.sv** | Register file, ALU, PC, multiplexers, flag logic | `ALU.sv`, `registers.sv` |
| **control_unit.sv** | 6-state FSM, control signal generation, branch orchestration | `data_path.sv` |
| **registers.sv** | Dual-port 16×8-bit register file | `data_path.sv` |
| **ALU.sv** | Combinational arithmetic/logic unit with status flags | `data_path.sv` |
| **Memory.sv** | Unified memory with ROM/RAM/I/O mapping | `computer.sv` |

---

## Development Status

### Recent Improvements
* **Enhanced branch instructions** — BRA, BNE, BEQ with proper PC-relative addressing
* **Improved assembler** — Fixed branch offset calculation for correct relative addressing  
* **Comprehensive test suite** — Complete instruction testing including branch operations
* **Enhanced debugging** — Additional debug flags and detailed state inspection

### Current Issues
* Branch instructions may produce incorrect PC jumps due to ALU input timing
* Complex branch scenarios require additional validation
* Some edge cases in branch offset calculation may need refinement

### Testing Recommendations
Start with simple test programs (test1-test3) to verify basic CPU functionality, then proceed to branch testing (test4) for advanced validation.

---

## Prerequisites & Installation

| Tool | Version | Purpose |
|------|---------|---------|
| Python | 3.7+ | Assembler, GUI |
| PyQt6 | latest | GUI framework |
| Icarus Verilog | 11+ | HDL simulation |
| GTKWave | 3.3+ | Waveform viewer |

### Windows Installation
```powershell
choco install python iverilog gtkwave
pip install PyQt6 click
```

### Linux/macOS Installation
```bash
# Ubuntu/Debian
sudo apt install python3 iverilog gtkwave
pip3 install PyQt6 click

# macOS (Homebrew)
brew install python icarus-verilog gtkwave
pip3 install PyQt6 click
```

---

## Roadmap

### Completed
* Simplified control unit states from 17 to 6 using optimizations in the assembler
* Enhanced branch instructions with PC-relative addressing
* Two-pass assembler with label resolution
* Comprehensive test suite and debugging tools
* Integrated GUI workflow

### In Progress 
* Branch instruction hardware optimization
* ALU input routing fixes for reliable branch execution

### Future Work
* **Hardware Expansion**
  - Dynamic ROM loading for FPGA deployment
  - Implement pipeline processing 
  - Additional conditional branches (BCC, BPL, BMI, BVS)
  - Interrupt system with vector table
* **Development Tools**
  - Unit tests for assembler components
  - Synthesis constraints for FPGA boards
  - Memory expansion support
* **Documentation**
  - Video tutorials and educational materials
  - Advanced programming examples
  - Hardware interfacing guides

---

## Contributing

Contributions and bug reports are welcome! Please feel free to:
- Report issues or bugs
- Suggest new features or improvements  
- Submit pull requests with enhancements
- Share educational use cases and examples

---