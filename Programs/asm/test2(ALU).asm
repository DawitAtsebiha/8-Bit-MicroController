// Test 2: Arithmetic Operations
// Tests ADD and SUB instructions

LD A, #$10        // Load A with 16
LD B, #$05        // Load B with 5
LD C, #$0F        // Load C with 15

// Addition Operations  
ADD A, B          // A = 16 + 5 = 21 (0x15)
ADD A, C          // A = 21 + 15 = 36 (0x24)

// Subtraction Operations
SUB A, B          // A = 36 - 5 = 31 (0x1F)  
SUB A, C          // A = 31 - 15 = 16 (0x10)

// Register Chain Operations
LD K, #$01        // Load K with 1
ADD K, K          // K = 1 + 1 = 2
ADD K, K          // K = 2 + 2 = 4  
ADD K, K          // K = 4 + 4 = 8
ADD K, K          // K = 8 + 8 = 16

// Equality Test  
LD G, #$42        // Load G with 0x42
LD H, #$42        // Load H with 0x42  
SUB G, H          // G = 0x42 - 0x42 = 0x00

// Logical Operations
LD D, #$F0        // Load D with 0xF0
LD E, #$0F        // Load E with 0x0F
AND D, E          // D = 0xF0 & 0x0F = 0x00
OR  D, A          // D = 0x00 | 0x10 = 0x10
XOR D, A          // D = 0x10 ^ 0x10 = 0x00

// Complex Expression
LD N, #$33        // Load N with 0x33
LD O, #$55        // Load O with 0x55
XOR N, O          // N = 0x33 ^ 0x55 = 0x66
AND N, O          // N = 0x66 & 0x55 = 0x44

// Expected Results:
// A=10 B=05 C=0f D=00 E=0f F=00 G=00 H=42
// I=00 J=00 K=10 L=00 M=00 N=44 O=55 P=00