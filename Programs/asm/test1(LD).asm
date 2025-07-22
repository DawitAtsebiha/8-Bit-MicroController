// Test 1: Load Operations Only
// Tests all LD immediate instructions

LD A, #$10        // Load A with 0x10 (16)
LD B, #$05        // Load B with 0x05 (5)
LD C, #$0F        // Load C with 0x0F (15)
LD D, #$F0        // Load D with 0xF0 (240)
LD E, #$0F        // Load E with 0x0F (15)
LD F, #$05        // Load F with 0x05 (5)
LD G, #$42        // Load G with 0x42 (66)
LD H, #$41        // Load H with 0x41 (65)
LD I, #$FF        // Load I with 0xFF (255)
LD J, #$AA        // Load J with 0xAA (170)
LD K, #$01        // Load K with 0x01 (1)
LD L, #$FF        // Load L with 0xFF (255)
LD M, #$00        // Load M with 0x00 (0)
LD N, #$33        // Load N with 0x33 (51)
LD O, #$55        // Load O with 0x55 (85)
LD P, #$99        // Load P with 0x99 (153)

// Expected Results:
// A=10 B=05 C=0f D=f0 E=0f F=05 G=42 H=41
// I=ff J=aa K=01 L=ff M=00 N=33 O=55 P=99