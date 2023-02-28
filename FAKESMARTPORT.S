.IF .NOT USE_SP


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
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE29

                PRINT_STR FAKE_SMARTPORT_STR_ADDR

                PRINT_STR FIND_SMARTPORT_SLOT_STR_ADDR

NO_TRACE29:
                RESTORE_REGS
.ENDIF

                LDA #$C5                ; FAKE SMARTPORT FOR TESTING $C500
                LDA SLOT_ADDR_HI
                RTS                     ; WE FOUND IT! A = SLOT ADDRESS


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
                ; FAKE SMARTPORT DISPATCHER

                LDX FAKE_DISPATCHER_ADDR
                STX DISPATCHER_ADDR_LO
                LDA FAKE_DISPATCHER_ADDR+1
                STA DISPATCHER_ADDR_HI
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
;   Y - CMD STATUS CODE
;******************************************************************
SP_STATUS:

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE26
                PRINT_STR SP_STATUS_STR_ADDR
NO_TRACE26:                
                RESTORE_REGS
.ENDIF
.ENDIF

                CPX #$00                        ; SMARTPORT DEVICE?
                BNE SPECIFIC_DEVICE

                ; ASSUME CMD STATUS CODE OF 0
                ; SMARTPORT STATUS - NUMBER OF DEVICES

                LDA #$02                        ; TWO DEVICES
                STA DCOUNT

SPECIFIC_DEVICE:
                LDA #SP_STATUS_PARAM_COUNT
                STA CMD_LIST_PCOUNT             ; PARAMETER COUNT
                STX CMD_LIST_DEST               ; DESTINATION DEVICE
                STY CMD_LIST_STAT               ; STATUS CODE

                CPY #SP_CMD_STATUS
                BNE NOT_STATUS

; STATUS FOR DEVICE NUMBER GREATER THAN ZERO

NOT_STATUS:
                CPY#SP_STATUS_DIB               ; GET NAME
                BNE CMD_UNKNOWN

                LDX CMD_LIST_DEST               ; WHAT DEVICE ARE WE WANTING INFO FROM?
                CPX #$01
                BNE NETWORK_DEV2

FUJI_DISK1:                                     ; FUJINET DISK 0?
                LDA FUJI_DISK_0_STR_ADDR
                LDY FUJI_DISK_0_STR_ADDR+1
                CLC
                BCC COPY_2_PAYLOAD

NETWORK_DEV2:                                   ; NETWORK DEVICE?
                CPX #$02
                BNE CMD_UNKNOWN

                LDA NETWORK_STR_ADDR
                LDY NETWORK_STR_ADDR+1

COPY_2_PAYLOAD:
                JSR CPY_STR_TO_SP_PAYLOAD

ADD_FAKE:
                LDX #255
                STX SP_COUNT
                LDY #$00
                STY SP_COUNT+1

CMD_UNKNOWN:
                JSR CALL_DISPATCHER

                .BYTE SP_CMD_STATUS             ; STATUS CALL COMMAND NUMBER
relocatefsp00:  .WORD CMD_LIST

                STX SP_COUNT+1
                STY SP_COUNT
                BCS ERROR

                BCC SP_STATUS_DONE
ERROR:
                PHA
                PRINT_STR SP_ERROR_STR_ADDR
                PLA
                TAX

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE30
                JSR PRTX
                JSR CROUT
NO_TRACE30:
                RESTORE_REGS
.ENDIF
.ENDIF


SP_STATUS_DONE:

                RTS


RETURN_ADDR:    .WORD $0000

; THIS IS JUST FOR TESTING WITH AN EMULATOR

FAKE_DISPATCHER:
                ; ADDRESS WE CALLED FROM IS ON STACK
                PLA
                STA ZP1_LO
                PLA
                STA ZP1_HI
                
                ; INCREASE ADDRESS BY NUMBER OF PARAMETERS
                LDY #$02
                LDA (ZP1),Y
                STA ZP2_LO
                INY
                LDA (ZP1),y
                STA ZP2_HI

                ; ZP2 NOW POINTS TO THE COMMAND LIST
                ; FIRST ITEM THERE IS THE PCOUNT
                LDY #$00
                LDA (ZP2),Y
                TAY ; ADD ONE
                INY
                TYA
                CLC
                ADC ZP1_LO
                STA ZP1_LO
                LDA ZP1_HI
                ADC #$00
                STA ZP1_HI

                ; ZP1 SHOULD NOT BE POINTING AT THE
                ; INSTRUCTIONS FOLLOWING THE PARAMETERS

                CLC     ; NO ERROR

                ; CONTINUE EXECUTION AFTER PARAMETERS
                JMP (ZP1)
                

FAKE_DEV:      .RES 255
FAKE_DEV_LEN:   .BYTE 0

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
                TXA
                PHA

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE27
                PRINT_STR SP_FIND_DEVICE_STR_ADDR
NO_TRACE27:                
                RESTORE_REGS
.ENDIF
.ENDIF

                CPX #$01
                BNE NETWORK_DEV

                LDA FUJI_DISK_0_STR_ADDR+1
                LDY FUJI_DISK_0_STR_ADDR
                CLC
                BCC COPY_STR
NETWORK_DEV:
                LDA NETWORK_STR_ADDR+1
                LDY NETWORK_STR_ADDR

COPY_STR:
                JSR CPY_STR_TO_SP_PAYLOAD
                
                PLA
                TAX
                RTS


SP_CLOSE:
                RTS
SP_READ:
                RTS
SP_CONTROL:
                RTS
SP_OPEN:        
                RTS
.ENDIF 