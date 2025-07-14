; seeds ----------------------------------------------------------------
        LDA   #$00          ; F0
        STAA  $80
        LDA   #$01          ; F1
        STAA  $81

; F2 ­–­­ F14 -----------------------------------------------------------
        LDA   #$00          ; F2 = 0+1
        LDAB  #$01
        ADD
        STAA  $82

        LDA   #$01          ; F3 = 1+1
        LDAB  #$01
        ADD
        STAA  $83

        LDA   #$01          ; F4 = 1+2
        LDAB  #$02
        ADD
        STAA  $84

        LDA   #$02          ; F5 = 2+3
        LDAB  #$03
        ADD
        STAA  $85

        LDA   #$03          ; F6 = 3+5
        LDAB  #$05
        ADD
        STAA  $86

        LDA   #$05          ; F7 = 5+8
        LDAB  #$08
        ADD
        STAA  $87

        LDA   #$08          ; F8 = 8+13
        LDAB  #$0D
        ADD
        STAA  $88

        LDA   #$0D          ; F9 = 13+21
        LDAB  #$15
        ADD
        STAA  $89

        LDA   #$15          ; F10 = 21+34
        LDAB  #$22
        ADD
        STAA  $8A

        LDA   #$22          ; F11 = 34+55
        LDAB  #$37
        ADD
        STAA  $8B

        LDA   #$37          ; F12 = 55+89
        LDAB  #$59
        ADD
        STAA  $8C

        LDA   #$59          ; F13 = 89+144
        LDAB  #$90
        ADD
        STAA  $8D

        LDA   #$90          ; F14 = 144+233 (wrap 121)
        LDAB  #$E9
        ADD
        STAA  $8E

; halt -----------------------------------------------------------------
DONE:   BRA   DONE          ; 20 FE
