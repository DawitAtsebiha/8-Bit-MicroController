        LDA  #$01      ; pattern 0000_0001 
loop:
        STAA $F0       ; LED on
        LDA  #$00
        STAA $F0       ; LED off
        BRA  loop      ; forever

        BRA *