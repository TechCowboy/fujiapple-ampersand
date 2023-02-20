
        .include "ZEROPAGE.S"

STAT_LIST:
        .BYTE   $03         ; PCOUNT ?
        .BYTE   $00         ; DEVICE
        .WORD   STAT_DATA  ; DATA RETURN HERE
        .BYTE   $00         ; GET HOST STATUS CALL

STAT_DATA:
        .WORD   $00

SMARTPORT_DISPATCHER: 
DISPATCHER_ADDR_LO:
        .BYTE $00
DISPATCHER_ADDR_HI:
        .BYTE $00


SLOT_ADDR		=	ZP2
SLOT_ADDR_LO	    	=	ZP2_LO
SLOT_ADDR_HI		=	ZP2_HI


;*******************************
; FIND_SMARTPORT_SLOT
; INPUT:
;   NONE
;***
; RETURN
;   A = $FF - NO SMARTPORT FOUND
;   A = $CX - WHERE X IS THE SLOT
;**********************************

FIND_SMARTPORT_SLOT:

        LDA     #$C7            ; START AT SLOT 7 ($C700)
        STA     SLOT_ADDR_HI
        LDA     #$00
        STA     SLOT_ADDR_LO

SCAN:
        LDY #$01                ; LOOK AT BYTES 1,3,5,AND 7
        LDX #$00

NEXT_MATCH:
        LDA (SLOT_ADDR),Y       ; COMPARE TO THE MAGIC NUMBERS
        CMP FIJINET_ID,X        ; 
        BNE NEXT_SLOT           ; NOT THE SAME, SO GO TO NEXT SLOT

        INY                     ; PREPARE TO CHECK THE NEXT NUMBER
        INY
        INX                     ; POINTER TO NEXT NUMBER TO CHECK
        CPX #$04                ; HAVE WE COMPARED ALL 4 NUMBERS?
        BEQ FOUND               ; YES, WE'VE FOUND IT
        BNE NEXT_MATCH          ; MORE TO MATCH

NEXT_SLOT:
        LDX SLOT_ADDR_HI        ; MOVE TO THE NEXT LOWER SLOT
        DEX                     ; $C700 -> $C600
        STX SLOT_ADDR_HI
        CPX #$C0                ; HAVE WE GONE BELOW SLOT 1?
        BEQ NOT_FOUND           ; WE'RE DONE
        BNE SCAN                ; CONTINUE SCANNING
FOUND:
        LDA SLOT_ADDR_HI
        RTS                     ; WE FOUND IT! A = SLOT ADDRESS

NOT_FOUND:
        LDA #$FF                ; WE DIDN'T FIND IT
        RTS
        
FIJINET_ID:     .BYTE $20, $00, $03, $00 

;*******************************
; GET_SMARTPORT_DISPATCH_ADDRESS
; INPUT:
;   NONE
;***
; RETURN
;   -A DISPATCHER ADDRESS HIGH
;   -X DISPATCHER ADDRESS LOW
; OR A AND X WILL BE SET TO $FF
; IF DISPATCHER NOT FOUND
;**********************************

GET_SMARTPORT_DISPATCH_ADDRESS:
        JSR FIND_SMARTPORT_SLOT 
        CMP #$FF                ; IF A == $FF THEN NOT FOUND
        BEQ NO_DISPATCHER

        STA DISPATCHER_ADDR_HI  ; A = $CX WHERE X IS THE SLOT
        LDA #$00
        STA DISPATCHER_ADDR_LO  ; COMPLETE ADDRESS IS $CX00
        
        LDY #$FF
        LDA (SLOT_ADDR),Y        ; j= peek(a+0xFF)
        CLC
        ADC DISPATCHER_ADDR_LO   ; DISPATCHER_ADDR += J
        STA DISPATCHER_ADDR_LO

        LDA DISPATCHER_ADDR_HI
        ADC #$00
        STA DISPATCHER_ADDR_HI

        CLC                     ; DISPATCHER_ADDR += 3
        LDA DISPATCHER_ADDR_LO
        ADC #$03
        STA DISPATCHER_ADDR_LO
        
        LDA DISPATCHER_ADDR_HI
        ADC #$00
        STA DISPATCHER_ADDR_HI

        LDA DISPATCHER_ADDR_HI  ; PUT ADDRESS IN A AND X
        LDX DISPATCHER_ADDR_LO
        CLC
        BCC DONE

NO_DISPATCHER:
        LDA #$FF                ; NO ADDRESS FOUND
        LDX #$FF

DONE:        
        RTS


SP_STATUS:  
        JSR CALL_DISPATCHER
        .BYTE $00           ; STATUS CALL COMMAND NUMBER
        .WORD STAT_LIST

        LDA STAT_DATA+2     ; LOW BYTE OF VENDER ID
        LDA STAT_DATA+3     ; HIGH BYTE OF VENDER ID
        LDA STAT_DATA+4     ; LOW BYTE OF VERSION
        LDA STAT_DATA+5     ; HIGH BYTE OF VERSION
        RTS

CALL_DISPATCHER:
        JMP (SMARTPORT_DISPATCHER)

