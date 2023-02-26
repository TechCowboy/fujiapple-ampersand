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

STR_X:          .ASCIIZ " X:"
STR_Y:          .ASCIIZ " Y:"
STR_A:          .ASCIIZ " A:"
STR_P:          .ASCIIZ " P:"


TEMP_A:         .BYTE 1
TEMP_X:         .BYTE 1
TEMP_Y:         .BYTE 1

TEMP_P:         .BYTE 1
TEMP_AND:       .BYTE 1
TEMP_CHAR:      .BYTE 1


PRINT_FLAG:
        PHA

        STX TEMP_CHAR
        STY TEMP_AND
        
        AND #$80
        BNE FLAG_SET
        LDA TEMP_CHAR
        CLC
        BCC PRINT_FLAG_DONE
FLAG_SET:
        AND #$3F                ; MAKE IT INVERSE
     
PRINT_FLAG_DONE:
        JSR COUT
        PLA
        RTS

PRINT_FLAGS:
        LDA #<STR_P
        LDY #>STR_P
        JSR STROUT
        LDA TEMP_P      ; Load accumulator with contents of $0018

        TAX
        JSR PRTX
        LDA #' '
        JSR COUT

        LDA #$80
        LDX #'N'
        LSR
        JSR PRINT_FLAG

        LDX #'V'
        LSR
        JSR PRINT_FLAG

        LDX #'.'
        LSR
        JSR PRINT_FLAG

        LDX #'B'
        LSR
        JSR PRINT_FLAG

        LDX #'D'
        LSR
        JSR PRINT_FLAG

        LDX #'I'
        LSR
        JSR PRINT_FLAG

        LDX #'Z'
        LSR
        JSR PRINT_FLAG

        LDX #'C'
        LSR
        JSR PRINT_FLAG

        RTS

PRINT_REGS:
        PHP
        
        STA TEMP_A

        PLA             ; GET THE PROCESSOR FLAG
        PHA

        LDA #$80
        STA TEMP_P
        
        STX TEMP_X
        STY TEMP_Y

        SAVE_REGS
        LDA #<STR_A
        LDY #>STR_A
        JSR STROUT
        LDX TEMP_A
        JSR PRTX
        
        LDA #<STR_X
        LDY #>STR_X
        JSR STROUT
        LDX TEMP_X
        JSR PRTX
        
        LDA #<STR_Y
        LDY #>STR_Y
        JSR STROUT
        LDX TEMP_Y
        JSR PRTX
        
;        JSR PRINT_FLAGS

        JSR CROUT
        RESTORE_REGS
        
        PLP
        
        RTS

