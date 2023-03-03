;*****************************************************
; Smartport Commands
;
; Generic smartport commands for use with Fujinet
; By Norman Davie

; Call GET_SMARTPORT_ADDRESS
; Call FIND_FIJINET

        .include "APPLEEQU.S"
        .include "ZEROPAGE.S"
        .include "MACROS.S"

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

SP_INIT_PARAM_COUNT     =       3
SP_OPEN_PARAM_COUNT     =       3
SP_CLOSE_PARAM_COUNT    =       3
SP_READ_PARAM_COUNT     =       4
SP_WRITE_PARAM_COUNT    =       4 
SP_STATUS_PARAM_COUNT   =       3
SP_CONTROL_PARAM_COUNT  =       3


SP_ERROR_NOT_FOUND      =       SP_ERROR_NON_FATAL50



SMARTPORT_DISPATCHER: 
DISPATCHER_ADDR_LO:     .BYTE $00
DISPATCHER_ADDR_HI:     .BYTE $00

relocatesp00:
SP_PAYLOAD_ADDR:        .WORD  SP_PAYLOAD
relocatesp01:
SP_PAYLOAD_STR_ADDR:    .WORD  SP_PAYLOAD+5

SP_COUNT:               .WORD   $FFFF           ; BYTES IN PAYLOAD?
SP_ERR:                 .BYTE   $FF             ; ERROR CODE

CMD_LIST:               .RES 15               

SP_PAYLOAD:
DCOUNT:                 .BYTE   $01             ; NUMBER OF DEVICES
INTSTATE:               .BYTE   $FF             ; INTERRUPT STATUS (IF BIT 6 IS SET, THEN NO INTERRUPT)
MANUFACTURER:           .WORD   $FFFF           ; DRIVER MANUFACTURER
                                                ; $0000 - UNDETERMINED
                                                ; $0001 - APPLE
                                                ; $0002-$FFFF 3RD PARTY DRIVER
INTERFACEVER:           .WORD   $FFFF           ; INTERFACE VERSION
                        .WORD   $0000           ; RESERVED (MUST BE $0000)
                        .RES    512             ; RESERVED FOR DATA

SLOT_ADDR		=	ZP2
SLOT_ADDR_LO	    	=	ZP2_LO
SLOT_ADDR_HI		=	ZP2_HI

;*******************************
; WIPE_PAYLOAD
;   Clear the contents of the payload
;**********************************

WIPE_PAYLOAD:
                SAVE_REGS

                LDA #$A5

                LDX #$00
CLR:                
                STA SP_PAYLOAD+4,X 
                INX
                CPX #16
                BNE CLR

                RESTORE_REGS
                RTS

;*******************************
; PRINT_SP_PAYLOAD
;   Display the ASCII contents
; of the payload buffer
;**********************************
PRINT_SP_PAYLOAD:
                SAVE_REGS

                LDX #$00
PPAYLOAD:   
                LDA SP_PAYLOAD+4,X      ; STRING
                ORA #$80
                JSR COUT
                INX
                CPX #16
                BNE PPAYLOAD

                RESTORE_REGS
PAYLOAD:
                RTS

;*******************************
; DUMP_SP_PAYLOAD
;   Display the HEX and ASCII contents
; of the payload buffer
;**********************************
DUMPSIZE = 12

DUMP_SP_PAYLOAD:
                JSR CROUT
                LDX #$00
PPAYLOAD0:   
                TXA
                PHA                     ; SAVE X PUSH +1

                LDA SP_PAYLOAD+4,X      ; STRING
                TAX
                JSR PRINT_X

                PLA                     ; RESTORE X -1
                TAX

                INX
                CPX #DUMPSIZE
                BNE PPAYLOAD0
                JSR CROUT

        JSR PRINT_STACK
                LDX #$00
PPAYLOAD1: 
                TXA
                PHA
                LDA SP_PAYLOAD+4,X      ; STRING
                ORA #$80                ; MAKE SURE THE HIGH BIT IS
                JSR COUT                ; SET SO IT DOESN'T LOOK INVERSE
                LDA #SPACE
                JSR COUT
                JSR COUT
                PLA
                TAX
                INX
                CPX #DUMPSIZE
                BNE PPAYLOAD1

                JSR CROUT

                RTS

;**********************************
DUMP_SP_PAYLOAD_STR:
                SAVE_REGS

                PRINT_STR LEN_STR_ADDR

                LDA #'['
                JSR COUT
                LDX SP_PAYLOAD+4
                JSR PRTX
                LDA #']'
                JSR COUT


                LDX #$00
PPAYLOAD2:  
                TXA
                PHA
                LDA SP_PAYLOAD+5,X      ; STRING
                ORA #$80
                JSR COUT
                PLA
                TAX
                INX
                CPX SP_PAYLOAD+4
                BNE PPAYLOAD2

                JSR CROUT
                RESTORE_REGS

                RTS



.IF USE_SP

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

.IF .NOT STRIP_TRACE
.IF EXT2_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE10


                PRINT_STR REAL_SMARTPORT_STR_ADDR

                PRINT_STR FIND_SMARTPORT_SLOT_STR_ADDR

 NO_TRACE10:               
                RESTORE_REGS
.ENDIF
.ENDIF

                LDA     #$C7            ; START AT SLOT 7 ($C700)
                STA     SLOT_ADDR_HI
                LDA     #$00
                STA     SLOT_ADDR_LO

SCAN:
                LDY #$01                ; LOOK AT BYTES 1,3,5,AND 7
                LDX #$00

NEXT_MATCH:
                LDA (SLOT_ADDR),Y       ; COMPARE TO THE MAGIC NUMBERS
                CMP SMARTPORT_ID,X      ; 
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
                TXA                    
                CLC
                BCC SLOT_FIND_DONE

NOT_FOUND:
                LDA #$FF                ; WE DIDN'T FIND IT
                STA SLOT_ADDR_LO
                STA SLOT_ADDR_HI

SLOT_FIND_DONE:

.IF .NOT STRIP_TRACE   
.IF EXT2_TRACE 
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE28
                LDA SLOT_ADDR_HI
                LDX SLOT_ADDR_LO
                JSR PRTAX
                JSR CROUT
 NO_TRACE28:               
                RESTORE_REGS 
.ENDIF 
.ENDIF

                RTS
        
SMARTPORT_ID:   .BYTE $20, $00, $03, $00 
.ENDIF



.IF USE_SP

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

.IF .NOT STRIP_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE11
                PRINT_STR GET_SMARTPORT_DISPATCH_ADDRESS_STR_ADDR
NO_TRACE11:                
                RESTORE_REGS
.ENDIF

                JSR FIND_SMARTPORT_SLOT 
                CMP #$FF                ; IF A == $FF THEN NOT FOUND
                BEQ NO_DISPATCHER

                LDA SLOT_ADDR_HI
                STA DISPATCHER_ADDR_HI  ; A = $CX WHERE X IS THE SLOT
                LDA SLOT_ADDR_LO
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

                CLC
                BCC DONE

NO_DISPATCHER:
                LDA #$FF                ; NO ADDRESS FOUND
                LDX #$FF
                STA DISPATCHER_ADDR_HI  ; PUT ADDRESS IN A AND X
                STX DISPATCHER_ADDR_LO
DONE:        

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                SAVE_REGS
                PRINT_STR DISPATCHER_ADDRESS_STR_ADDR


                LDA DISPATCHER_ADDR_HI
                LDX DISPATCHER_ADDR_LO
                JSR PRTAX
                JSR CROUT
                RESTORE_REGS
.ENDIF
.ENDIF

                LDA DISPATCHER_ADDR_HI  ; PUT ADDRESS IN A AND X
                LDX DISPATCHER_ADDR_LO

                RTS
.ENDIF


.IF USE_SP

;******************************************************************
; SP_OPEN
; The Open command opens a logical me on the target device for data I/0. This
; command is used for character devices only. The parameter list for this call is as
; follows:
; Byte Definition
; 0     parameter list length ($03)
; 1     unit number 
; INPUT
; X = UNIT DESTINATION
;******************************************************************
SP_OPEN:

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                SAVE_REGS
                TXA
                PHA                                     ; STACK +1

                LDA TRACE_FLAG
                BEQ NO_TRACE12

                JSR CROUT
                PRINT_STR SP_OPEN_STR_ADDR              ; "SP_OPEN:"

                PLA                                     ; STACK -1
                PHA                                     ; STACK +1
                TAX
                JSR PRTX
                JSR CROUT
                JSR DUMP_SP_PAYLOAD_STR
                JSR CROUT
NO_TRACE12:          
                PLA                                     ; STACK -1

                RESTORE_REGS

.ENDIF
.ENDIF

                LDA #SP_OPEN_PARAM_COUNT        ; 3
                STA CMD_LIST                    ; PARAMETER COUNT
                STX CMD_LIST+1                  ; DESTINATION DEVICE
                JSR CALL_DISPATCHER

                .BYTE SP_CMD_OPEN
relocatesp02:   .WORD CMD_LIST
                
                BCS OPEN_ERROR

                BCC SP_OPEN_DONE
OPEN_ERROR:
                PHA
                PRINT_STR SP_ERROR_STR_ADDR
                PLA
                TAX
                JSR PRTX
                JSR CROUT

SP_OPEN_DONE:

                RTS

;******************************************************************
; SP_CLOSE
; The Close command closes a logical file on the target device after a data I/O
; sequence is completed. This command is used for character devices only. The
; parameter list for this call is as follows:
; Byte Definition
; 0     parameter list length ($03)
; 1     unit number
; INPUT
; X = UNIT DESTINATION
;******************************************************************
SP_CLOSE:

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                SAVE_REGS
                TXA
                PHA
                LDA TRACE_FLAG
                BEQ NO_TRACE13
                PRINT_STR SP_CLOSE_STR_ADDR
                PLA
                PHA
                TAX
                JSR PRTX

NO_TRACE13:     
                PLA           
                RESTORE_REGS
.ENDIF
.ENDIF

                LDA #SP_CLOSE_PARAM_COUNT       ; 3
                STA CMD_LIST                    ; PARAMETER COUNT
                STX CMD_LIST+1                  ; DESTINATION DEVICE
                JSR CALL_DISPATCHER

                .BYTE SP_CMD_CLOSE
relocatesp03:   .WORD CMD_LIST
                
                BCS CLOSE_ERROR

                BCC SP_CLOSE_DONE
CLOSE_ERROR:
                PRINT_STR SP_ERROR_STR_ADDR

                LDX CMD_LIST+1
                JSR PRTX
                JSR CROUT

SP_CLOSE_DONE:

                RTS


;******************************************************************
; SP_CONTROL
;The Control command provides two basic functions. The first is to execute device
;control routines designed by Apple. The second is to execute Fujinet commands. 
;Although each control code has its own parameter list.
;
; FUJINET SPECIFC
;Byte   Definition
; 'O'-open
;0-1    payload size
;2      mode read or write or both
;3      translation
;4...   url
;
; 'C'-close
;0-1    payload size $00
;
;'R'
;0-1   payload size (bytes to return)
;2..   data
;
;'W'
; 0-1  payload size (bytes to write)
; 2..  data
;
;'A'
; accept connection
;
; 'c'
; close client connection
;
;'D'
; set UDP destination
;
; INPUT
;  X = UNIT
;  Y = CONTROL CODE
;******************************************************************
SP_CONTROL:
                STY CMD_LIST+4

.IF .NOT STRIP_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE14

                TXA
                PHA

                PRINT_STR SP_CONTROL_STR_ADDR
                PLA
                TAX
                
                JSR PRTX
                LDA #'['
                JSR COUT
                LDA CMD_LIST+4
                JSR COUT
                LDA #']'
                JSR COUT
                LDX CMD_LIST+4
                JSR PRTX
                JSR CROUT
NO_TRACE14:                
                RESTORE_REGS
.ENDIF

                LDA #SP_CONTROL_PARAM_COUNT     ; 3
                STA CMD_LIST                    ; PARAMETER COUNT
                STX CMD_LIST+1                  ; DESTINATION DEVICE
                ; OTHER ITEMS WILL NEED TO BE
                ; SET BEFORE CALLING THIS ROUTINE
                JSR CALL_DISPATCHER

                .BYTE SP_CMD_CONTROL
relocatesp04:   .WORD CMD_LIST
                
                BCS CTRL_ERROR
                BCC SP_CTRL_DONE
CTRL_ERROR:
                PHA
                PRINT_STR SP_ERROR_STR_ADDR
                PLA
                TAX
                JSR PRTX
                JSR CROUT
                SEC

SP_CTRL_DONE:

                RTS

;******************************************************************
; SP_READ
;The Read command reads a specified number of bytes from the target device
;specified in the unit number parameter. The bytes read by this command are
;written into RAM, beginning at the address specified in the data buffer pointer. The
;number of bytes to be read is specified in the byte count parameter. The parameter
;list for this call is as follows:
;
;Byte  Definition
;0      parameter list length ($04)
;1      unit number
;2-3    data buffer pointer
;4-5    byte count
;6-7    address pointer
;
;Parameter description
;data buffer pointer: This parameter contains the beginning address of the host data
;buffer to which the target bytes are written.
;byte count: This parameter contains the number of bytes to be read 
;address pointer: This parameter contains the block address of the target block.
;******************************************************************
SP_READ:

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE15
                TXA
                PHA
                PRINT_STR SP_READ_STR_ADDR
                LDA #COLON
                JSR COUT
                PRINT_STR UNIT_STR_ADDR
                PLA
                TAX
                JSR PRTX
                JSR CROUT
NO_TRACE15:                
                RESTORE_REGS
.ENDIF
.ENDIF
; CHECK HERE
                LDA #SP_READ_PARAM_COUNT
                STA CMD_LIST                    ; [0] PARAMETER COUNT
                STX CMD_LIST+1                  ; [1] X = DESTINATION DEVICE
                LDA SP_PAYLOAD_ADDR
                STA CMD_LIST+2                  ; [2] WHERE TO STORE DATA LO
                LDA SP_PAYLOAD_ADDR+1
                STA CMD_LIST+3                  ; [3] WHERE TO STORE DATA HI
                STY CMD_LIST+4                  ; [4] LENGTH LO
                LDA #$00
                STA CMD_LIST+5                  ; [5] LENGTH HI
                LDA #00
                STA CMD_LIST+6                  ; [6] ????
                LDA #40
                STA CMD_LIST+7                  ; [7] ????
                JSR CALL_DISPATCHER

                .BYTE SP_CMD_READ               ; READ CALL COMMAND NUMBER
relocatesp05:   .WORD CMD_LIST

                STX SP_COUNT+1
                STY SP_COUNT
                STA SP_ERR
                BCC SP_READ_DONE

ERROR:
.IF EXT_TRACE
                PHA
                PRINT_STR SP_ERROR_STR_ADDR
                PLA
                TAX
                JSR PRTX
                JSR CROUT
.ENDIF
                SEC
                RTS

SP_READ_DONE:
                RTS


;******************************************************************
; SP_WRITE
;The Write command writes a specified number of bytes to the target device
;specified in the unit number p4rameter. The bytes written by this command are
;read from RAM, beginning at the address specified in the data buffer pointer. The
;number of bytes to be written is specified in the byte count parameter. The
;parameter list for this call is as follows:
;
;Byte  Definition
;0      parameter list length 
;1      unit number
;2-3    data buffer pointer
;4-5    byte count
;6-7    address pointer
;
;data buffer pointer: This parameter contains the beginning address of the data
;buffer from which the target bytes are written.
;byte count: This parameter contains the number of bytes to write for this
;command.
;address pointer: This parameter contains the block address of the target block.
;******************************************************************
SP_WRITE:

.IF .NOT STRIP_TRACE
.IF EXT2_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE15
                TXA
                PHA
                PRINT_STR SP_WRITE_STR_ADDR
                PRINT_STR UNIT_STR_ADDR
                PLA
                TAX
                JSR PRTX
                JSR CROUT
NO_TRACE15:                
                RESTORE_REGS
.ENDIF
.ENDIF

                LDA #SP_WRITE_PARAM_COUNT
                STA CMD_LIST                    ; PARAMETER COUNT
                STX CMD_LIST+1                  ; DESTINATION DEVICE
                LDA SP_PAYLOAD_ADDR
                STA CMD_LIST+2                  ; DATA BUFFER
                LDA SP_PAYLOAD_ADDR+1
                STY CMD_LIST+4                  ; Y=LENGTH LO
                LDA #$00         
                LDY CMD_LIST+5                  ; LENGTH HI
                LDA #0                          ; DATA POINTER
                STA CMD_LIST+6                
                STA CMD_LIST+7
   
                JSR CALL_DISPATCHER

                .BYTE SP_CMD_WRITE             ; STATUS CALL COMMAND NUMBER
relocatesp06:   .WORD CMD_LIST

                STX SP_COUNT+1
                STY SP_COUNT
                BCS ERROR2

                BCC SP_WRITE_DONE
ERROR2:
                PHA
                PRINT_STR SP_ERROR_STR_ADDR
                PLA
                TAX
                JSR PRTX
                JSR CROUT

SP_WRITE_DONE:

                RTS




;******************************************************************
; SP_STATUS
;   The Status command returns information about a specific device.
; The information returned by this command is determined by status code.
; On return from a Status call, the microprocessor X and Y registers are set to
; indicate the number of bytes transferred to the Apple II by the command. The X
; register is set to the low byte of the count, and the Y register is set to the high byte.
; The parameter list for this call is as follows:
; Byte Definition
;  0   parameter list length
;  1   unit number
; 2-3  status list pointer (lsb-msb)
;  4   status code
; INPUT
;   X - UNIT DESTINATION
;   Y - STATUS CODE
;******************************************************************
SP_STATUS:

.IF .NOT STRIP_TRACE
.IF EXT2_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE15
                TXA
                PHA
                PRINT_STR SP_STATUS_STR_ADDR
                PRINT_STR UNIT_STR_ADDR
                PLA
                TAX
                JSR PRTX
                JSR CROUT
NO_TRACE15:                
                RESTORE_REGS
.ENDIF
.ENDIF

                LDA #SP_STATUS_PARAM_COUNT
                STA CMD_LIST                    ; PARAMETER COUNT
                STX CMD_LIST+1                  ; X = DESTINATION DEVICE
                LDA SP_PAYLOAD_ADDR             
                STA CMD_LIST+2                  ; STATUS LIST POINTER LO
                LDA SP_PAYLOAD_ADDR+1           
                STA CMD_LIST+3                  ; STATUS LIST POINTER HI
                STY CMD_LIST+4                  ; Y = STATUS CODE

                JSR CALL_DISPATCHER

                .BYTE SP_CMD_STATUS             ; STATUS CALL COMMAND NUMBER
relocatesp07:   .WORD CMD_LIST

                STX SP_COUNT+1
                STY SP_COUNT
                BCS ERROR3

                BCC SP_STATUS_DONE
ERROR3:
                PHA
                PRINT_STR SP_ERROR_STR_ADDR
                PLA
                TAX
                JSR PRTX
                JSR CROUT

SP_STATUS_DONE:

                RTS
.ENDIF

;*******************************
; CALL_DISPATCHER
;   Call this routine as a JSR
; INPUT:
;   Immediately following the 
; JSR put the following data
; into your code
; BYTE - Command Number
; WORD - Address for return values
;**********************************
CALL_DISPATCHER:

.IF .NOT STRIP_TRACE
.IF EXT2_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE16
                PRINT_STR CALL_DISPATCHER_STR_ADDR
NO_TRACE16:                
                RESTORE_REGS
.ENDIF
.ENDIF

                JMP (SMARTPORT_DISPATCHER)



;*******************************
; DISPLAY_SP_STATUS
;   Displays the device count,
; vender id, and version number
;**********************************
DISPLAY_SP_STATUS:

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE17
                PRINT_STR DISPLAY_SP_STATUS_STR_ADDR
NO_TRACE17:                
                RESTORE_REGS
.ENDIF
.ENDIF

                LDX #$00                                ; SMARTPORT DEVICE ZERO
                LDY #$00
                JSR SP_STATUS
                LDX DCOUNT                              ; DCOUNT = NUMBER OF DEVICES

                PRINT_STR COUNT_STR_ADDR
                LDX DCOUNT
                JSR PRTX
                JSR CROUT

                PRINT_STR VENDER_STR_ADDR
                LDA MANUFACTURER
                LDX MANUFACTURER+1
                JSR PRTAX
                JSR CROUT

                PRINT_STR VENDER_VERSION_STR_ADDR
                LDA INTERFACEVER
                LDX INTERFACEVER+1
                JSR PRTAX
                JSR CROUT

                RTS




NUM_DEVICES:    .BYTE $00

;*******************************
; ISTROUT
;   Display string in Fsp_D
;**********************************
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

;*******************************
; DISPLAY_SP_DEVICES
;   Display all the devices on
; the smartport
;**********************************
DISPLAY_SP_DEVICES:

                LDA DEV_LIST_STR_ADDR
                LDY DEV_LIST_STR_ADDR+1
                JSR ISTROUT
                JSR CROUT
                JSR CROUT

                LDX #$00
                LDY #SP_CMD_STATUS
                JSR SP_STATUS

                LDX DCOUNT
                INX
                STX NUM_DEVICES

                LDX #$01
NEXT_DEV:               
                TXA
                PHA

                PRINT_STR UNIT_STR_ADDR

                PLA                     ; GET BACK OUR VALUE OF 
                PHA                     ; X WE STORED ON THE STACK
                TAX
                JSR PRTX
                
                PRINT_STR NAME_STR_ADDR

                PLA                     ; ONCE AGAIN, GET OUR VALUE OF X
                PHA
                TAX

                LDY #SP_STATUS_DIB      ; X = DEVICE 
                JSR SP_STATUS
                BCS DISPLAY_ERROR_OUT   ; SHOULD NEVER HAPPEN, BUT IF IT DOES, JUST EXIT

                JSR PRINT_SP_PAYLOAD

                JSR CROUT

                PLA
                TAX
                INX
                CPX NUM_DEVICES
                BNE NEXT_DEV
                RTS

DISPLAY_ERROR_OUT:
                JSR PRTX

                PRINT_STR UNIT_STR_ADDR

                PLA
                TAX
                JSR PRTX

                RTS



FIND_DEVICE_BUF_LEN:    .BYTE 0
FIND_DEVICE_BUF:        .RES  255
relocate011:
FIND_DEVICE_BUF_ADDR:   .WORD FIND_DEVICE_BUF


;***************************************************************
.IF USE_SP

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

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE18
                PRINT_STR SP_FIND_DEVICE_STR_ADDR       ; "SP_FIND_DEVICE:"
NO_TRACE18:                
                RESTORE_REGS
.ENDIF
.ENDIF

                STA ZP1_HI                              ; STORE THE STRING ADDRESS
                STY ZP1_LO
                
                LDX #$00
                LDY #$00
LOOK_FOR_NULL:
                LDA (ZP1),Y                             ; START OF STRING WITHOUT LENGTH
                STA FIND_DEVICE_BUF,X                   
                BEQ GOT_LENGTH                          ; STOP WHEN WE GET TO NULL
                INY
                INX
                CLC
                BCC LOOK_FOR_NULL

GOT_LENGTH:     
                STX FIND_DEVICE_BUF_LEN                 ; SAVE THE LENGTH INCLUDES NULL

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE19
                PRINT_STR FIND_DEVICE_BUF_ADDR          ; DISPLAY THE STRING WE COLLECTED
                JSR CROUT                               ; CARRIAGE RETURN
NO_TRACE19:                
                RESTORE_REGS
.ENDIF
.ENDIF

                LDX #$00
                LDY #SP_CMD_STATUS                      ; ASK FOR SMARTPORT STATUS
                JSR SP_STATUS

                LDX DCOUNT                              ; THE NUMBER OF DEVICES
                INX
                STX NUM_DEVICES

                LDX #$01                                ; START AT DEVICE #1

NEXT_DEV2: 
                TXA
                PHA 

                LDY #SP_STATUS_DIB                      ; X IS DEVICE 
                JSR SP_STATUS                           ; GET INFO
                BCS ERROR_OUT
                
                LDA SP_PAYLOAD+4                        ; LENGTH OF STRING
                CMP FIND_DEVICE_BUF_LEN                 ; IS IT THE SAME SIZE AS THE STRING WE'RE LOOKING FOR?
                BNE NEXT_DEVICE                         ; NOPE, CHECK NEXT DEVICE


                ; SAME SIZE STRING, NOW CHECK AND SEE IF IT
                ; IS THE DEVICE WE'RE LOOKING FOR

                LDX #$00        
SCAN_CHAR:

                LDA SP_PAYLOAD+5,X                      ; INFO STRING
                CMP FIND_DEVICE_BUF,X                   ; DEVICE WE'RE LOOKING FOR
                BNE NEXT_DEVICE                         ; NOT THE SAME, CHECK NEXT DEVICE

                INX                                     ; MOVE TO NEXT DEVICE
                CPX SP_PAYLOAD+4                        ; HAVE WE FINISHED LOOKING AT THE SAME NUMBER OF CHARACTERS?
                BNE SCAN_CHAR                           ; NOPE, KEEP GOING                           

                CLC
                BCC FOUND_DEVICE                        ; WE FOUND OUR DEVICE
NEXT_DEVICE:

                PLA                                     ; REMOVE THE DEVICE NUMBER OFF STACK
                TAX                                     
                INX                                     ; AND INCREMENT IT
                CPX NUM_DEVICES                         ; HAVE WE CHECKED ALL DEVICES?
                BNE NEXT_DEV2                           ; NOPE, KEEP GOING

                ; EXHAUSTED OUR LIST

                LDX #$FF                                ; NOT FOUND
                LDA #SP_ERROR_NOT_FOUND
                CLC
                BCC FOUND_DONE

ERROR_OUT:      
                ; ERROR STRING HERE
                PLA
                LDX #$FF                                ; ERROR
                RTS

FOUND_DEVICE:

                PLA
                TAX

FOUND_DONE:    

                RTS
.ENDIF




