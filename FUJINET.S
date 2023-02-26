;*****************************************************
; FUJINET.S
; BASIC to Fujinet
; By Norman Davie

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

;******************************************************************
; CPY_URL_TO_SP_PAYLOAD
; Copy the BASIC URL into the Smartport buffer
;
; CPY_STR_TO_SP_PAYLOAD
; Copy the zero terminated string to the Smartport buffer
;
; INPUT
;  A = high address
;  Y = low address
; RETURNS
;  X = String length
;******************************************************************

CPY_URL_TO_SP_PAYLOAD:

                LDA URL_ADDR+1
                LDY URL_ADDR
                
CPY_STR_TO_SP_PAYLOAD:
                STA ZP1_LO
                STY ZP1_HI
                
                LDX #$00
                LDY #$00
LOOK_FOR_NULL2:
                LDA (ZP1),Y
                STA SP_PAYLOAD+4,X 
                BEQ GOT_LENGTH2
                INY
                INX
                CLC
                BCC LOOK_FOR_NULL2

GOT_LENGTH2:
                INX
                LDA #$00
                STA SP_PAYLOAD+4,X

                RTS

;******************************************************************
; FN_OPEN
; Open the specified UNIT
;
; INPUT
; X = UNIT DESTINATION
;******************************************************************
FN_OPEN:

.IF .NOT STRIP_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE20
                TXA
                PHA
                PRINT_STR FN_OPEN_STR_ADDR
                LDA #' '
                JSR COUT
                PRINT_STR UNIT_STR_ADDR
                PLA
                TAX
                JSR PRTX
                JSR CROUT

NO_TRACE20:                
                RESTORE_REGS
.ENDIF

                TXA                         ; X CONTAINS THE UNIT NUMBER
                PHA

                ; OPEN THE DEVICE #X
                JSR SP_OPEN 
                BCS OPEN_ERR

                PLA                         ; GET BACK UNIT NUMBER
                PHA
                TAX

                ; CONNECT TO URL
                LDY #$02                    ; PAYLOAD SIZE = $102 = 258 BYTES
                STY SP_PAYLOAD
                LDY #$01
                STY SP_PAYLOAD+1
       
                LDA MODE                    ; READ OR WRITE OR BOTH
                STA SP_PAYLOAD+2
                
                LDA TRANSLATION             ; CHARACTER TRANSLATION
                STA SP_PAYLOAD+3

                JSR CPY_URL_TO_SP_PAYLOAD   ; TRANSFER THE URL

                PLA                         ; GET BACK OUR DEVICE NUMBER
                TAX
                LDY #'O'                    ; SEND 'O' TO FUJINET
                JSR SP_CONTROL
                BCS CTRL_ERR

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
                JSR PRINT_SP_PAYLOAD    ; PRINT THE URL
                JSR CROUT
NO_TRACE21:              
                RESTORE_REGS
.ENDIF


                RTS
CTRL_ERR:
                LDA #<CTRL_ERR_STR
                LDY #>CTRL_ERR_STR
                CLC
                BCC OPEN_ERR_DONE
OPEN_ERR:
                LDA #<OPEN_ERR_STR
                LDY #>OPEN_ERR_STR

OPEN_ERR_DONE:
                JSR STROUT
                JSR CROUT
                PLA
                SEC
                LDX #FN_ERR_NETWORK_DOWN
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
                BEQ NO_TRACE22
                TXA
                PHA
                PRINT_STR FN_CLOSE_STR_ADDR
                LDA #' '
                JSR COUT
                PRINT_STR UNIT_STR_ADDR
                PLA
                TAX
                JSR PRTX
                JSR CROUT
NO_TRACE22:                
                RESTORE_REGS
.ENDIF

                TXA
                PHA
                JSR SP_CLOSE
                
                LDY #$00                ; PAYLOAD SIZE = $102 = 258 BYTES
                STY SP_PAYLOAD
                STY SP_PAYLOAD+1
                
                PLA                     ; GET BACK OUR DEVICE NUMBER
                TAX
                LDY #'C'                ; SEND 'C' TO FUJINET
                JSR SP_CONTROL

                RTS


;******************************************************************
; FN_IS_CONNECTED
; Is this unit connected to a site
;
; INPUT
; X = UNIT DESTINATION
;******************************************************************
; X = DEVICE
FN_IS_CONNECTED:

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                SAVE_REGS
                LDA TRACE_FLAG
                BEQ NO_TRACE23
                TXA
                PHA
                PRINT_STR FN_IS_CONNECTED_STR_ADDR
                JSR COUT
                PRINT_STR UNIT_STR_ADDR
                PLA
                TAX
                JSR PRTX
                JSR CROUT

NO_TRACE23:                
                RESTORE_REGS
.ENDIF
.ENDIF

                LDY #'S'
                JSR SP_STATUS
                LDA SP_PAYLOAD+2
                AND #$02
                ROR
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
                LDA TRACE_FLAG
                BEQ NO_TRACE24
                TXA
                PHA
                PRINT_STR FN_BYTES_WAITING_STR_ADDR
                JSR COUT
                PRINT_STR UNIT_STR_ADDR
                PLA
                TAX
                JSR PRTX
                JSR CROUT

NO_TRACE24:                
                RESTORE_REGS
.ENDIF
.ENDIF
                LDY #'S'
                JSR SP_STATUS
                LDA SP_PAYLOAD
                LDY SP_PAYLOAD+1
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

                LDA NETWORK_STR_ADDR+1
                LDY NETWORK_STR_ADDR
            
                JSR SP_FIND_DEVICE

                RTS
