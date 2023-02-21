;*****************************************************
; Smartport Commands
;
; Generic smartport commands for use with Fujinet
; By Norman Davie

; Call GET_SMARTPORT_ADDRESS
; Call FIND_FIJINET

        .include "APPLEEQU.S"
        .include "ZEROPAGE.S"

SP_CMD_STATUS           =       0
SP_CMD_CONTROL          =       4
SP_CMD_OPEN             =       6
SP_CMD_READ             =       8
SP_CMD_WRITE            =       9
SP_STATUS_PARAM_COUNT   =       3
SP_CONTROL_PARAM_COUNT  =       3
SP_OPEN_PARAM_COUNT     =       1
SP_READ_PARAM_COUNT     =       4
SP_WRITE_PARAM_COUNT    =       4




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
                CMP SMARTPORT_ID,X        ; 
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
        
SMARTPORT_ID:   .BYTE $20, $00, $03, $00 

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

;*******************************
; SP_STATUS
;   Get smartport status
; INPUT:
;   X - DESTINATION DEVICE
;   Y - 
;**********************************

CMD_LIST:
CMD_LIST_PCOUNT:.BYTE   $FF             ; PARAMETER COUNT
CMD_LIST_DEST:  .BYTE   $FF             ; DESTINATION DEVICE NUMBER
CMD_LIST_RESULT:.WORD   SP_PAYLOAD      ; DATA RETURN HERE
CMD_LIST_STAT:  .BYTE   $FF             ; STATUS CODE


SP_PAYLOAD:
DCOUNT:         .BYTE   $FF             ; NUMBER OF DEVICES
INTSTATE:       .BYTE   $FF             ; INTERRUPT STATUS (IF BIT 6 IS SET, THEN NO INTERRUPT)
MANUFACTURER:   .WORD   $FFFF           ; DRIVER MANUFACTURER
                                        ; $0000 - UNDETERMINED
                                        ; $0001 - APPLE
                                        ; $0002-$FFFF 3RD PARTY DRIVER
INTERFACEVER:   .WORD   $FFFF           ; INTERFACE VERSION
                .WORD   $FFFF           ; RESERVED (MUST BE $0000)
                .RES    255

SP_COUNT:       .WORD   $FFFF           ; BYTES IN PAYLOAD?

SP_STATUS:
                LDA #SP_STATUS_PARAM_COUNT
                STA CMD_LIST_PCOUNT             ; PARAMETER COUNT
                STX CMD_LIST_DEST               ; DESTINATION DEVICE
                STY CMD_LIST_STAT               ; STATUS CODE
                JSR CALL_DISPATCHER

                .BYTE SP_CMD_STATUS             ; STATUS CALL COMMAND NUMBER
                .WORD CMD_LIST

                STX SP_COUNT+1
                STY SP_COUNT
                BCS ERROR

                BCC SP_STATUS_DONE
ERROR:
                PHA
                LDA #<SP_ERROR
                LDY #>SP_ERROR
                JSR STROUT
                PLA
                TAX
                JSR PRTX
                JSR CROUT

SP_STATUS_DONE:

                RTS

;*******************************
; CALL_DISPATCHER
;   Call this routine as a JSR
; INPUT:
;   Immediately following the 
; JSR put the following data
; into your code
; BYTE - Command Number
; WORD - Address for return values
;
;**********************************
CALL_DISPATCHER:
                JMP (SMARTPORT_DISPATCHER)


VENDER_STR:             .ASCIIZ "VENDER ID: "

VENDER_VERSION_STR:     .ASCIIZ "VENDER VERSION: "

COUNT_STR:              .ASCIIZ "DEVICE COUNT: "

SP_ERROR:               .ASCIIZ "SMARTPORT ERROR: "
SP_SUCCESS:             .ASCIIZ "SMARTPORT SUCCESS:  "

;*******************************
; DISPLAY_SP_STATUS
;   Displays the device count,
; vender id, and version number
;**********************************

DISPLAY_SP_STATUS:

                LDX #$00                ; SMARTPORT DEVICE ZERO
                LDY #$00
                JSR SP_STATUS

                LDA #<COUNT_STR         ; "DEVICE COUNT:"
                LDY #>COUNT_STR
                JSR STROUT
                LDX DCOUNT
                JSR PRTX
                JSR CROUT

                LDA #<VENDER_STR        ; "VENDER ID:"
                LDY #>VENDER_STR
                JSR STROUT
                LDA MANUFACTURER
                LDX MANUFACTURER+1
                JSR PRTAX
                JSR CROUT

                LDA #<VENDER_VERSION_STR       ; "VERSION:"
                LDY #>VENDER_VERSION_STR
                JSR STROUT
                LDA INTERFACEVER
                LDX INTERFACEVER+1
                JSR PRTAX
                JSR CROUT

                RTS

DEV_LIST_STR:   .ASCIIZ " SMARTPORT DEVICE LIST "
UNIT_STR:       .ASCIIZ "UNIT #"
NAME_STR:       .ASCIIZ " NAME: "

NUM_DEVICES:    .BYTE $00

ISTROUT:
                STA ZP1_LO
                STY ZP1_HI
                LDY #$00
PRINTI:
                LDA (ZP1),Y
                BEQ PRINTI_STOP
                AND #$3F        ; INVERSE
;               ORA #$80        ; NORMAL
;               ORA #$40        ; FLASHING
                JSR COUT
                INY
                CLC
                BCC PRINTI
PRINTI_STOP:
                RTS

DISPLAY_SP_DEVICES:
                LDA #<DEV_LIST_STR
                LDY #>DEV_LIST_STR
                JSR ISTROUT
                JSR CROUT
                JSR CROUT

                LDX #$00
                LDY #$00
                JSR SP_STATUS

                LDX DCOUNT
                INX
                STX NUM_DEVICES

                LDX #$01
NEXT_DEV:               
                TXA
                PHA

                LDA #<UNIT_STR
                LDY #>UNIT_STR
                JSR STROUT

                PLA                     ; GET BACK OUR VALUE OF 
                PHA                     ; X WE STORED ON THE STACK
                TAX
                JSR PRTX
                
                LDA #<NAME_STR
                LDY #>NAME_STR
                JSR STROUT

                PLA                     ; ONCE AGAIN, GET OUR VALUE OF X
                PHA
                TAX

                LDY #$03
                JSR SP_STATUS

                LDX #$00        
NEXT_CHAR:
                LDA SP_PAYLOAD+5,X      ; STRING
                ORA #$80
                JSR COUT
                INX
                CPX SP_PAYLOAD+4        ; LENGTH OF STRING
                BNE NEXT_CHAR
                JSR CROUT

                PLA
                TAX
                INX
                CPX NUM_DEVICES
                BNE NEXT_DEV
                
                RTS

FUJI_DISK_0_STR:        .ASCIIZ "FUJINET_DISK_0"
NETWORK_STR:            .ASCIIZ "NETWORK"

FIND_DEVICE_STR:        .ASCIIZ "FUJINET_DISK_0"
                        .RES 255

FIND_DEVICE_STR_LEN:    .BYTE 14

;*******************************
; SP_FIND_DEVICE
;   Looks for the specified smartport device
; INPUT
;   Put NULL terminated string of device to
;   search for in FIND_DEVICE_STR
; RETURNS
;   A = High byte address of string
;   Y = Low byte address of string
;   X = Device number or $FF on failure
;*********************************


SP_FIND_DEVICE:
                STA ZP1_LO
                STY ZP1_HI
                
                LDX #$00
                LDY #$00
LOOK_FOR_NULL:
                LDA (ZP1),Y
                STA FIND_DEVICE_STR,X 
                BEQ GOT_LENGTH
                INY
                INX
                CLC
                BCC LOOK_FOR_NULL

GOT_LENGTH:     
                STX FIND_DEVICE_STR_LEN

                LDA #'!'
                JSR COUT

                LDA #<FIND_DEVICE_STR
                LDY #>FIND_DEVICE_STR
                JSR STROUT

                LDX #$00
                LDY #$00
                JSR SP_STATUS

                LDX DCOUNT
                INX
                STX NUM_DEVICES

                LDX #$01

NEXT_DEV2: 
                LDA #'.'
                JSR COUT

                TXA
                PHA 

                LDY #$03                ; ? WHAT IS THIS COMMAND ?
                JSR SP_STATUS

                LDA SP_PAYLOAD+4        ; LENGTH OF STRING
                CMP FIND_DEVICE_STR_LEN
                BNE NEXT_DEVICE

; SAME STRING LENGTH SO COMPARE
                
                LDX #$00        
SCAN_CHAR:
                LDA SP_PAYLOAD+5,X      ; STRING
                ORA #$80
                CMP FIND_DEVICE_STR,X
                BNE NEXT_DEVICE

                INX
                CPX SP_PAYLOAD+4        ; LENGTH OF STRING
                BNE SCAN_CHAR

                CLC
                BCC FOUND_DEVICE        ; WE FOUND OUR DEVICE
NEXT_DEVICE:

                PLA
                TAX

                INX
                CPX NUM_DEVICES
                BNE NEXT_DEV2

                ; EXHAUSTED OUR LIST

                LDA #'N'
                JSR COUT
                LDX #$FF        ; NOT FOUND

                CLC
                BCC FOUND_DONE
FOUND_DEVICE:
                LDA #'F'
                JSR COUT  
FOUND_DONE:              
                RTS


