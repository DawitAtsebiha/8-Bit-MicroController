// Test 3: Increment/Decrement Operations
// Tests INC and DEC instructions

LD A, #$10        // Load A with 0x10 (16)
LD B, #$05        // Load B with 0x05 (5)
LD F, #$05        // Load F with 0x05 (5)

// Increment Operations
INC A             // A = 0x10 + 1 = 0x11
INC A             // A = 0x11 + 1 = 0x12
INC A             // A = 0x12 + 1 = 0x13

// Decrement Operations
DEC B             // B = 0x05 - 1 = 0x04
DEC B             // B = 0x04 - 1 = 0x03
DEC B             // B = 0x03 - 1 = 0x02

// Decrement to Zero Test
DEC F             // F = 0x05 - 1 = 0x04
DEC F             // F = 0x04 - 1 = 0x03
DEC F             // F = 0x03 - 1 = 0x02
DEC F             // F = 0x02 - 1 = 0x01
DEC F             // F = 0x01 - 1 = 0x00

// Boundary Value Tests
LD L, #$FF        // Load L with 255
INC L             // L = 255 + 1 = 0 (overflow)

LD M, #$00        // Load M with 0
DEC M             // M = 0 - 1 = 255 (underflow)

// Expected Results:
// A=13 B=02 C=00 D=00 E=00 F=00 G=00 H=00
// I=00 J=00 K=00 L=00 M=ff N=00 O=00 P=00