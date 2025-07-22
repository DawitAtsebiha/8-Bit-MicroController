// Minimal branch test
LD A, #$42        // Load A with 0x42 (sets A=42)

LOOP:
BRA LOOP          // Should jump back to LOOP infinitely

// Expected behavior: Program should loop infinitely at LOOP
// If working: A=42, PC jumps between BRA instruction and LOOP
// If broken: A=42, but PC goes to wrong address
