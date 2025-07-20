# 8‑But MightyController

### A teaching‑oriented 8‑bit CPU with a modern workflow

> GUI • Custom two‑pass assembler • Verilog RTL • Icarus/GTKWave simulation

---

## Table of Contents
- [Overview](#overview)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
  - [CPU Core](#cpu-core)
  - [Memory Sub‑System](#memory-sub-system)
  - [I/O Map](#io-map)
- [Instruction Set Architecture (ISA)](#instruction-set)
  - [Addressing Modes](#addressing-modes)
  - [Opcode Reference](#opcode-reference)
- [Development Workflow](#development-workflow)
  - [Graphical UI](#using-the-gui)
  - [Command Line](#command-line)
- [Simulation & Debugging](#simulation--debugging)
- [Sample Programs](#sample-programs)
- [Prerequisites & Installation](#prerequisites-installation)
- [Roadmap](#roadmap)

## Overview

**8‑But MightyController** is an 8-Bit CPU designed for hardware/firmware co‑design:

* A parameterised register file (16 × 8‑bit) that supports single‑register and register‑to‑register ALU operations
* A robust control unit that sequences a 6‑stage finite‑state‑machine  
* A two-pass assembler that understands labels, `EQU` constants, relative branching, immediate/direct/register addressing to convert assembly code written in the 8-But Mighty's custom ISA
* An easy to use GUI that covers the workflow of assembly ➜ compile ➜ simulate ➜ waveform inspection in one window  
* A thorough testbench with CLI flags (`+ROMFILE=`, `+CYCLES=`, `+DEBUG_PC`, …) that allows for in-depth debugging

This repo contains a couple of demo programs that can be assembled and debugged from the GUI right away, just follow the quick‑start below. If you’d like to create and debug your own programs, make sure to consult the [ISA documentation!](#instruction-set)

## Quick Start

```bash
# 1. Clone & enter
git clone https://github.com/DawitAtsebiha/8‑But‑MightyController.git
cd 8‑But‑MightyController

# 2. Install dependencies (Windows users: see Chocolatey notes below)
pip install -r requirements.txt   # PyQt6 click

# 3. Launch the assembler/simulator
python "MightyController.py"
```

1. **Load** an `.asm` program from `Programs/asm/`  
2. Click **Assemble** ➜ **Compile & Simulate**  
3. GTKWave opens with the waveform trace; inspect `PC`, `IR`, `io_data`, etc.

If you would like to run the assembly/simulations directly in your console and/or adjust the iverilog settings, use the following format:
```bash
python software/assembler.py assemble [location of .asm file] -o Programs/build/[name of program].bin
iverilog -g2012 -s computer_TB -o build/tb.out verilog/*.sv testbench/computer_TB.sv
vvp -n build/tb.out +ROMFILE=build/[name of program].bin +DEBUG +CYCLES=500
gtkwave waves.vcd
```

An example of the above would be: 
```bash
python software/assembler.py assemble Programs/asm/test.asm -o Programs/build/test.bin
iverilog -g2012 -s computer_TB -o build/tb.out verilog/*.sv testbench/computer_TB.sv
vvp -n build/tb.out +ROMFILE=build/test.bin +DEBUG +CYCLES=500
gtkwave waves.vcd
```

## Project Structure
```text
8‑Bit‑MightyController/
├── MightyController GUI.py      # GUI development front-end
├── software/
│   └── assembler.py             # Two‑pass Python assembler (see docs below)
├── verilog/                     # RTL
│   ├── computer.v               # Top‑level wrapper
│   ├── cpu.v                    # CPU core
│   ├── data_path.v              # Register file, buses, ALU glue
│   ├── control_unit.v           # Micro‑coded FSM
│   ├── ALU.v                    # 8‑bit arithmetic logic unit
|   ├── registers.v              # 
|   ├── 
|   ├──  
│   └── Memory.sv                # Unified ROM/RAM/I‑O
├── testbench/
│   └── computer_TB.sv           # Feature‑rich testbench
├── ROM Programs/
│   ├── asm/                     # Source
│   └── build/                   # Compiled binaries
└── Documentation/               # PDF companion, state diagrams, schematics
```

## Module Breakdown

| File            | Responsibilities                                                                                                                                                                   | Works With                       |
|-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------|
| **computer.sv** | System top‑level. Instantiates `cpu`, `Memory`, and routes the tri‑state `io_data` bus. Provides the clean interface seen by the testbench or (eventually) an FPGA top module.      | `cpu.sv`, `Memory.sv`            |
| **cpu.sv**      | Glue wrapper combining `data_path` and `control_unit`; exposes simple handshake signals to the outside world (`mem_address`, `mem_data`, `mem_we`).                                 | `data_path.sv`, `control_unit.sv`|
| **data_path.sv**| Implements the register file, ALU, program counter, internal multiplexers, and status‑flag logic. All arithmetic signals live here.                                                 | `ALU.sv`, `registers.sv`         |
| **control_unit.sv** | Six‑state FSM that generates control signals: selects bus sources, issues register writes, orchestrates memory cycles and branching. Translates `IR` + flags into next state. | `data_path.sv`                   |
| **registers.sv**| True dual‑port 16 × 8‑bit register file. Read addresses come from the control unit; write‑back addressed via datapath.                                                              | `data_path.sv`                   |
| **ALU.sv**      | Pure‑combinational arithmetic / logic unit supporting ADD, SUB, AND, OR, XOR plus INC/DEC shorthand. Outputs result and status flags (Z, N, C).                                     | `data_path.sv`                   |
| **Memory.sv**   | Unified memory module mapping 0x00–0x7F to ROM, 0x80–0xDF to RAM, 0xF0–0xFF to I/O. Reads are single‑cycle; writes are ignored for the ROM region.                                   | `computer.sv`, external I/O      |

**How the pieces fit together**

1. On each clock edge **control_unit** evaluates the current state plus `IR` and issues control signals (register selects, ALU op, write‑enables).  
2. **data_path** moves data between the register file, ALU, and memory interface based on those signals. ALU results can feed back into registers or update the PC.  
3. For memory requests, **Memory** decides whether the access hits ROM, RAM, or the I/O window. ROM reads return the byte next cycle; I/O writes drive `io_data` so peripherals/testbench can observe them.  
4. The top‑level **computer** module simply wires CPU ↔ Memory and exports the tri‑state I/O bus so the testbench (or real hardware) can latch LED patterns, etc.

## State Machine & Encoding

The **control_unit.sv** drives the CPU through **17 one‑hot states**. A register with 17 flip‑flops holds the active state; exactly one bit is `1` at any time, keeping next‑state logic simple and glitch‑free on FPGAs.

### State Overview
| ID | Mnemonic    | Purpose                             |
|----|-------------|-------------------------------------|
| 0  | Fetch0      | Issue program‑counter address to ROM |
| 1  | Fetch1      | Latch opcode into `IR`               |
| 2  | Fetch2      | Bypass stalls / align buses          |
| 3  | Decode      | Determine addressing mode & dispatch |
| 4  | LoadStore0  | Addr calculation for LD/ST           |
| 5  | LoadStore2  | Read / write cycle start             |
| 6  | LoadStore3  | Wait for memory ready                |
| 7  | LoadStore4  | Write‑back to register               |
| 8  | LoadStore5  | Finalise bus release                 |
| 9  | Data0       | First ALU phase (source fetch)       |
| 10 | Data1       | Execute ALU                          |
| 11 | Data2       | Write‑back result                    |
| 12 | Data3       | Flag update                          |
| 13 | Branch0     | Calculate relative offset            |
| 14 | Branch1     | Update PC if taken                   |
| 15 | Branch2     | Flush pipeline & resume fetch        |

> A visual representation of the transitions can be found below. Arrows correspond to *next‑state* paths evaluated inside `control_unit.sv`.
![8-But MightyController StateDiagram](https://github.com/user-attachments/assets/488a753f-e519-4447-a7a3-94b77992899e)

### One‑Hot Encoding Matrix
Each row shows the 17‑bit state register where `1` marks the active state. For example, row `Fetch0` asserts bit‑16 while all others are 0.
<img width="1288" height="577" alt="8-But MightyController StateDiagramEncoding" src="https://github.com/user-attachments/assets/7dd33d20-ff8b-4c7d-93d3-a294651ec3fe" />

This explicit encoding eliminates ripple decoders and allows single‑cycle, combinational next‑state logic, which is important for meeting timing once the design is ported to an FPGA.

## Architecture

### CPU Core
* **Registers** — 16 general‑purpose 8‑bit regs (`A..P`) exposed to the ISA.  
* **ALU** — supports ADD, SUB, AND, OR, XOR, INC, DEC with flag update.  
* **Control Unit** — 6‑state FSM (`Fetch0/1/2`, `Decode`, `Data*`, `Branch*`, …) drives bus multiplexers & write‑enables.

### Memory Sub‑System
* 128‑byte _on‑chip_ ROM, 96‑byte RAM, 16‑byte memory‑mapped I/O.  
* Single‑cycle access thanks to unified `Memory.sv`.  
* `computer_TB` provides a helper `load_rom()` task to patch ROM contents at sim‑time.

### I/O Map
| Range | Purpose            |
|-------|--------------------|
| `$F0` | LED out / GPIO     |
| `$F1` | (reserved)         |
| …     | Future expansion   |

## Instruction Set

### Addressing Modes
| Mode | Syntax | Bytes | Notes |
|------|--------|-------|-------|
| **IMP** | `INC A` | 2 | opcode + reg |
| **IMM** | `LD A, #$7F` | 3 | reg + literal |
| **DIR** | `ST B, $80` | 3 | reg + zero‑page addr |
| **REG** | `ADD A, B` | 3 | reg + reg |
| **REL** | `BRA loop` | 2 | PC‑relative ±128 |

### Opcode Reference
*(Full table in PDF companion)*

| Mnemonic | Modes | Summary |
|----------|-------|---------|
| `LD` | IMM, DIR | Load reg |
| `ST` | DIR | Store reg |
| `ADD/SUB/AND/OR/XOR` | REG | Two‑operand ALU |
| `INC/DEC` | IMP | Single‑reg ALU |
| `BRA/BNE/BEQ` | REL | Relative branch |

## Development Workflow

### Using the GUI
1. Write or import `.asm` source.  
2. **Assemble** — generates a binary in `ROM Programs/build/`.  
3. **Compile & Simulate** — invokes Icarus & opens GTKWave.  
4. Toggle live debug check‑boxes (`PC`, `IR`, registers, state machine) to step through execution.

### Command Line
See [Quick Start](#quick-start) for the one‑liner sequence, or pass `+` arguments to the testbench, for example:

```bash
vvp -n build/tb.out     +ROMFILE=build/fibo.bin     +TESTNAME=Fibonacci     +CYCLES=2000     +DEBUG_PC +DEBUG_IR +DEBUG_REGS
```

## Simulation & Debugging

The testbench exposes internal signals as VCD for post‑hoc inspection **and** prints human‑readable traces during execution.

Key GTKWave signals:
* `PC`, `IR` — instruction flow  
* `Reg_A…Reg_D` — working registers  
* `io_data`, `io_we` — external interface  
* `dut.cpu1.control_unit1.state` — current FSM state

Enable targeted logging with plusargs:

| Flag | Effect |
|------|--------|
| `+DEBUG_PC` | Print PC each cycle |
| `+DEBUG_STATE` | Decode FSM to mnemonic |
| `+DEBUG_MEM` | Show RAM writes |

## Sample Programs

### LED Blink
Toggles bit‑0 of `$F0` at ~1 kHz.

```assembly
start:  LD A, #$01
loop:   ST A, $F0      ; LED on
        LD A, #$00
        ST A, $F0      ; LED off
        BRA loop
```

## Prerequisites & Installation

| Tool | Version | Purpose |
|------|---------|---------|
| Python | 3.7+ | assembler, GUI |
| PyQt6 | latest | GUI |
| Icarus Verilog | 11+ | simulation |
| GTKWave | 3.3+ | waveform viewer |

On Windows:

```powershell
choco install python iverilog gtkwave
pip install PyQt6 click
```

## Roadmap (Want to add)
* **Add more operations, and conditional branches** (`MUL`, `JMP`, `BPL`, etc.)  
* **Write synthesis constraints** for an entry‑level FPGA board (IceBreaker)  

Contributions & bug reports welcome!

---
