.IF .NOT USE_SP

NUMBER_OF_FAKE_UNITS = 4

;*******************************
; FIND_SMARTPORT_SLOT
; INPUT:
;   NONE
;***
; RETURN
;   A = $FF - NO SMARTPORT FOUND
;   A = $CX - WHERE X IS THE SLOT
;**********************************
.IF USE_SP

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

.ENDIF
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
; 0 smartport
; 1 fujidisk_0
; 2 network

; SP_STATUS:

; .IF .NOT STRIP_TRACE
; .IF EXT_TRACE
;                 SAVE_REGS
;                 LDA TRACE_FLAG
;                 BEQ NO_TRACE26
;                 PRINT_STR SP_STATUS_STR_ADDR
; NO_TRACE26:                
;                 RESTORE_REGS
; .ENDIF
; .ENDIF

;                 CPX #$00                        ; SMARTPORT DEVICE?
;                 BNE SPECIFIC_DEVICE

;                 ; ASSUME CMD STATUS CODE OF 0
;                 ; SMARTPORT STATUS - NUMBER OF DEVICES

;                 LDA #$04                        ; TWO DEVICES
;                 STA DCOUNT

; SPECIFIC_DEVICE:
;                 LDA #SP_STATUS_PARAM_COUNT
;                 STA CMD_LIST                    ; PARAMETER COUNT
;                 STX CMD_LIST+1                  ; DESTINATION DEVICE
;                 STY CMD_LIST+2                  ; STATUS CODE

;                 CPY #SP_CMD_STATUS
;                 BNE NOT_STATUS

; ; STATUS FOR DEVICE NUMBER GREATER THAN ZERO

; NOT_STATUS:
;                 CPY#SP_STATUS_DIB               ; GET NAME
;                 BNE CMD_UNKNOWN

;                 LDX CMD_LIST+1                  ; WHAT DEVICE ARE WE WANTING INFO FROM?
;                 CPX #$01
;                 BNE NETWORK_DEV0

; FUJI_DISK1:                                     ; FUJINET DISK 0?
;                 LDA FUJI_DISK_0_STR_ADDR
;                 LDY FUJI_DISK_0_STR_ADDR+1
;                 LDX FUJI_DISK_0_STR_LEN
;                 CLC
;                 BCC COPY_2_PAYLOAD

; NETWORK_DEV0:                                   ; NETWORK DEVICE?
;                 CPX #$02
;                 BNE NETWORK_1_AND_UP

;                 LDA NETWORK_STR_ADDR
;                 LDY NETWORK_STR_ADDR+1
;                 LDX NETWORK_STR_LEN

;                 CLC
;                 BCC COPY_2_PAYLOAD

; NETWORK_1_AND_UP:
;                 CPX #$05
;                 BPL CMD_UNKNOWN
;                 TXA
;                 DEX                     ; UNIT 3 = NETWORK_1
;                 DEX
;                 TXA
;                 CLC
;                 ADC #'0'
;                 LDX NETWORK_STR_WITH_NUMBER_INDEX
;                 STA NETWORK_STR_WITH_NUMBER,X

;                 LDA NETWORK_STR_WITH_NUMBER_ADDR
;                 LDY NETWORK_STR_WITH_NUMBER_ADDR+1
;                 LDX NETWORK_STR_WITH_NUMBER_LEN


; COPY_2_PAYLOAD:
;                 JSR CPY_STR_TO_SP_PAYLOAD

; ADD_FAKE:
;                 LDX #255        ; buf buffer, but we don't care
;                 STX SP_COUNT
;                 LDY #$00
;                 STY SP_COUNT+1

; CMD_UNKNOWN:
;                 JSR CALL_DISPATCHER             ; known commands will adjust the process pointer

;                 .BYTE SP_CMD_STATUS             ; STATUS CALL COMMAND NUMBER
; relocatefsp00:  .WORD CMD_LIST

;                 STX SP_COUNT+1
;                 STY SP_COUNT
;                 BCS ERROR

;                 BCC SP_STATUS_DONE
; ERROR:
;                 PHA
;                 PRINT_STR SP_ERROR_STR_ADDR
;                 PLA
;                 TAX

; .IF .NOT STRIP_TRACE
; .IF EXT_TRACE
;                 SAVE_REGS
;                 LDA TRACE_FLAG
;                 BEQ NO_TRACE30
;                 JSR PRTX
;                 JSR CROUT
; NO_TRACE30:
;                 RESTORE_REGS
; .ENDIF
; .ENDIF

; SP_STATUS_DONE:

;                 RTS


; RETURN_ADDR:    .WORD $0000

; THIS IS JUST FOR TESTING WITH AN EMULATOR

;******************************************************************
; FAKE_DISPATCHER
;   Simulates dispatcher calls so we can test in an emulator
; NOTE: Destroys ZP1
; ZP1 = Address from stack
; ZP2 = CMD_LIST
; ZP3 = STORAGE
; ZP4 = address of string to copy
;******************************************************************

REQUESTED_CMD:          .BYTE $FF
REQUESTED_UNIT:         .BYTE $FF
GET_INDEX:              .BYTE $FF
STORE_INDEX:            .BYTE $FF
SAVE_ZERO_PAGE:         .RES 10

REGS_TO_SAVE            = 7


FAKE_DISPATCHER:
                LDX #$00
SAVE_ZP:
                LDA ZP2,X
                STA SAVE_ZERO_PAGE,X
                INX
                CPX #REGS_TO_SAVE
                BNE SAVE_ZP

                ; ADDRESS WE CALLED FROM IS ON STACK
                PLA
                STA ZP1_LO
                PLA
                STA ZP1_HI

;                JSR CALL_DISPATCHER
;
;Y+1:            .BYTE SP_CMD_STATUS             ; STATUS CALL COMMAND NUMBER
;y+2:            .WORD CMD_LIST
;Y+4:            NEXT INSTRUCTION

; let's play, fake the call!

                JSR WIPE_PAYLOAD

                LDA #$01
                LDA (ZP2),y
                STA REQUESTED_CMD         ; SMARTPORT COMMAND

                LDY #$02        ; GET CMD_LIST ADDRESS
                LDA (ZP1),Y
                STA ZP2_LO      ; POINTER TO CMDLIST (STORED_AFTER_CALL)
                INY
                LDA (ZP1),y
                STA ZP2_HI

                ; COMMON TO ALL CALLS
                ; SMARTPORT CONTROLLER CMDLIST
                ; 0   parameter list length
                ; 1   unit number
                ; 2-3 storage
                
                LDY #$01            ; CMD_LIST
                LDA (ZP2),Y         ; UNIT #
                STA REQUESTED_UNIT

                LDY #2
                LDA (ZP2),Y
                STA ZP3_LO
                INY
                LDA (ZP2),Y 
                STA ZP3_HI          ; WHERE TO STORE RESULT

                LDA REQUESTED_CMD
                CMP #SP_CMD_STATUS
                BNE COMPLETE_CMD

                ; ***********************
                ; SP_CMD_STATUS
                ; ***********************

                LDA REQUESTED_UNIT
                CMP #$00            ; SMARTPORT_CONTROLLER
                BNE NON_SMARTPORT_CTRLR

                ; SMARTPORT CONTROLLER CMDLIST
                ; 0   parameter list length
                ; 1   unit number
                ; 2-3  status list pointer (lsb-msb)
                ; 4   status code

                LDY #4
                LDA (ZP2),Y
                CMP #SP_STATUS_CODE
                BNE COMPLETE_CMD            ; DON'T KNOW WHAT TO DO...

                LDY #$00
                LDA #NUMBER_OF_FAKE_UNITS
                STA (ZP3),Y
                CLC
                BCC COMPLETE_CMD

NON_SMARTPORT_CTRLR:
;               LDA REQUESTED_UNIT
                CMP #1
                BNE NETWORK_DEV0
FUJI_DISK1:                                     ; UNIT 1 - FUJINET DISK 0
                LDA FUJI_DISK_0_STR_ADDR
                LDY FUJI_DISK_0_STR_ADDR+1
                LDX FUJI_DISK_0_STR_LEN
                CLC
                BCC COPY_2_PAYLOAD

NETWORK_DEV0:                                   ; UNIT 2 - NETWORK 
;               LDA REQUESTED_UNIT
                CMP #$02
                BNE NETWORK_1_AND_UP

                LDA NETWORK_STR_ADDR
                LDY NETWORK_STR_ADDR+1
                LDX NETWORK_STR_LEN

                CLC
                BCC COPY_2_PAYLOAD

NETWORK_1_AND_UP:
;               LDA REQUESTED_UNIT
                CMP #$05
                BPL COMPLETE_CMD

                TAX
                DEX                             ; UNIT 3/4 = NETWORK_1/2
                DEX
                TXA
                CLC
                ADC #'0'
                LDX NETWORK_STR_WITH_NUMBER_INDEX
                STA NETWORK_STR_WITH_NUMBER,X

                LDA NETWORK_STR_WITH_NUMBER_ADDR
                LDY NETWORK_STR_WITH_NUMBER_ADDR+1
                LDX NETWORK_STR_WITH_NUMBER_LEN

COPY_2_PAYLOAD:

                ; SP_PAYLOAD+4 LENGTH
                ; SP_PAYLOAD+5 STRING

                STA ZP4_LO                      ; GET THE STRING FROM
                STY ZP4_HI

                INX                             ; ADD NULL
                TXA
                LDY #4                          ; PAYLOAD+4
                STA (ZP3),Y                     ; STORE THE LENGTH
                
                TXA                             ; LENGTH OF STRING
                TAY
                STY GET_INDEX

                INY
                INY
                INY
                INY
                INY
                
                STY STORE_INDEX
                INX
CPY2PAYLOAD:
                LDY GET_INDEX
                LDA (ZP4),Y                     ; GET THE STRING
                LDY STORE_INDEX
                STA (ZP3),Y                     ; STORE THE STRING

                DEC STORE_INDEX
                DEC GET_INDEX
                DEX
                BNE CPY2PAYLOAD            

COMPLETE_CMD: 
                LDX #255                        ; buf buffer, but we don't care
                STX SP_COUNT
                LDY #$00
                STY SP_COUNT+1
              
                ; INCREASE ADDRESS BY NUMBER OF PARAMETERS

                LDY #$02
                LDA (ZP1),Y
                STA ZP2_LO                      ; CMD_LIST
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

                LDX #$00
RESTORE_ZP:
                LDA SAVE_ZERO_PAGE,X
                STA ZP2,X
                
                INX
                CPX #REGS_TO_SAVE
                BNE RESTORE_ZP


                LDA #SP_ERROR_OK
                CLC                             ; NO ERROR

                ; CONTINUE EXECUTION AFTER PARAMETERS
                JMP (ZP1)
                

FAKE_DEV:       .RES 255
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
;*** fake ***
; 0 - SMARTPORT
; 1 - FUJI_DISK_0
; 2 - NETWORK
; 3 - NETWORK_1
; 4 - NETWORK_2

; SP_FIND_DEVICE:
;                 TXA
;                 PHA

; .IF .NOT STRIP_TRACE
; .IF EXT_TRACE
;                 SAVE_REGS
;                 LDA TRACE_FLAG
;                 BEQ NO_TRACE27
;                 PRINT_STR SP_FIND_DEVICE_STR_ADDR
; NO_TRACE27:                
;                 RESTORE_REGS
; .ENDIF
; .ENDIF

;                 CPX #$01
;                 BNE NETWORK_DEV

;                 LDX FUJI_DISK_0_STR_LEN
;                 LDA FUJI_DISK_0_STR_ADDR+1
;                 LDY FUJI_DISK_0_STR_ADDR

;                 CLC
;                 BCC COPY_STR
; NETWORK_DEV:
;                 CPX #$02
;                 BNE NETWORK_DEV1

;                 LDX NETWORK_STR_LEN
;                 LDA NETWORK_STR_ADDR+1
;                 LDY NETWORK_STR_ADDR
                
;                 CLC
;                 BCC COPY_STR

; NETWORK_DEV1:
;                 CPX #$03
;                 BNE NO_DEVICE

;                 TXA
;                 CLC
;                 ADC #'0'
;                 LDX NETWORK_STR_WITH_NUMBER_INDEX
;                 STA NETWORK_STR_WITH_NUMBER,X
;                 LDX NETWORK_STR_WITH_NUMBER_LEN
;                 LDA NETWORK_STR_WITH_NUMBER_ADDR+1
;                 LDY NETWORK_STR_WITH_NUMBER_ADDR

; COPY_STR:
;                 JSR CPY_STR_TO_SP_PAYLOAD
                
;                 PLA
;                 TAX
;                 CLC
;                 RTS

; NO_DEVICE:
;                 PLA
;                 SEC
;                 LDX #SP_ERR
;                 RTS



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
; SP_CLOSE:
;                 RTS



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
;2-3    input buffer pointer (lsb-msb)
;4-5    byte count
;6-7    address pointer
;
;Parameter description
;input buffer pointer: This parameter contains the beginning address of the host data
;buffer to which the target bytes are written.
;byte count: This parameter contains the number of bytes to be read 
;address pointer: This parameter contains the block address of the target block.
;******************************************************************
; SP_READ:
;                 LDX TEST_BLOCK_STR_LEN
;                 LDA TEST_BLOCK_STR_ADDR
;                 LDY TEST_BLOCK_STR_ADDR+1
;                 JSR CPY_BUF_TO_SP_PAYLOAD
;                 LDX #$00
;                 CLC
;                 RTS


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
; 'R'-read
;0-1   payload size (bytes to return)
;2..   data
;
; 'W'-write
; 0-1  payload size (bytes to write)
; 2..  data
;
; 'A'-accept
; accept connection
;0-1    payload size $00?
;
; 'c'-close connection
; close client connection
;0-1    payload size $00?
;
;'D'-udp destination
; set UDP destination
;0-1    payload size?
;2...   url?
;
; INPUT
;  X = UNIT
;  Y = CONTROL CODE
;******************************************************************
; SP_CONTROL:
;                 CLC
;                 RTS

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
; SP_OPEN:        
;                 CLC
;                 RTS
.ENDIF 