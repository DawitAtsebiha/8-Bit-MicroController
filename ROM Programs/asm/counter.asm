LDA  #$10           ; Start at 16 (so first decrement gives 15)
        
count_down_loop:
        DECA            ; Decrement first
        STAA $F0        ; Output current count
        
        ; Check if we've reached 0
        LDAB #$01       ; Load 1 into B
        SUB             ; A = A - 1
        BEQ  reset_down ; If A was 1 (now 0), reset
        
        ; Restore A and continue
        LDAB #$01       ; Load 1 into B
        ADD             ; A = A + 1 (restore)
        BRA  count_down_loop
        
reset_down:
        LDA  #$10       ; Reset to 16
        BRA  count_down_loop