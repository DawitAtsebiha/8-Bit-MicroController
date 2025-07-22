// Test 4: Branch Operations - SIMPLIFIED VERSION
// Tests BEQ and BNE instructions with minimal program

// Simple decrement loop test  
LD F, #$03        // Load F with 3 (smaller number for easier debugging)

LOOP:
    DEC F         // Decrement F  
    BNE LOOP      // Branch back if F != 0 (should loop 3 times)

// After loop, F should be 0
LD A, #$11        // Mark that we exited loop successfully

// Simple equality test
LD G, #$42        // Load G with 0x42
LD H, #$42        // Load H with 0x42  
SUB G, H          // G = G - H = 0 (should set zero flag)
BEQ SUCCESS       // Branch if equal (zero flag set)

// Should NOT reach here if BEQ works
LD B, #$FF        // Error - BEQ didn't work

SUCCESS:
    LD C, #$AA        // Success - BEQ worked

// Final completion marker
LD P, #$99        // Program completed

// Expected Results if branches work correctly:
// A=11 B=00 C=aa D=00 E=00 F=00 G=00 H=42
// I=00 J=00 K=00 L=00 M=00 N=00 O=00 P=99

// Expected Results if branches DON'T work (sequential execution):
// A=11 B=ff C=aa D=00 E=00 F=02 G=00 H=42
// I=00 J=00 K=00 L=00 M=00 N=00 O=00 P=99