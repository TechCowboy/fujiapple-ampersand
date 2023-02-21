;*****************************************************
; Smartport Commands
;
; Generic smartport commands for use with Fujinet
; By Norman Davie

; Call GET_SMARTPORT_ADDRESS
; Call FIND_FIJINET

        .include "APPLEEQU.S"
        .include "ZEROPAGE.S"

SP_CMD_STATUS           =       $00
SP_CMD_READ_BLOCK       =       $01
SP_CMD_WRITE_BLOCK      =       $02
SP_CMD_FORMAT           =       $03
SP_CMD_CONTROL          =       $04
SP_CMD_INIT             =       $05
SP_CMD_OPEN             =       $06
SP_CMD_CLOSE            =       $07
SP_CMD_READ             =       $08
SP_CMD_WRITE            =       $09

SP_STATUS_CODE          =       $00     ; RETURN DEVICE STATUS
SP_STATUS_DIB           =       $03     ; RETURN DEVICE INFORMATION BLOCK
SP_STATUS_DIB_EXTRA     =       $04     ; RETURN DEVICE INFORMATION BLOCK EXTRA
SP_STATUS_LAST_ERROR    =       $05
SP_STATUS_RETURN_DATA   =       $06     ; RETURN BYTES/BLOCK PARAMETER FOR DEVICE

SP_ERROR_OK             =       $00
SP_ERROR_BAD_CMD        =       $01
SP_ERROR_BAD_PCNT       =       $02     ; BAD CALL PARAMETER COUNT
SP_ERROR_BUS_ERR        =       $06
SP_ERROR_BAD_UNIT       =       $11     ; UNIT NUMBER $00 WAS USED
SP_ERROR_BAD_CTRL       =       $21     ; CTRL OR STATUS CODE WAS NOT SUPPORTED
SP_ERROR_BAD_CTRL_PARM  =       $22     ; CTRL PARAMTER LIST CONTAINS INVALID INFO
SP_ERROR_IO_ERROR       =       $27     
SP_ERROR_NO_DRIVE       =       $28     ; DEVICE IS NOT CONNECTED
SP_ERROR_NO_WRITE       =       $2B     ; MEDIUM IS WRITE PROTECTED
SP_ERROR_BAD_BLOCK      =       $2D     ; BLOCK NUMBER IS OUTSIDE OF RANGE
SP_ERROR_DISK_SW        =       $2E     ; DISK SWITCH TOOK PLACE
SP_ERROR_OFFLINE        =       $2F     ; DEVICE OFFLINE OR NO DISK IN DRIVE
SP_ERROR_DEV_SPEC0      =       $30     ; DEVICE SPECIFIC ERRORS
SP_ERROR_DEV_SPECF      =       $3F     ; DEVICE SPECIFIC ERRORS
;SP_ERROR_RESERVED $40-$4F
SP_ERROR_NON_FATAL50    =       $50     ; DEVICE SPECIFIC WARNING
SP_ERROR_NON_FATAL7F    =       $7F     ; DEVICE SPECIFIC WARNING        

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
                LDX DCOUNT

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

                LDY #SP_STATUS_DIB      ; X = DEVICE 
                JSR SP_STATUS
                BCS DISPLAY_ERROR_OUT   ; SHOULD NEVER HAPPEN, BUT IF IT DOES, JUST EXIT

                JSR PRINT_PAYLOAD

                JSR CROUT

                PLA
                TAX
                INX
                CPX NUM_DEVICES
                BNE NEXT_DEV
                RTS
DISPLAY_ERROR_OUT:
                JSR PRTX

                LDA #<UNIT_STR
                LDY #>UNIT_STR
                JSR STROUT

                PLA
                TAX
                JSR PRTX

                RTS

FUJI_DISK_0_STR:        .ASCIIZ "FUJINET_DISK_0"
NETWORK_STR:            .ASCIIZ "NETWORK"

FIND_DEVICE_STR:        .RES 255
FIND_DEVICE_STR_LEN:    .BYTE 0

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
PRINT_PAYLOAD:
                PHA
                TXA
                PHA
                TYA
                PHA
                LDX #$00
PPAYLOAD:   
                LDA SP_PAYLOAD+5,X      ; STRING
                ORA #$80
                JSR COUT
                INX
                CPX SP_PAYLOAD+4
                BNE PPAYLOAD

                PLA
                TAY
                PLA
                TAX
                PLA

                RTS

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
                STX FIND_DEVICE_STR_LEN         ; LENGTH INCLUDES NULL

                LDA #<FIND_DEVICE_STR
                LDY #>FIND_DEVICE_STR
                JSR STROUT
                JSR CROUT

                LDX #$00
                LDY #$00
                JSR SP_STATUS

                LDX DCOUNT
                INX
                STX NUM_DEVICES

                LDX #$01

NEXT_DEV2: 
                TXA
                PHA 

                LDY #SP_STATUS_DIB      ; X IS DEVICE 
                JSR SP_STATUS
                BCS ERROR_OUT

                LDA SP_PAYLOAD+4        ; LENGTH OF STRING
                CMP FIND_DEVICE_STR_LEN
                BNE NEXT_DEVICE

; SAME STRING LENGTH SO COMPARE
                
                LDX #$00        
SCAN_CHAR:

                LDA SP_PAYLOAD+5,X      ; STRING
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

                LDX #$FF        ; NOT FOUND

                CLC
                BCC FOUND_DONE

ERROR_OUT:       
                PLA
                LDX #$FE        ; ERROR
                RTS

FOUND_DEVICE:
                PLA
                TAX
FOUND_DONE:              
                RTS


