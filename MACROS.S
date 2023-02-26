.IF .NOT .DEFINED(PRINT_X)

.MACRO SAVE_REGS
        PHP
        PHA
        TXA
        PHA
        TYA
        PHA
.ENDMACRO

.MACRO RESTORE_REGS
        PLA
        TAY
        PLA
        TAX
        PLA
        PLP
.ENDMACRO

.MACRO PRINT_STR STR
        LDA STR
        LDY STR+1
        JSR STROUT
.ENDMACRO

PRINT_X:
        JSR PRTX
        LDA #' '
        JSR COUT
        RTS
.ENDIF

