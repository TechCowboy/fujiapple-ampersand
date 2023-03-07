;*****************************************************
; FUJINET.S
; BASIC to Fujinet
; By Norman Davie

    .include "MACROS.S"
    .include "REGS.S"

FN_OK                   = 0
FN_ERR_WRITE_ONLY       = 131	    ;Protocol is in Write-only mode
FN_ERR_INVALID_COMMAND  = 132	    ;Protocol was sent an invalid command
FN_ERR_MISSING_PROTO    = 133	    ;No protocol attached.
FN_ERR_READ_ONLY        = 135	    ;Protocol is in read-only mode
FN_ERR_TIMED_OUT        = 138	    ;Timed out
FN_ERR_CRITICAL         = 144	    ;A critical error occurred. SIO reports this, get the actual Error code from byte 4 of STATUS.
FN_ERR_CMD_NOT_IMPLEMENTED = 146	;Command not implemented
FN_ERR_FILE_EXISTS      = 151	    ;File Exists
FN_ERR_NO_SPACE         = 162	    ;No space on device
FN_ERR_INVALID_URL      = 165	    ;Invalid Devicespec
FN_ERR_ACCESS_DENIED    = 167	    ;Access Denied
FN_ERR_FILE_NOT_FOUND   = 170	    ;File not found (emitted by filesystem adaptors)
FN_ERR_REFUSED          = 200	    ;Connection Refused (equivalent to errno ECONNREFUSED)
FN_ERR_UNREACHABLE      = 201	    ;Network Unreachable (equivalent to errno ENETUNREACH)
FN_ERR_CONNECTION_TIMEOUT   = 202	;Connection Timeout (equivalent to errno ETIMEDOUT)
FN_ERR_NETWORK_DOWN     = 203	    ;Network is down (equivalent to errno ENETDOWN)
FN_ERR_CONNECTION_RESET = 204	    ;Connection was reset during read/write (equivalent to errno ECONNRESET)
FN_ERR_CIP              = 205	    ;Connection in progress (EAGAIN)
FN_ERR_ADDRESS_IN_USE   = 206	    ;Address in use (EADDRINUSE)
FN_ERR_NOT_CONNECTED    = 207	    ;Not Connected
FN_ERR_SERVER_NOT_RUNNING = 208	    ;Server not Running
FN_ERR_NO_CONNECTION_WAITING = 209	;No connection waiting
FN_ERR_SERVICE_NOT_AVAILABLE = 210	;Service Not Available
FN_ERR_CONNECTION_ABORTED = 211	    ;Connection Aborted
FN_ERR_BAD_CREDENTIALS  = 212	    ;Invalid Username or Password (debating whether to overload as access denied.)
FN_ERR_MEMORY_ERROR     = 255	    ;Could not allocate either receive or transmit buffers.

FN_LAST_ERR:            .BYTE $00

;******************************************************************;
; CPY_STR_TO_SP_PAYLOAD
; Copy the length proceeded string to the Smartport buffer
;
; INPUT
;  A = high address
;  Y = low address
;  X = length
; RETURNS
;  X = String length
;******************************************************************
CPY_STR_TO_SP_PAYLOAD:
                STA ZP1_LO
                STY ZP1_HI
                STX ZP2


                LDY #$00
CONT3:
                LDA (ZP1),Y
                STA SP_PAYLOAD+5,Y 
                INY
                CPY ZP2
                BNE CONT3

GOT_LENGTH2:
                
                STY SP_PAYLOAD+4        ; STORE LENGTH
                LDX SP_PAYLOAD+4
                RTS

;******************************************************************
; CPY_URL_TO_SP_PAYLOAD
; Copy the BASIC URL into the Smartport buffer as a zero
; terminated string
;
; INPUT
;  A = high address
;  Y = low address
; RETURNS
;  X = String length
;******************************************************************
CPY_URL_TO_SP_PAYLOAD:

                LDA URL_ADDR        ; STRING WITHOUT LENGTH
                LDY URL_ADDR+1
                
                STA ZP1_LO
                STY ZP1_HI
                
                LDX #$00
                LDY #$00
LOOK_FOR_NULL3:
                LDA (ZP1),Y
                STA SP_PAYLOAD+4,X 
                BEQ GOT_LENGTH3
                INY
                INX
                CLC
                BCC LOOK_FOR_NULL3

GOT_LENGTH3:
                INX                     
                LDA #$00                ; NULL TERMINATE STRING
                STA SP_PAYLOAD+5,X

;                TXA
;                STA SP_PAYLOAD+4        ; STORE LENGTH

;                TAX                     ; RETURN LENGTH
                RTS

;******************************************************************
; CPY_BUF_TO_SP_PAYLOAD
; Copy the BASIC URL into the Smartport buffer as a zero
; terminated string
;
; INPUT
;  A = high address
;  Y = low address
; RETURNS
;  X = String length
;******************************************************************
CPY_BUF_TO_SP_PAYLOAD:
                
                STA ZP1_LO
                STY ZP1_HI
                
                LDX #$00
                LDY #$00
LOOK_FOR_NULL4:
                LDA (ZP1),Y
                STA SP_PAYLOAD+4,X 
                BEQ GOT_LENGTH4
                INY
                INX
                CLC
                BCC LOOK_FOR_NULL4

GOT_LENGTH4:
                INX                     
                LDA #$00                ; NULL TERMINATE STRING
                STA SP_PAYLOAD+5,X

;                TXA
;                STA SP_PAYLOAD+4        ; STORE LENGTH

;                TAX                     ; RETURN LENGTH
                RTS

;******************************************************************
; FN_OPEN
; Open the specified UNIT, gets it ready for reading or writing
; 
; INPUT
; X = UNIT DESTINATION
;******************************************************************
FN_OPEN:

.IF .NOT STRIP_TRACE
                SAVE_REGS
                TXA
                PHA
                LDA TRACE_FLAG
                BEQ NO_TRACE20
                PRINT_STR FN_OPEN_STR_ADDR
                PRINT_STR UNIT_STR_ADDR
                PLA
                PHA
                TAX
                JSR PRTX
                LDA #SPACE
                JSR COUT

NO_TRACE20:     
                PLA           
                RESTORE_REGS
.ENDIF

                TXA                         ; X CONTAINS THE UNIT NUMBER
                PHA

                ; STAGE #1
                ; OPEN THE DEVICE #X
                JSR SP_OPEN 
                STA FN_LAST_ERR
                BCC CONT2
OPEN_ERR:

.IF .NOT STRIP_TRACE
                LDA #<OPEN_ERR_STR
                LDY #>OPEN_ERR_STR

                JSR STROUT
                JSR CROUT
.ENDIF
                PLA
                SEC
                LDX FN_LAST_ERR
                RTS

CONT2:
                PLA                         ; GET BACK UNIT NUMBER
                PHA
                TAX

; FUJINET SPECIFC
;Byte   Definition
; 'O'-open
;0-1    payload size
;2      mode read or write or both
;3      translation
;4...   url
                ; STAGE #2
                ; SET PAYLOAD SIZE
                LDY #$02                    ; PAYLOAD SIZE = $102 = 258 BYTES
                STY SP_PAYLOAD
                LDY #$01
                STY SP_PAYLOAD+1
       
                ; FILL PAYLOAD - Read/write mode
                LDA MODE                    ; READ OR WRITE OR BOTH
                STA SP_PAYLOAD+2
                
                ; FILL PAYLOAD - Character translation
                LDA TRANSLATION             ; CHARACTER TRANSLATION
                STA SP_PAYLOAD+3

                ; FILL PAYLOAD - Transfer BASIC URL to payload
                JSR CPY_URL_TO_SP_PAYLOAD   ; TRANSFER THE URL

.IF .NOT STRIP_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE21

                PRINT_STR MODE_STR_ADDR
                LDX MODE
                JSR PRINT_X

                PRINT_STR TRANS_STR_ADDR
                LDX TRANSLATION
                JSR PRINT_X
                
                PRINT_STR PAYLOAD_STR_ADDR
                JSR DUMP_SP_PAYLOAD        ; PRINT THE URL
                JSR CROUT
NO_TRACE21:              
                RESTORE_REGS
.ENDIF

                PLA                         ; GET BACK OUR DEVICE NUMBER
                TAX

                ; STAGE #3
                ; CALL FUJINET OPEN
                LDY #'O'                    ; SEND 'O' TO FUJINET
                JSR SP_CONTROL
                STA FN_LAST_ERR
                BCC OPEN_OK2
CTRL_ERR:

.IF .NOT STRIP_TRACE
                LDA #<CTRL_ERR_STR
                LDY #>CTRL_ERR_STR
                JSR STROUT
                JSR CROUT
.ENDIF
                SEC
                LDX FN_LAST_ERR
                RTS

OPEN_OK2:
                LDX FN_LAST_ERR
                RTS


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

;******************************************************************
; FN_READ
; Read the specified UNIT
;
; INPUT
; X = UNIT DESTINATION
;******************************************************************

FN_READ:

.IF .NOT STRIP_TRACE
                SAVE_REGS
                TXA
                PHA
                LDA TRACE_FLAG
                BEQ NO_TRACE22

                PRINT_STR FN_READ_STR_ADDR
                PRINT_STR UNIT_STR_ADDR
                PLA
                PHA
                TAX
                JSR PRTX
                JSR CROUT
NO_TRACE22:     
                PLA          
                RESTORE_REGS

.ENDIF
                ; X = DEVICE
                LDY BUFLEN              ; MAX PAYLOAD IS 255         
                JSR SP_READ
                STA FN_LAST_ERR
                BCC READ_OK


READ_ERR:


.IF .NOT STRIP_TRACE                
                PRINT_STR FN_READ_ERROR_STR_ADDR
                JSR DUMP_SP_PAYLOAD
.ENDIF

                LDX FN_LAST_ERR
                CLC
                BCC READ_DONE
READ_OK:
   
                LDX FN_LAST_ERR
READ_DONE:
                LDY SP_COUNT
                LDA SP_ERR
                RTS

;******************************************************************
; FN_CLOSE
; Close the specified UNIT
;
; INPUT
; X = UNIT DESTINATION
;******************************************************************
FN_CLOSE:

.IF .NOT STRIP_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE33
                TXA
                PHA
                PRINT_STR FN_CLOSE_STR_ADDR
                PRINT_STR UNIT_STR_ADDR
                PLA
                TAX
                JSR PRTX
                JSR CROUT
NO_TRACE33:                
                RESTORE_REGS
.ENDIF

                TXA
                PHA
                
                LDY #$00                ; PAYLOAD SIZE = ZERO
                STY SP_PAYLOAD
                STY SP_PAYLOAD+1
                
                LDY #'C'                ; SEND 'C' TO FUJINET
                JSR SP_CONTROL
                STA FN_LAST_ERR
                BCC CLOSE_OK

                PLA
                LDX #$FF

.IF .NOT STRIP_TRACE                
                PRINT_STR CLOSE_ERROR_STR_ADDR
.ENDIF

                CLC
                BCC CLOSE_DONE
CLOSE_OK:
                PLA
                TAX
                JSR SP_CLOSE

                LDX #FN_OK
CLOSE_DONE:
                RTS

;******************************************************************
; FN_IS_CONNECTED
; Is this unit connected to a site
;
; INPUT
; X = UNIT DESTINATION
; RETURN
; A = 1 IF CONNECTED, 0 IF NOT
;******************************************************************
; X = DEVICE

;bool isConnected(void)
;{
;  sp_status(net,'S');
;  return sp_payload[2] & 0x02; // Bit 2 = Connected?
;}

FN_IS_CONNECTED:

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE23
                TXA
                PHA
                PRINT_STR FN_IS_CONNECTED_STR_ADDR
                PRINT_STR UNIT_STR_ADDR
                PLA
                TAX
                JSR PRTX

NO_TRACE23:                
                RESTORE_REGS
.ENDIF
.ENDIF

                LDY #'S'
                JSR SP_STATUS
                STA FN_LAST_ERR
                BCC CONNECT_CONT
                LDX #$FF
                RTS

CONNECT_CONT:
                LDX #FN_OK
                LDA SP_PAYLOAD+2
                AND #$02
                ROR

.IF EXT_TRACE
                SAVE_REGS
                TAX
                JSR PRTX
                JSR CROUT
                RESTORE_REGS
.ENDIF
                RTS

;******************************************************************
; FN_BYTES_WAITING
; Number of characters in the buffer
;
; INPUT
; X = UNIT DESTINATION
;******************************************************************
FN_BYTES_WAITING:

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                SAVE_REGS
                TXA
                PHA
                LDA TRACE_FLAG
                BEQ NO_TRACE24

                PRINT_STR FN_BYTES_WAITING_STR_ADDR
                PLA
                PHA
                TAX
                JSR PRTX

NO_TRACE24:     
                PLA           
                RESTORE_REGS
.ENDIF
.ENDIF

;  sp_status(net,'S');
;
;  bw = sp_payload[0];
;  bw |= (sp_payload[1]) << 8;
;
;  if (bw==0)
;    return;
                LDY #'S'
                JSR SP_STATUS
                STA FN_LAST_ERR
                BCC BW_OK
BW_ERROR:                
                LDX #$FF
                BCS BW_DONE
BW_OK:
                LDA SP_PAYLOAD
                LDY SP_PAYLOAD+1
.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                PHA
                TYA
                TAX
                PLA
                JSR PRTAX
                LDA SP_PAYLOAD
                LDY SP_PAYLOAD+1
.ENDIF
.ENDIF

BW_DONE:
                RTS
        
;******************************************************************
; FN_FIND_NETWORK
; Return the Unit number for a device
;
; INPUT
;   A = High byte address of string
;   Y = Low byte address of string
;   X = Device number or $FF on failure
;******************************************************************
FN_FIND_NETWORK:

.IF .NOT STRIP_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE25
                PRINT_STR FN_FIND_NETWORK_STR_ADDR
NO_TRACE25:                
                RESTORE_REGS
.ENDIF

                LDA BASIC_UNIT
                CMP #$01
                BPL MULTI_NETWORK

                ; LOOK FOR "NETWORK"
                LDA NETWORK_STR_ADDR+1
                LDY NETWORK_STR_ADDR
            
                JSR SP_FIND_DEVICE          ; LOOK FOR "NETWORK"
                CPX #$FF
                BNE FIND_COMPLETED

MULTI_NETWORK:
                ; IF WE'RE HERE, THEN WE DIDN'T FIND "NETWORK"
                ; OR A UNIT NUMBER GREATER THAN ZERO WAS SPECIFIED.
                ; LOOK FOR "NETWORK_X"

                LDA BASIC_UNIT
                CLC
                ADC #'0'
                
                LDX NETWORK_STR_WITH_NUMBER_INDEX
                STA NETWORK_STR_WITH_NUMBER,X

                LDA NETWORK_STR_WITH_NUMBER_ADDR+1
                LDY NETWORK_STR_WITH_NUMBER_ADDR

                JSR SP_FIND_DEVICE              ; LOOK FOR "NETWORK_X" WHERE X IS 0-3

FIND_COMPLETED:

                RTS


FN_LIST:
;*******************************
; FN_LIST
;   Transfer devices into a buffer
;**********************************
                LDX #$00
                LDY #SP_CMD_STATUS
                JSR SP_STATUS

                LDX DCOUNT
                INX
                STX NUM_DEVICES

                LDX #$01
                LDY #$00
                STY STRLEN
NEXT_DEV1:               
                TXA
                PHA

                LDY #SP_STATUS_DIB      ; X = DEVICE 
                JSR SP_STATUS
                STA FN_LAST_ERR
                BCS FN_LIST_ERROR_OUT   ; SHOULD NEVER HAPPEN, BUT IF IT DOES, JUST EXIT

                LDX #$00              
NEXT_CHAR:
                LDA SP_PAYLOAD+5,X
                LDY STRLEN
                STA STRBUF,Y
                INX
                INC STRLEN
                CPX SP_PAYLOAD+4        ; ARE WE AT END OF STRING (NOT NULL TERMINATED)
                BNE NEXT_CHAR
                    
                LDA #','                 ; ADD A COMMA
                LDY STRLEN
                STA STRBUF,Y
                INC STRLEN

                PLA                     ; MOVE TO NEXT DEVICE
                TAX
                INX
                CPX NUM_DEVICES         ; HAVE WE EXCEEDED DEVICE LIST?
                BNE NEXT_DEV1

FN_LIST_OK:
                DEC STRLEN
                LDX STRLEN
                LDA #$00
                STA STRBUF,X            ; REMOVE THE LAST COMMA
                LDX #FN_OK
                CLC
                RTS

FN_LIST_ERROR_OUT:

                PLA

                LDX #$FF
                SEC
                RTS


