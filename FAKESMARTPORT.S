.IF USE_SP
    ; DON'T USE THIS CODE
.ELSE
FIND_SMARTPORT_SLOT:

                LDA #$C5                ; FAKE SMARTPORT FOR TESTING $C500
                LDA SLOT_ADDR_HI
                RTS                     ; WE FOUND IT! A = SLOT ADDRESS

GET_SMARTPORT_DISPATCH_ADDRESS:
                ; FAKE SMARTPORT DISPATCHER

                LDA #<FAKE_DISPATCHER
                STA DISPATCHER_ADDR_LO
                LDA #>FAKE_DISPATCHER
                STA DISPATCHER_ADDR_HI
                RTS

SP_STATUS:
                LDA #SP_STATUS_PARAM_COUNT
                STA CMD_LIST_PCOUNT             ; PARAMETER COUNT
                STX CMD_LIST_DEST               ; DESTINATION DEVICE
                STY CMD_LIST_STAT               ; STATUS CODE

                CPY #SP_STATUS_DIB
                BNE NOT_STATUS

                LDA #<NETWORK_STR
                LDY #>NETWORK_STR
                JSR CPY_STR_TO_PAYLOAD
NOT_STATUS:
                JSR CALL_DISPATCHER

                .BYTE SP_CMD_STATUS             ; STATUS CALL COMMAND NUMBER
relocatesp04:   .WORD CMD_LIST

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

SP_FIND_DEVICE:

                STA ZP1_LO
                STY ZP1_HI
                
                LDX #$00
                LDY #$00
LOOK_FOR_NULL:
                LDA (ZP1),Y
                STA FAKE_DEV,X 
                BEQ GOT_LENGTH
                INY
                INX
                CLC
                BCC LOOK_FOR_NULL

GOT_LENGTH:     
                STX FAKE_DEV_LEN         ; LENGTH INCLUDES NULL

                LDX #$00        
SCAN_CHAR:
                LDA FAKE_DEV,X
                STA SP_PAYLOAD+5,X      ; STRING

                INX
                CPX FAKE_DEV_LEN        ; LENGTH OF STRING
                BNE SCAN_CHAR

                LDA FAKE_DEV_LEN
                STA SP_PAYLOAD+4

                LDX #$01
                RTS

.ENDIF 