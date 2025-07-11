;---------- seeds -------------------------------------------
        LDA     #$00        ; F0
        STAA    $80
        LDAB    #$01        ; F1
        STAB    $81

        LDA     #$00        ; A = F(n-1)
        LDAB    #$01        ; B = F(n)

; ---------- temporary scratchpad at $FE ----------------------
temp    EQU     $FE         ; holds the *previous* A each step

; ---------- F2 ------------------------------------------------
        STAA    temp        ; save old A
        ADD                 ; A = A + B  = 1
        STAA    $82         ; store F2
        LDAB    temp        ; B = old A  = 0

; ---------- F3 ------------------------------------------------
        STAA    temp
        ADD                 ; 1 + 0 = 1
        STAA    $83
        LDAB    temp

; ---------- F4 ------------------------------------------------
        STAA    temp
        ADD                 ; 1 + 1 = 2
        STAA    $84
        LDAB    temp

; ---------- F5 ------------------------------------------------
        STAA    temp
        ADD                 ; 2 + 1 = 3
        STAA    $85
        LDAB    temp

; ---------- F6 ------------------------------------------------
        STAA    temp
        ADD                 ; 3 + 2 = 5
        STAA    $86
        LDAB    temp

; ---------- F7 ------------------------------------------------
        STAA    temp
        ADD                 ; 5 + 3 = 8
        STAA    $87
        LDAB    temp

; ---------- F8 ------------------------------------------------
        STAA    temp
        ADD                 ; 8 + 5 = 13
        STAA    $88
        LDAB    temp

; ---------- F9 ------------------------------------------------
        STAA    temp
        ADD                 ; 13 + 8 = 21
        STAA    $89
        LDAB    temp

; ---------- F10 ----------------------------------------------
        STAA    temp
        ADD                 ; 21 + 13 = 34
        STAA    $8A
        LDAB    temp

; ---------- F11 ----------------------------------------------
        STAA    temp
        ADD                 ; 34 + 21 = 55
        STAA    $8B
        LDAB    temp

; ---------- F12 ----------------------------------------------
        STAA    temp
        ADD                 ; 55 + 34 = 89
        STAA    $8C
        LDAB    temp

; ---------- F13 ----------------------------------------------
        STAA    temp
        ADD                 ; 89 + 55 = 144
        STAA    $8D
        LDAB    temp

; ---------- F14 ----------------------------------------------
        STAA    temp
        ADD                 ; 144 + 89 = 233
        STAA    $8E
        LDAB    temp

; ---------- F15 ----------------------------------------------
        STAA    temp
        ADD                 ; 233 + 144 = 121 (8-bit wrap!)
        STAA    $8F
        ; No need to shift B any further — sequence is done

; ---------- finished -----------------------------------------
done:   BRA     *        ; park CPU
