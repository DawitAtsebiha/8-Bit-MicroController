LDA  #$10     ; A = 16
LDAB #$00     ; B = 0

loop:
    DECA      ; A = A + 1
    INCB      ; B = B + 1
    STAA $F0  ; Output A value
    STAB $F0  ; Output B value
    BRA loop  ; Go back to loop