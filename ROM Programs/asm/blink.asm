        LDA  #$01      ; Load pattern 1 (LED on)
loop:
        STAA $F0       ; Output to LED port (on)
        LDA  #$01      ; Reload A (creates a delay cycle)
        LDA  #$00     
        STAA $F0       
        LDA  #$00   
        BRA  loop      ; Continue blinking until simulation is terminated