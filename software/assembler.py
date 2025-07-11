"""assembly.py
Self‑contained command‑line assembler for the 8‑bit MicroController.

New in this revision
────────────────────
• **Implied‑operand instructions** (`ADD`, `SUB`, `AND`, `OR`, `INC`, `DEC`) now assemble (1‑byte op‑codes).
• `_classify_operand` recognises the *absence* of an operand when the mnemonic supports `IMP` mode instead of raising "missing operand".
• Added nicer fallback when pass‑1 errors occur: real line numbers are always reported.

Usage
─────
$ python mini8_assembler.py assemble prog.asm -o rom.bin
"""
from __future__ import annotations

import pathlib, re, sys
from dataclasses import dataclass
from typing import Dict, List, Tuple

import click

# ────────────────────────────────────────────────────────────
# 1.  ISA description
# ────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class Opcode:
    code: int
    size: int   # bytes (1 or 2)
    mode: str   # "IMP", "IMM", "DIR", "REL"

def _op(code: int, mode: str) -> Opcode:
    return Opcode(code, 1 if mode == "IMP" else 2, mode)

BRANCHES = {"BRA", "BNE", "BEQ"}

OPCODES: Dict[Tuple[str, str], Opcode] = {
    # Immediate / direct loads & stores
    ("LDA",  "IMM"): _op(0x86, "IMM"),
    ("LDAB", "IMM"): _op(0x88, "IMM"),
    ("LDA",  "DIR"): _op(0xB6, "DIR"),
    ("LDAB", "DIR"): _op(0xB7, "DIR"),
    ("STAA", "DIR"): _op(0x96, "DIR"),
    ("STAB", "DIR"): _op(0x97, "DIR"),

    # Branches (relative)
    ("BRA", "REL"): _op(0x20, "REL"),
    ("BNE", "REL"): _op(0x26, "REL"),
    ("BEQ", "REL"): _op(0x27, "REL"),

    # ALU implied‑operand instructions
    ("ADD", "IMP"): _op(0x42, "IMP"),
    ("SUB", "IMP"): _op(0x43, "IMP"),
    ("AND", "IMP"): _op(0x44, "IMP"),
    ("OR",  "IMP"): _op(0x45, "IMP"),
    ("INC", "IMP"): _op(0x46, "IMP"),
    ("DEC", "IMP"): _op(0x48, "IMP"),
}

# regex helpers
HEX_BYTE  = re.compile(r"^\$([0-9A-Fa-f]{1,2})$")
HEX_IMM   = re.compile(r"^#\$([0-9A-Fa-f]{1,2})$")
LABEL_RE  = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
EQU_RE    = re.compile(r"^(\w+)\s+EQU\s+\$([0-9A-Fa-f]{1,2})$")

class AsmError(RuntimeError):
    pass

# ────────────────────────────────────────────────────────────
# 2.  Helpers
# ────────────────────────────────────────────────────────────

def _split_label(line: str) -> Tuple[str | None, str | None]:
    if ':' not in line:
        return None, line.strip() or None
    lab, rest = line.split(':', 1)
    return lab.strip(), rest.strip() or None

# ────────────────────────────────────────────────────────────
# 3.  Two‑pass assembler
# ────────────────────────────────────────────────────────────

def assemble(lines: List[str]) -> bytes:
    """Convert source lines to ROM image (bytes)."""
    src = [ln.split(';', 1)[0].rstrip() for ln in lines]

    # pass‑1: label + constant table
    labels: Dict[str, int] = {}
    pc = 0
    for line_no, ln in enumerate(src, 1):
        lab, inst = _split_label(ln)
        # EQU pseudo‑op
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
            continue
        mnem, *ops = inst.split()
        mode, _ = _determine_mode(mnem, ops, labels, line_no)
        pc += _lookup(mnem, mode, line=line_no).size

    # pass‑2: emit code
    rom: List[int] = []
    pc = 0
    for line_no, ln in enumerate(src, 1):
        lab, inst = _split_label(ln)
        if not inst or EQU_RE.match(inst):
            continue
        mnem, *ops = inst.split()
        mode, op_val = _determine_mode(mnem, ops, labels, line_no)
        opc = _lookup(mnem, mode, line=line_no)
        rom.append(opc.code); pc += 1
        if mode == "IMM" or mode == "DIR":
            rom.append(op_val)
        elif mode == "REL":
            off = (-2 & 0xFF) if op_val == "*" else (labels[op_val] - (pc + 1)) & 0xFF
            rom.append(off)
        pc = len(rom)
    return bytes(rom)

# ────────────────────────────────────────────────────────────
# 4.  Operand classification
# ────────────────────────────────────────────────────────────

def _determine_mode(mnem: str, ops: List[str], labels: Dict[str, int], line: int):
    """Return (mode, value_or_symbol). value is int for IMM/DIR."""
    mnem_u = mnem.upper()
    if not ops:
        if (mnem_u, "IMP") in OPCODES:
            return "IMP", None
        raise AsmError(f"Line {line}: missing operand")

    token = ops[0]

    # BRA *  (branch to self)
    if token == "*":
        return "REL", token

    if (m := HEX_IMM.match(token)):
        return "IMM", int(m.group(1), 16)
    if (m := HEX_BYTE.match(token)):
        return "DIR", int(m.group(1), 16)

    if LABEL_RE.match(token):
        if mnem_u in BRANCHES:
            return "REL", token
        if token not in labels:
            raise AsmError(f"Line {line}: unknown symbol '{token}'")
        return "DIR", labels[token]

    raise AsmError(f"Line {line}: malformed operand '{token}'")(f"Line {line}: missing operand")

    token = ops[0]

    if (m := HEX_IMM.match(token)):
        return "IMM", int(m.group(1), 16)
    if (m := HEX_BYTE.match(token)):
        return "DIR", int(m.group(1), 16)
    if LABEL_RE.match(token):
        if mnem_u in BRANCHES or token == "*":
            return "REL", token
        if token not in labels:
            raise AsmError(f"Line {line}: unknown symbol '{token}'")
        return "DIR", labels[token]
    raise AsmError(f"Line {line}: malformed operand '{token}'")


def _lookup(mnem: str, mode: str, *, line: int):
    key = (mnem.upper(), mode)
    if key not in OPCODES:
        raise AsmError(f"Line {line}: {mnem} does not support {mode} addressing")
    return OPCODES[key]

# ────────────────────────────────────────────────────────────
# 5.  CLI entry‑points
# ────────────────────────────────────────────────────────────

@click.group()
def cli():
    """8‑bit CPU utility suite — assembler only."""


@cli.command("assemble")
@click.argument("asm_path", type=click.Path(dir_okay=False, exists=True))
@click.option("--out", "-o", default="rom.bin", show_default=True, help="Output ROM binary")
def assemble_cmd(asm_path: str, out: str):
    lines = pathlib.Path(asm_path).read_text(encoding="utf-8").splitlines()
    try:
        rom = assemble(lines)
    except AsmError as e:
        click.echo(f"Assembler error: {e}", err=True)
        sys.exit(1)
    pathlib.Path(out).write_bytes(rom)
    click.echo(f"[assembler] wrote {len(rom)} bytes → {out}")


if __name__ == "__main__":
    cli()
