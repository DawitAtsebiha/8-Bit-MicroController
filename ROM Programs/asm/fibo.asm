; seeds
        LDA   #$00          ; F0
        STAA  $80
        STAA  $F0  
        
        LDA   #$01          ; F1
        STAA  $81
        STAA  $F0           ; Outputs current F to I/O port 0

; F2 ­–­­ F14 -----------------------------------------------------------
        LDA   #$00          ; F2 = 0+1
        LDAB  #$01
        ADD
        STAA  $82
        STAA  $F0          

        LDA   #$01          ; F3 = 1+1
        LDAB  #$01
        ADD
        STAA  $83
        STAA  $F0          

        LDA   #$01          ; F4 = 1+2
        LDAB  #$02
        ADD
        STAA  $84
        STAA  $F0           

        LDA   #$02          ; F5 = 2+3
        LDAB  #$03
        ADD
        STAA  $85
        STAA  $F0           

        LDA   #$03          ; F6 = 3+5
        LDAB  #$05
        ADD
        STAA  $86
        STAA  $F0           

        LDA   #$05          ; F7 = 5+8
        LDAB  #$08
        ADD
        STAA  $87
        STAA  $F0           

        LDA   #$08          ; F8 = 8+13
        LDAB  #$0D
        ADD
        STAA  $88
        STAA  $F0      

        LDA   #$0D          ; F9 = 13+21
        LDAB  #$15
        ADD
        STAA  $89
        STAA  $F0          

        LDA   #$15          ; F10 = 21+34
        LDAB  #$22
        ADD
        STAA  $8A
        STAA  $F0        

        LDA   #$22          ; F11 = 34+55
        LDAB  #$37
        ADD
        STAA  $8B
        STAA  $F0         

        LDA   #$37          ; F12 = 55+89
        LDAB  #$59
        ADD
        STAA  $8C
        STAA  $F0        

        LDA   #$59          ; F13 = 89+144
        LDAB  #$90
        ADD
        STAA  $8D
        STAA  $F0         

        LDA   #$90          ; F14 = 144+233 (wrap 121)
        LDAB  #$E9
        ADD
        STAA  $8E
        STAA  $F0        

; halt
DONE:   BRA   DONE          ; 20 FE
