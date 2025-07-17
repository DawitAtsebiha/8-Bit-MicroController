; Test 1: Basic Load/Store
LDA  #$42     ; A = 66
STAA $F0      ; Output: 66 (0x42)

; Test 2: Arithmetic
LDA  #$08     ; A = 8
LDAB #$03     ; B = 3
ADD           ; A = 11
STAA $F0      ; Output: 11 (0x0B)

; Test 3: Logical Operations
LDA  #$0F     ; A = 15
LDAB #$F0     ; B = 240
BOR           ; A = 255
STAA $F0      ; Output: 255 (0xFF)

; Test 4: Critical Branch Test (BEQ)
LDA  #$05     ; A = 5
LDAB #$05     ; B = 5
SUB           ; A = 0 (Zero flag set)
BEQ branch_success
LDA  #$FF     ; Error - should not reach here
STAA $F0

branch_success:
LDA  #$99     ; Success marker
STAA $F0      ; Output: 153 (0x99) - CRITICAL TEST PASSED

; Test 5: Loop Control (BNE)
LDA  #$03     ; Counter = 3
loop:
STAA $F0      ; Output: 3, 2, 1
DECA          ; Decrement
BNE loop      ; Loop while not zero

; Test 6: Unconditional Branch (BRA)
BRA final_test
LDA  #$FF     ; Should be skipped
STAA $F0

final_test:
LDA  #$AA     ; Test complete marker
STAA $F0      ; Output: 170 (0xAA)

; Program end
DONE: BRA DONE
