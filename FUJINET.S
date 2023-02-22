;void connect(void)
;{
;  sp_open(net);
;  sp_payload[0]=0x02; // 258 bytes
;  sp_payload[1]=0x01;
;  sp_payload[2]=0x0C; // READ/WRITE (or GET)
;  sp_payload[3]=0x80; // NO TRANSLATION
;  memcpy(&sp_payload[4],url,256)
;  sp_control(net,'O'); // Do the open.  ;
;}

;bool isConnected(void)
;{
;  sp_status(net,'S');
;  return sp_payload[2] & 0x02; // Bit 2 = Connected?
;}

; X = DEVICE

CPY_URL_TO_PAYLOAD:
                LDA #<URL
                LDY #>URL
                
CPY_STR_TO_PAYLOAD:
                STA ZP1_LO
                STY ZP1_HI
                
                LDX #$00
                LDY #$00
LOOK_FOR_NULL2:
                LDA (ZP1),Y
                STA PAYLOAD+4,X 
                BEQ GOT_LENGTH2
                INY
                INX
                CLC
                BCC LOOK_FOR_NULL2

GOT_LENGTH2:
                ; STX URL_LEN         ; X = LENGTH INCLUDES NULL

                RTS

;void connect(void)
;{
;  sp_open(net);
;  sp_payload[0]=0x02; // 258 bytes
;  sp_payload[1]=0x01;
;  sp_payload[2]=0x0C; // READ/WRITE (or GET)
;  sp_payload[3]=0x80; // NO TRANSLATION
;  memcpy(&sp_payload[4],url,256)
;  sp_control(net,'O'); // Do the open.  ;
;}
FN_OPEN:
                TXA
                PHA
                JSR SP_OPEN
                LDY #$02
                STY PAYLOAD
                DEY
                STY PAYLOAD+1
                LDA #$0C
                STA PAYLOAD+2
                LDA TRANSLATION
                STA PAYLOAD+3

                JSR CPY_URL_TO_PAYLOAD

                PLA
                TAX
                LDY #'O'
                JSR SP_CONTROL


; X = DEVICE
FN_IS_CONNECTED:
                LDY #'S'
                JSR SP_STATUS
                LDA PAYLOAD+2
                AND #$02
                ROR
                RTS

; X = DEVICE 
FN_BYTES_WAITING:
                LDY #'S'
                JSR SP_STATUS
                LDA SP_PAYLOAD
                LDY SP_PAYLOAD+1
                RTS
        
; X=DEVICE
FIND_NETWORK:
                LDA #<NETWORK_STR
                LDY #>NETWORK_STR
                JSR SP_FIND_DEVICE

                RTS
