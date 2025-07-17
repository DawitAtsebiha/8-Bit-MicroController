        LDA  #$00      ; Load pattern 1 (LED OFF)
loop:
        STAA $F0       ; Output to LED port
        LDA  #$01      ; Reload A (creates a delay cycle)
        STAA $F0       
        LDA  #$00   
        BRA  loop      ; Continue blinking until simulation is terminated