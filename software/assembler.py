"""
assembly.py
Self-contained command-line assembler for the 8-But MightyController.

New in this revision
────────────────────
• Support for parameterized instructions (LD reg, operand)
• 3-byte instruction format for multi-register operations
• Scalable register system

Usage
─────
$ python assembly.py assemble prog.asm -o rom.bin
"""
from __future__ import annotations

import pathlib, re, sys
from dataclasses import dataclass
from typing import Dict, List, Tuple

import click

# 1.  ISA setup
@dataclass(frozen=True)
class Opcode:
    code: int
    size: int          
    mode: str           # "IMP", "IMM", "DIR", "REL"

def _op(code: int, mode: str, size: int = None) -> Opcode:
    # Size for operations determined by mode:
    if size is None:
        size_map = {
            "IMP": 2,   # Opcode + register (ex. INC A)
            "IMM": 3,   # Opcode + register + immediate (ex: LD A, #$50)
            "DIR": 3,   # Opcode + register + address (ex: LD A, $80)
            "REG": 3,   # Opcode + reg1 + reg2 (ex: ADD A, B)
            "REL": 2    # Opcode + offset (ex: BRA loop)
        }
        size = size_map.get(mode, 2)  # Default to 2 for ALU ops

    return Opcode(code, size, mode)

REGISTERS = {
    "A": 0, "B": 1, "C": 2, "D": 3,
    "E": 4, "F": 5, "G": 6, "H": 7,
    "I": 8, "J": 9, "K": 10, "L": 11,
    "M": 12, "N": 13, "O": 14, "P": 15
}

OPCODES: Dict[Tuple[str, str], Opcode] = {
    # Load/Store operations
    ("LD",  "IMM"): _op(0x80, "IMM"),
    ("LD",  "DIR"): _op(0x81, "DIR"),
    ("ST",  "DIR"): _op(0x82, "DIR"),

    # Branches (relative)
    ("BRA", "REL"): _op(0x20, "REL"),
    ("BNE", "REL"): _op(0x23, "REL"),
    ("BEQ", "REL"): _op(0x24, "REL"),

    #ALU Single-register data operations  
    ("INC", "IMP"): _op(0xA0, "IMP"),        
    ("DEC", "IMP"): _op(0xA1, "IMP"), 

    # ALU Two-register data operations
    ("ADD", "REG"): _op(0x90, "REG"),
    ("SUB", "REG"): _op(0x91, "REG"),
    ("AND", "REG"): _op(0x92, "REG"),
    ("OR",  "REG"): _op(0x93, "REG"),
    ("XOR", "REG"): _op(0x94, "REG"),
}

BRANCHES = {"BRA", "BNE", "BEQ", "BCC", "BCS", "BPL", "BMI", "BVC", "BVS"}

# regex helpers
HEX_BYTE  = re.compile(r"^\$([0-9A-Fa-f]{1,2})$")
HEX_IMM   = re.compile(r"^#\$([0-9A-Fa-f]{1,2})$")
LABEL_RE  = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
EQU_RE    = re.compile(r"^(\w+)\s+EQU\s+\$([0-9A-Fa-f]{1,2})$")

class AsmError(RuntimeError):
    pass

# 2.  Helpers
def _split_label(line: str) -> Tuple[str | None, str | None]:
    if ':' not in line:
        return None, line.strip() or None
    lab, rest = line.split(':', 1)
    return lab.strip(), rest.strip() or None

def _parse_instruction(inst: str) -> Tuple[str, List[str]]:
    """Parse instruction into mnemonic and operands."""
    parts = inst.split()
    if not parts:
        return "", []
    
    mnem = parts[0]
    if len(parts) == 1:
        return mnem, []
    
    # Join remaining parts and split by comma for multi-operand instructions
    operand_str = ' '.join(parts[1:])
    operands = [op.strip() for op in operand_str.split(',')]  # Split by comma and strip whitespace
    return mnem, operands

# 3.  Two-pass assembler
def assemble(lines: List[str]) -> bytes:
    # Convert source lines to a ROM image (byte string).
    src = [ln.split(';', 1)[0].rstrip() for ln in lines]  # strip comments

    # pass-1: collect labels / constants, compute PC
    labels: Dict[str, int] = {}
    pc = 0
    for line_no, ln in enumerate(src, 1):
        lab, inst = _split_label(ln)

        # EQU pseudo-op
        if inst and (m := EQU_RE.match(inst)):
            sym, val = m.group(1), int(m.group(2), 16)
            if sym in labels:
                raise AsmError(f"Line {line_no}: duplicate symbol '{sym}'")
            labels[sym] = val & 0xFF
            continue

        if lab:
            if lab in labels:
                raise AsmError(f"Line {line_no}: duplicate label '{lab}'")
            labels[lab] = pc

        if not inst:
            continue  # blank line or label-only

        mnem, ops = _parse_instruction(inst)
        mode, _ = _determine_mode(mnem, ops, labels, line_no)
        pc += _lookup(mnem, mode, line=line_no).size

    # pass-2: emit op-codes + operands
    rom: List[int] = []
    pc = 0

    for line_no, ln in enumerate(src, 1):
        lab, inst = _split_label(ln)

        if not inst or EQU_RE.match(inst):
            continue

        mnem, ops = _parse_instruction(inst)
        mode, op_val = _determine_mode(mnem, ops, labels, line_no)
        opc = _lookup(mnem, mode, line=line_no)
        rom.append(opc.code)
        pc += 1

        if mode == "IMP":            # Single register (INC A, DEC B)
            reg_num = op_val
            rom.append(reg_num)

        elif mode == "REG":          # Two registers (ADD A, B)
            reg1_num, reg2_num = op_val
            rom.extend([reg1_num, reg2_num])

        elif mode == "IMM":        # Register + immediate value (LD A, #$3F)
            reg_num, imm_val = op_val
            rom.extend([reg_num, imm_val])

        elif mode == "DIR":        # Register + direct address (LD A, $80)
            reg_num, addr_val = op_val
            rom.extend([reg_num, addr_val])

        elif mode == "REL":        # Relative branch (BRA loop)
            if op_val == "*":
                off = (-1 & 0xFF)

            else:
                target_addr = labels[op_val]
                current_pc = pc + 1  # PC after branch instruction (pc is already incremented)
                offset = target_addr - current_pc
                
                # Check if offset is within valid range (-128 to +127)
                if offset < -128 or offset > 127:
                    raise AsmError(f"Branch target too far: {offset}")
                
                off = offset & 0xFF
            
            rom.append(off)
            
        pc = len(rom)
    return bytes(rom)

# 4.  Operand classification
def _determine_mode(mnem: str, ops: List[str], labels: Dict[str, int], line: int):
    """
    Return (addressing_mode, operand_value_or_symbol).
    For IMM/DIR the value is an int; for REL it is the symbol (or "*").
    """
    mnem_u = mnem.upper()

    # implied-operand (no token)
    if not ops:
        if (mnem_u, "IMP") in OPCODES:
            return "IMP", None
        raise AsmError(f"Line {line}: missing operand")

   # Single operand
    if len(ops) == 1:
        token = ops[0]

        # Register name (for single-register operations)
        if token.upper() in REGISTERS:
            if mnem_u in {"INC", "DEC"}:
                return "IMP", REGISTERS[token.upper()]
            else:
                raise AsmError(f"Line {line}: {mnem_u} does not support single register")
       # Symbol/label
        if LABEL_RE.match(token):
            if mnem_u in BRANCHES:
                return "REL", token
            if token not in labels:
                raise AsmError(f"Line {line}: unknown symbol '{token}'")
            return "DIR", labels[token]

        raise AsmError(f"Line {line}: malformed operand '{token}'")

    # Two operands - NEW PARAMETERIZED FORMAT
    elif len(ops) == 2:
        reg_token = ops[0]
        val_token = ops[1]

        # First operand must be a register
        if reg_token.upper() not in REGISTERS:
            raise AsmError(f"Line {line}: first operand must be a register, got '{reg_token}'")
        
        reg_num = REGISTERS[reg_token.upper()]

        # Second operand determines the addressing mode
        if val_token.upper() in REGISTERS:
            # Register-to-register operation
            reg2_num = REGISTERS[val_token.upper()]
            if mnem_u in {"ADD", "SUB", "AND", "OR", "XOR"}:
                return "REG", (reg_num, reg2_num)
            else:
                raise AsmError(f"Line {line}: {mnem_u} does not support register-to-register")
        
        elif (m := HEX_IMM.match(val_token)):
            # Immediate value
            imm_val = int(m.group(1), 16)
            if mnem_u == "LD":
                return "IMM", (reg_num, imm_val)
            else:
                raise AsmError(f"Line {line}: {mnem_u} does not support immediate addressing")
        
        elif (m := HEX_BYTE.match(val_token)):
            # Direct address
            addr_val = int(m.group(1), 16)
            if mnem_u in {"LD", "ST"}:
                return "DIR", (reg_num, addr_val)
            else:
                raise AsmError(f"Line {line}: {mnem_u} does not support direct addressing")
        
        elif LABEL_RE.match(val_token):
            # Symbol/label for direct addressing
            if val_token not in labels:
                raise AsmError(f"Line {line}: unknown symbol '{val_token}'")
            addr_val = labels[val_token]
            if mnem_u in {"LD", "ST"}:
                return "DIR", (reg_num, addr_val)
            else:
                raise AsmError(f"Line {line}: {mnem_u} does not support direct addressing")
        
        else:
            raise AsmError(f"Line {line}: malformed second operand '{val_token}'")

    else:
        raise AsmError(f"Line {line}: too many operands")

# 5.  Lookup helper
def _lookup(mnem: str, mode: str, *, line: int) -> Opcode:
    key = (mnem.upper(), mode)
    if key not in OPCODES:
        raise AsmError(f"Line {line}: {mnem} does not support {mode} addressing")
    return OPCODES[key]

# 6.  CLI
@click.group()
def cli():
    """8-bit CPU utility suite – assembler only."""

@cli.command("assemble")
@click.argument("asm_path", type=click.Path(dir_okay=False, exists=True))
@click.option("--out", "-o", default=None, show_default=True,
              help="Output ROM binary (defaults to build/<asm_name>.bin)")
def assemble_cmd(asm_path: str, out: str):
    """Assemble ASM_PATH into a raw ROM image."""
    # Auto-generate output path if not specified
    if out is None:
        asm_file = pathlib.Path(asm_path)
        out = f"Programs/build/{asm_file.stem}.bin"
    
    # Ensure Programs/build directory exists
    build_dir = pathlib.Path("Programs/build")
    build_dir.mkdir(parents=True, exist_ok=True)
    
    lines = pathlib.Path(asm_path).read_text(encoding="utf-8").splitlines()
    try:
        rom = assemble(lines)
    except AsmError as e:
        click.echo(f"Assembler error: {e}", err=True)
        sys.exit(1)
    pathlib.Path(out).write_bytes(rom)
    click.echo(f"[assembler] wrote {len(rom)} bytes -> {out}")   # plain ASCII arrow

if __name__ == "__main__":
    cli()
