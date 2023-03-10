;*****************************************************
; FUJIAPPLE
; Ampersand extension for Fujinet commands
; By Norman Davie
;
; VERSION: 1.06 - updated to use ca65
;
; NOTES:
;   If you set USE_TRACE a large about of debug info will be included
; You can turn on and off the debug messages using &NTRACE and &NNOTRACE
;   If you want to test your code without a smartport card (for emulators)  
; you can set USE_SP 
;
; With ca65 task
;{
;    "version": "2.0fnet.0",
;    "tasks": [
;        {
;            "label": "ca65: Compile and Link Current File",
;            "group": "build",
;            "type": "shell",
;            "command": " cl65 -v -t apple2 -C apple2-asm.cfg  \"${file}\"",
;            "problemMatcher": [
;                "$ca65",
;                "$ld65",
;                "$ld65-config",
;                "$ld65-unresolved"
;            ]
;        }
;    ]
;}

; If you don't set STRIP_TRACE=1, then &NTRACE and &NNOTRACE
; keywords are active and a bunch of strings are included
; in the code making it quite large.
; These keywords show information regarding the BASIC and
; FN_???? functions being called.
;
; EXT_TRACE and EXT2_TRACE includes calls into the SMARTPORT routines

STRIP_TRACE= 1  ; Eliminate all tracing code and strings
TRACE_ON   = 1  ; &NTRACE is on at the very start
EXT_TRACE  = 1  ; Extended Trace, 1=display SMARTPORT internal debug messages 
EXT2_TRACE = 1  ; Extended Trace 2, display SP_STATUS and CALL_DISPATCHER
RELOCATE   = 0  ; 1=relocate himem and put our code there
PRODOS     = 1  ; 0=add dos 3.3 header
APPLEII    = 1  ; always set to one, EQUs will be for apple zero page
USE_SP     = 0  ; 1=USE ACTUAL SMARTPORT 0=EMULATE SMARTPORT FUNCTIONS

SMALL_TEST = 0  ; Test only one small specific code


START      = $2000


.IF PRODOS

        .ORG START

; NO HEADER FOR PRODOS

.ELSE

; WE SUBRACT 4 TO ALLOW ROOM FOR THE ADDRESS AND LENGTH FIELDS AT THE START OF THE FILE

        .ORG START - 4 

; HEADER FOR BINARY FILES ON DOS 3.3

        .WORD NINIT                             ; Starting address
        .WORD (ENDOFFILE - RELOCATE_CODE_START) ; Length

.ENDIF
; VARIOUS SYSTEM ROUTINES AND LOCATIONS 


        .include "APPLEEQU.S"
        .include "ZEROPAGE.S"
        .include "MACROS.S"


TOK_READ                =       135       ; APPLESOFT TOKEN FOR READ
TOK_AT                  =       197       ; APPLESOFT TOKEN FOR AT
TOK_END                 =       128       ; APPLESOFT TOKEN FOR END
QUOTE                   =       $22       ; ASCII QUOTE CHARACTER
TOK_LIST                =       188       ; APPLESOFT TOKEN FOR LIST                          
TOK_TRACE               =       155       ; APPLESOFT TOKEN FOR TRACE       
TOK_NOTRACE             =       156       ; APPLESOFT TOKEN FOR NOTRACE

;*********************************************************                           

STARTOFFILE:

NINIT:

.IF SMALL_TEST

        LDA #<FUJIAPPLE_VER_STR                 ; "VERSON: YYYYMMDD.HHMM" - FILLED BY PYTHON SCRIPT
        LDY #>FUJIAPPLE_VER_STR
        JSR  STROUT

        LDA #<TEST_STR
        LDY #>TEST_STR
        JSR STROUT

        JSR GET_SMARTPORT_DISPATCH_ADDRESS      ; FIND THE ADDRESS

        JSR FN_FIND_NETWORK
        TXA
        PHA
        TAX
        JSR FN_OPEN
        JSR PRINT_REGS

        PLA
        PHA
        TAX
        JSR FN_BYTES_WAITING

        PLA
        TAX
        JSR FN_IS_CONNECTED
        JSR PRTAX

        RTS

TEST_STR:    
        .BYTE "<><><><><>SMALL TEST MODE<><><><><><>", $0D,$00

.ENDIF


                LDA CIDERPRESS_CORRUPTION_TEST
                CMP #$0A
                BEQ NOT_CORRUPTED
                LDA #<CIDERPRESS_CORRUPTION_TEST
                LDY #>CIDERPRESS_CORRUPTION_TEST
                JSR STROUT
                RTS

NOT_CORRUPTED:

                ; FIND ALL THE NETWORK ADAPTERS
                ; 0 IS "NETWORK" OR "NETWORK_0"
                ; 1-3 IS "NETWORK_1" OR 2, OR 3






.IF .NOT STRIP_TRACE
.IF TRACE_ON
                JSR NTRACE
.ELSE
                JSR NNOTRACE
.ENDIF
.ENDIF

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                LDA #<FUJIAPPLE_VER_STR                 ; "VERSON: YYYYMMDD.HHMM" - FILLED BY PYTHON SCRIPT
                LDY #>FUJIAPPLE_VER_STR
                JSR  STROUT
.ENDIF
.ENDIF
                JSR GET_SMARTPORT_DISPATCH_ADDRESS      ; FIND THE ADDRESS

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                SAVE_REGS
                PRINT_STR DISPATCHER_ADDRESS_STR_ADDR
                JSR PRTAX
                JSR CROUT
                RESTORE_REGS
.ENDIF
.ENDIF
                LDA DISPATCHER_ADDR_HI
                CMP #$FF                                ; WAS THE CARD FOUND?
                BNE FOUND_SMARTPORT

                LDA #<SP_NOT_FOUND_STR                  ; "SMARTPORT NOT FOUND!"
                LDY #>SP_NOT_FOUND_STR
                JSR STROUT



                LDX #$00
NEXT_NETWORK_CACHE:
                STX BASIC_UNIT 
                JSR FN_FIND_NETWORK
                
                LDX BASIC_UNIT
                TYA
                STA NETWORK_CACHE,X

                INX
                CPX #$04
                BNE NEXT_NETWORK_CACHE

.IF EXT_TRACE
                LDA #<EXITING_STR
                LDY #>EXITING_STR
                JSR STROUT
.ENDIF

BYE:
                RTS


FOUND_SMARTPORT:

; RELOCATE US TO WHERE IT'S SAFE

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                JSR CROUT               ; CARRIAGE RETURN
                LDA #<HIMEM_IS_STR          ; "HIMEM IS:"
                LDY #>HIMEM_IS_STR
                JSR STROUT

                LDA HIMEM+1
                STA OLDHIMEM+1          ; KEEP TRACK OF HIMEM
		LDX HIMEM
                STX OLDHIMEM
		JSR PRTAX               ; PRINT ADDRESS
.ENDIF
.ENDIF

.IF RELOCATE
		JSR ADJUST_HIMEM        ; Move HIMEM so we can put our code at it. 
.ENDIF

.IF .NOT STRIP_TRACE
		LDA #<RELOCATING_STR    ; "RELOCATING TO:"
		LDY #>RELOCATING_STR
		JSR STROUT
.ENDIF

		LDA HIMEM+1
		LDX HIMEM

.IF .NOT STRIP_TRACE
		JSR PRTAX               ; PRINT NEW HIMEM ADDRESS
                JSR CROUT
.ENDIF

.IF RELOCATE
                JSR RELOCATE_TO_HIMEM   ; copy the code and data, adjust all absolute addresses
.ENDIF

.IF RELOCATE

.IF .NOT STRIP_TRACE
.IF EXT_TRACE
                LDA #<RELOC_SIZE_STR        ; "CODE SIZE:"
                LDY #>RELOC_SIZE_STR
                JSR STROUT

                LDX #<(RELOCATE_DATA_END - RELOCATE_CODE_START)
                LDA #>(RELOCATE_DATA_END - RELOCATE_CODE_START)
                JSR PRTAX               ; PRINT SIZE
                JSR CROUT

.ENDIF
.ENDIF

.ENDIF

; SAVE PREVIOUS VECTOR INFO

SAVEVECT:

                LDA AMPVECT
                STA PREVECT
                LDA AMPVECT+1
                STA PREVECT+1
                LDA AMPVECT+2
                STA PREVECT+2

; UPDATE THE AMPERSAND VECTOR TO OUR ROUTINE

                LDA #$4C                ; JMP
                STA AMPVECT
                LDA RELOC_FUJIAPPLE     ; SET THE AMPERSAND VECTOR
                STA AMPVECT+1
                LDA RELOC_FUJIAPPLE+1
                STA AMPVECT+2
        
; ANNOUNCE OUR SUCCESS

                LDA #<EXTADDED_STR          ; "FUJINET EXTENSION ADDED"
                LDY #>EXTADDED_STR          
                JSR STROUT

.IF .NOT USE_SP
                PRINT_STR FAKE_SMARTPORT_STR_ADDR
.ENDIF

.IF PRODOS
                RTS
.ELSE
                JMP DOSWARM             ; WARM START DOS-NEEDED FOR BRUN
.ENDIF


RELOCATE_CODE_START:
;****************************************
; THIS IS USED TO DETERMINE IF THE
; EXTENSIONS HAVE ALREADY BEEN INSTALLED
; (R=1)
;****************************************
;10000 REM *************************
;10010 REM DETERMINE IF FUJI EXTENSIONS
;10015 REM HAVE BEEN INSTALLED (R=1)
;10020 REM *************************
;10030 X = PEEK(1014)+PEEK(1015)*256
;10040 X = X - 1
;10050 C = PEEK(X): IF C = 0 OR C > 20 THEN 10080
;10060 X = X - C - 1
;10070 A$=""
;10080 FOR Y = 1 TO C: A$=A$+CHR$(PEEK(X)):X=X+1:NEXT Y
;10090 B$ = "FUJIAMP"
;10100 PRINT A$;"--";B$;"?";
;10130 IF A$=B$ THEN R=1: PRINT "YES":GOTO 10150
;10140 R=0:PRINT "NO"
;10150 RETURN

;****************************************
                .ASCIIZ "FUJIAMP"
                .BYTE 7
;****************************************
; NSTART - FUJINET EXTENSION START
;   THIS IS THE ENTRY POINT OF THE AMPERSAND ROUTINE
;   CHECK FOR OUR COMMANDS AND EXECUTE IF FOUND
;   IF IT DOESN'T MATCH OUR COMMANDS, THEN
;   GO TO THE PREVIOUS AMPERSAND ROUTINE
;****************************************

NSTART:
                LDX #$00
NEXTCMD:
                LDY #$00       ; INDEX INTO TXTPTR
                LDA COMMANDS,X ; COMMAND TEXT IN TABLE
                BEQ NOMORECMDS ; WE'VE EXAUSTED OUR CMD LIST
COMP:
                LDA COMMANDS,X
                CMP (TXTPTR),Y ; DOES COMMAND TEXT MATCH?
                BNE SKIPCMD    ; IT'S NOT A MATCH
                INY              ; MOVE TO NEXT CHARACTER
                INX
                LDA COMMANDS,X ; IS THE CHARACTER A NULL?
                BNE COMP       ; NOPE, COMPARE NEXT CHARACTER
                BEQ FOUNDCMD   ; YES, WE'VE FOUND OUR COMMAND
SKIPCMD:
                INX             ; MOVE TO THE NEXT CHARACTER
                LDA COMMANDS,X  ; KEEP READING UNTIL NULL
                BNE SKIPCMD
                INX             ; IGNORE THE NULL
                INX             ; IGNORE THE ADDRESS
                INX

                CLC
                BCC NEXTCMD     ; CHECK NEXT CMD
FOUNDCMD:
                TXA
                PHA
RMCMD:
                JSR CHRGET      ; REMOVE CHAR FROM BASIC
                DEY
                BNE RMCMD

                PLA
                TAX

; PUSHADDR ON STACK AND "RETURN" TO OUR ROUTINE

                INX
                LDA COMMANDS+1,X
                PHA
                LDA COMMANDS,X
                PHA             ; ADDRESS OF OUR ROUTINE IS ON STACK

                RTS             ; "RETURN" (JMP) TO ADDRESS ON STACK

; IF WE'RE HERE, IT'S NOT ONE OF OUR COMMANDS
; JUMP TO THE PREVIOUS VECTOR AND LET IT PROCESS IT

NOMORECMDS:

.IF .NOT STRIP_TRACE
.IF EXT_TRACE

                PRINT_STR NOT_FOUND_STR_ADDR  ; "COMMAND NOT FOUND"
                JSR CROUT

.ENDIF
.ENDIF

                JMP   PREVECT    ; WE DIDN'T FIND OUR COMAND SO GO TO OLD VECTOR

DISPLAY_OPENS:
                SAVE_REGS
                PRINT_STR NETWORK_STR_ADDR
                LDA #COLON 
                JSR COUT

                LDY #$00

NEXT_OPEN:
                LDA OPEN_LIST,Y
                TAX
                JSR PRTX
                INY
                CPY #$04
                BNE NEXT_OPEN
                JSR CROUT
                RESTORE_REGS
                RTS

DISPLAY_NERRS:
                SAVE_REGS
                PRINT_STR SP_ERROR_STR_ADDR
                LDA #COLON 
                JSR COUT

                LDY #$00

NEXT_NERR:
                LDA NERR,Y
                TAX
                JSR PRTX
                INY
                CPY #$04
                BNE NEXT_NERR
                JSR CROUT
                RESTORE_REGS
                RTS
;*********************************
; GETSTR - GETS A STATIC STRING ("BLAH")
; INPUT:
;   TXTPTR IS AT THE START OF THE STRING IN BASIC
; RETURNS:
;   STRING IS COPIED INTO STRBUF AND TERMINATED WITH A NULL
;   STRING LENGTH IS STORED IN STRLEN
; NOTE:
;    CHRGET CONSUMES SPACES SILENTLY, WHICH IS WHY
;    WE DON'T USE IT TO COLLECT THE STRING
;***********************************

GETSTR:                         ; GET STATIC STRING
                LDY #01
CONSUME:
                LDA (TXTPTR),Y  ; GET CHARACTER FROM BASIC
                CMP #QUOTE      ; WE NEED TO STOP ON THE ENDING QUOTE
                BEQ NULLSTR1    ; WE'RE DONE

                STA STRBUF-1,Y  ; SAVE THE CHARACTER
                INY
                CLC
                BCC CONSUME     ; GET THE NEXT CHARACTER
NULLSTR1:
                LDA #00
                STA STRBUF-1,Y  ; TERMINATE THE STRING WITH A NULL
                DEY
                STY STRLEN      ; SAVE THE LENGTH OF THE STRING
                JSR CHRGET
GOBBLE:
                JSR CHRGET      ; GET THE CHARACTER FROM BASIC
                CMP #QUOTE      ; HAVE WE FOUND THE ENDING QUOTE?
                BEQ COMPLETED   ; WE'RE DONE
                INY
                CLC
                BCC GOBBLE

COMPLETED:
                JSR CHRGET     
                RTS

;*******************************************
; GETSTRVAR - GET STRING VARIABLE
; RETURNS:
;   STRING LENGTH IN DSCTMP
;   STRING ADDR LO IN DSCTMP+1
;   STRING ADDR HI IN DSCTMP+2
;*********************************
GETSTRVAR:
                JSR PTRGET     ; GET STRING DESCRIPTOR
                LDY #0
                LDA (VARPTR),Y ; STRING LENGTH
                STA DSCTMP
                INY
                LDA (VARPTR),Y ; ADDR LO
                STA DSCTMP+1
                INY
                LDA (VARPTR),Y ; ADDR HI
                STA DSCTMP+2
                RTS
;*********************************
;*******************************
; BYTESAV - CONVERT BYTE TO FLOAT
;           AND STORE IN VARIABLE
; INPUT:
;   Y - BYTE TO STORE
;***
; WOR.RESAV - CONVERT WORD TO FLOAT AND STORE IN VARIABLE
; INPUT:
;   A - WORD HI
;   Y - WORD LO
;***
; RETURN
;   BOTH ROUTINES RETURN:
;   FLOAT STORED INTO VARIABLE
;**********************************
BYTESAV:
                LDA #0
WORDSAV:
                JSR GIVAYF     ; CONVERT TO FLOATING POINT
                JSR PTRGET     ; FIND ADDRESS OF THE VARIABLE
                TAX
                JSR MOVMF      ; STORE VALUE INTO VARIABLE
                RTS
;*************************************
; DISPLAY INTERNAL STATE
;*************************************
DISPLAY_INTERNAL_STATE:

                SAVE_REGS
                LDX BASIC_UNIT
                JSR PRINT_X
                LDX MODE
                JSR PRINT_X
                LDX TRANSLATION
                JSR PRINT_X
                JSR CROUT
                LDA #'"'
                JSR COUT
                PRINT_STR URL_ADDR
                LDA #'"'
                JSR COUT
                JSR CROUT

                LDX URL_LEN
                JSR PRINT_X

                LDX COMMAND
                JSR PRINT_X
                JSR CROUT

                LDX NETWORK_CACHE
                JSR PRINT_X
                LDX NETWORK_CACHE+1
                JSR PRINT_X
                LDX NETWORK_CACHE+2
                JSR PRINT_X
                LDX NETWORK_CACHE+3
                JSR PRINT_X
                JSR CROUT

                RESTORE_REGS
                RTS

;*************************************
;*************************************
;*************************************
;*************************************

IGNORE_TO_NEXT_BASIC_STATEMENT:
                JSR CHRGOT              
                BEQ RETURN_TO_BASIC     ; 0 = END OF LINE
                CMP #':'
                BEQ RETURN_TO_BASIC

                JSR CHRGET
                CLC
                BCC IGNORE_TO_NEXT_BASIC_STATEMENT

RETURN_TO_BASIC:
                RTS

NOPEN:
; &NOPEN UNIT,MODE,TRANS,URL$
; &NOPEN UNIT,MODE,TRANS,"URL"
;
; Opens a specified URL for use.
;
; UNIT = 0-4 BASIC NETWORK (not Fujinet unit number)
; MODE = 04-READ ONLY
;        06-READ DIRECTORY
;        08-WRITE ONLY
;        0C-READ AND WRITE
;        0E-HTTP POST
; TRANS= 0-NO TRANSLATION
;        1-CR TO CR (yeah, does nothing)
;        2-LF TO CR 
;        3-CR/LF TO CR

.IF .NOT STRIP_TRACE
                LDA TRACE_FLAG
                BEQ NO_TRACE1
                PRINT_STR NOPEN_STR_ADDR        ; "NOPEN"
NO_TRACE1:
.ENDIF

                JSR GETBYT                      ; GET THE BASIC UNIT
                STX BASIC_UNIT        

.IF .NOT STRIP_TRACE
                LDA TRACE_FLAG
                BEQ NO_TRACE32
                SAVE_REGS
                JSR PRTX
                JSR CROUT
                RESTORE_REGS
NO_TRACE32:
.ENDIF
                CPX #$04                        ; BASIC UNIT HAS TO BE BETWEEN 0-3
                BMI UNIT_OK1                    ; OUT OF RANGE?

                LDX #ILLEGAL_QUANTITY_ERROR     ; MUST BE BETWEEN 0 AND 3
                JMP APPLESOFT_ERROR
               
UNIT_OK1:
                LDX BASIC_UNIT
                CPX #FN_ERR                     ; NETWORK WAS NOT FOUND!
                BNE NOPEN_NETWORK_FOUND

NO_NETWORK_ERROR:
                LDA #FN_ERR_SERVICE_NOT_AVAILABLE       ; CAN'T FIND THE SPECIFIED NETWORK (E.G. NETWORK_1 WAS NOT FOUND)
                STA NERR,X                              ; RECORD THE ERROR
                LDA #FN_ERR                             ; INDICATE THIS BASIC_UNIT IS CLOSED
                STA OPEN_LIST,X
                JSR IGNORE_TO_NEXT_BASIC_STATEMENT
                RTS

NOPEN_NETWORK_FOUND:
                ; NETWORK: WW XX YY ZZ - WHERE EACH BYTE IS THE ACTUAL UNIT NUMBER

                LDX BASIC_UNIT                  ; LOAD THE "BASIC" UNIT NUMBER
                LDA NETWORK_CACHE,X
                STA OPEN_LIST, X                     ; STORE THE ACTUAL UNIT NUMBER FOR LATER USE

                JSR CHKCOM
                JSR GETBYT                      ; GET MODE
                STX MODE

                JSR CHKCOM
                JSR GETBYT                      ; GET TRANS
                STX TRANSLATION

                JSR CHKCOM
                JSR CHRGOT                      ; WHAT ARE WE POINTING AT IN BASIC
                CMP #QUOTE                      ; IS IT A STATIC STRING?
                BNE VARSTR

                JSR GETSTR                      ; GETS THE STATIC STRING, STORED IN STRBUF

; WE'RE GOING TO CREATE A NEW DESCRIPTION
; THE SAME WAY APPLESOFT DOES

                LDA STRLEN                      ; GETSTR STORES THE STRING LENGTH HERE
                STA DSCTMP

                LDA STRBUF_ADDR                 ; THE ADDRESS OF OUR STATIC STRING
                STA DSCTMP+1
                LDA STRBUF_ADDR+1
                STA DSCTMP+2
                
                CLC
                BCC STORE

VARSTR:
                JSR GETSTRVAR                   ; IT'S A STRING VARIABLE
STORE:
                LDY DSCTMP                      ; GET THE STRING LENGTH
                STY URL_LEN                     ; INCLUDE NULL AT END OF LENGTH
                DEY
STORING:
                LDA (DSCTMP+1),Y                ; TRANSER THE STRING TO THE URL BUFFER
                STA URL,Y
                DEY
                BPL STORING

                ; MAKE THE STRING C COMPATIBLE

                LDY URL_LEN
                LDA #0                          ; NULL TERMINATE THE STRING
                STA URL,Y

                INY                             ; INCLUDE THE NULL TERMINATOR TO THE LENGTH
                STY URL_LEN

                LDX BASIC_UNIT                  ; BASIC UNIT 0-4
                LDA OPEN_LIST,X                   ; FUJINET UNIT
                TAX
                JSR FN_OPEN
                BCC NOPEN_COMPLETE

                LDX BASIC_UNIT                  ; FAILED TO OPEN
                LDA #FN_NO_NETWORK              ; INDICATE THE NETWORK IS 
                STA OPEN_LIST,X                   ; NOT IN USE
                LDA FN_LAST_ERR
                STA NERR,X

NOPEN_COMPLETE:

                RTS
;*********************************************
NCLOSE:
; &NCLOSE UNIT
; Closes a network connection.

.IF .NOT STRIP_TRACE
                LDA TRACE_FLAG
                BEQ NO_TRACE2
                PRINT_STR NCLOSE_STR_ADDR       ; "NCLOSE"

NO_TRACE2:                
.ENDIF
                JSR   GETBYT                    ; GET THE UNIT
                STX   BASIC_UNIT

.IF .NOT STRIP_TRACE
                LDA TRACE_FLAG
                BEQ NO_TRACE34

                SAVE_REGS
                JSR PRTX
                JSR CROUT
                RESTORE_REGS
NO_TRACE34:
.ENDIF               


                LDX BASIC_UNIT
                LDA OPEN_LIST, X          ; THIS IS THE ACTUAL UNIT NUMBER
                CMP #FN_NO_NETWORK   ; CLOSING SOMETHING THAT IS NOT ACTUALLY OPEN  
                BEQ JUST_CLOSE
                TAX
                JSR FN_CLOSE

JUST_CLOSE:
                LDX BASIC_UNIT          ; SAVE ANY ERROR THAT OCCURED DURING CLOSE
                STA NERR,X

                LDA #FN_NO_NETWORK      ; REGARDLESS, INDICATE BASIC UNIT IS CLOSED
                STA OPEN_LIST, X
                RTS

;*********************************************
NREAD:

; &NREAD UNIT, VAR$, LEN
; Gets len number of bytes and puts them into string variable var$

.IF .NOT STRIP_TRACE
                LDA TRACE_FLAG
                BEQ NO_TRACE3
                PRINT_STR NREAD_STR_ADDR        ; "NREAD"
NO_TRACE3:                
.ENDIF
                JSR   GETBYT                    ; GET THE UNIT
                STX   BASIC_UNIT

.IF .NOT STRIP_TRACE
                LDA TRACE_FLAG
                BEQ NO_TRACE36
                SAVE_REGS
                JSR PRTX
                JSR CROUT
                RESTORE_REGS
NO_TRACE36:
.ENDIF

                JSR CHKCOM
                JSR PTRGET                      ; GET THE STRING TO RECEIVED OUR DATA

;Returns the address of variable contents in A-reg (high) and Y-reg (low), 
;as well as in VARPTR at $83.84. If a variable does not exist, it
;is created. TXTPTR points to the next character. 

                LDA VARPTR                      ; SAVE THE STRING DESCRIPTOR LOCATION 
                STA STR_DSC_LEN                 ; FOR LATER
                LDA VARPTR+1
                STY STR_DSC_LO
                LDA VARPTR+2
                STA STR_DSC_HI

                JSR CHKCOM
                JSR GETBYT                      ; GET THE NUMBER OF CHARACTERS TO READ 
                STX BUFLEN
                TXA


                LDX BASIC_UNIT                  ; CONVERT THE BASIC_UNIT TO THE FUJINET UNIT
                LDA OPEN_LIST,X
                CMP #FN_NO_NETWORK              ; $FF INDICATES IT WAS NEVER OPENED
                BNE UNIT_OK2

                LDA #FN_NO_NETWORK              ; RETURN ERROR THAT WE WERE NEVER CONNECTED
                STA NERR,X
                RTS

UNIT_OK2:
                TAX
                JSR FN_READ                     ; REQUEST THE DATA FROM FUJINET
                CPX #FN_ERR
                BNE TRANSFER_VALUES

NREAD_ERROR:
                STA NERR,X
                RTS

TRANSFER_VALUES:                
                ; TODO:
                ; Adjust BUFLEN to the actual amount of
                ; characters read

                ; MOVSTR
                ; Source must be in Y(HI) and X(LO)
                ; Destination must be in FRESPC ($71,$72)

                LDA STR_DSC_LEN                 ; RESTORE THE STRING DESCRIPTOR
                STA VARPTR                      ; THAT WE SAVED EARLIER SO WE
                LDA STR_DSC_LO                  
                STA VARPTR+1
                LDA STR_DSC_HI
                STA VARPTR+2

                LDA BUFLEN                      ; THIS IS THE ACTUAL NUMBER OF CHARS WE READ
                JSR STRINI                      ; CREATE NEW STRING OF LENGTH A

                LDY #$00
                LDA DSCTMP                      ; DESCRIPTOR FOR NEW STRING
                STA (VARPTR),Y                  ; UPDATE THE LENGTH
                INY
                LDA DSCTMP+1                    ; UPDATE THE LOCATION OF THE STRING
                STA (VARPTR),Y 
                INY
                LDA DSCTMP+2
                STA (VARPTR),Y

                ;JSR PRTAX
                ;JSR CROUT

                ;LDA SP_PAYLOAD_STR_ADDR+1
                ;LDX SP_PAYLOAD_STR_ADDR
                ;JSR PRTAX
                ;JSR CROUT

                LDA BUFLEN                      ; USE THE APPLESOFT ROUTINES TO
                LDY SP_PAYLOAD_ADDR+1           ; MOVE THE PAYLOAD INTO THE
                LDX SP_PAYLOAD_ADDR             ; ACTUAL STRING
                JSR MOVSTR                      ; COPY BUFFER TO STRING (VAR$)
                
                RTS

;*****************************************************
NWRITE:
; &NWRITE UNIT,VAR$,LEN
; &NWRITE UNIT,"STRING",LEN
; Gets len number of bytes and puts them into string variable var$

.IF .NOT STRIP_TRACE
                LDA TRACE_FLAG
                BEQ NO_TRACE4      
                PRINT_STR NWRITE_STR_ADDR       ; "NWRITE"
NO_TRACE4:
.ENDIF
                JSR   GETBYT                    ; GET UNIT
                STX   BASIC_UNIT

.IF .NOT STRIP_TRACE
                LDA TRACE_FLAG
                BEQ NO_TRACE37
                SAVE_REGS
                JSR PRTX
                JSR CROUT
                RESTORE_REGS
NO_TRACE37:
.ENDIF

                JSR   CHKCOM
                JSR   CHRGOT                    ; WHAT ARE WE POINTING AT IN BASIC?
                CMP   #QUOTE                    ; IS IT A STATIC STRING?
                BNE   GETVAR

                JSR   GETSTR                    ; GET THE STATIC STRING
                CLC
                BCC   STORE2

GETVAR:
                JSR   GETSTRVAR                 ; GET VAR$

STORE2:
                JSR   CHKCOM
                JSR   GETBYT                    ; GET LENGTH REQUESTED
                STX   BUFLEN

                LDY   BUFLEN
COPYBUF:
                LDA   (DSCTMP+1),Y
                STA   BUF,Y
                DEY
                BPL   COPYBUF

                LDX BASIC_UNIT
                LDA OPEN_LIST,X
                CMP #FN_NO_NETWORK
                BNE UNIT_OK5

                PRINT_STR NOT_OPENED_STR_ADDR
                JMP SYNERR

UNIT_OK5:
;****** TO DO *********
; BUF NOW CONTAINS DATA
; TO BE SENT
; CALL FUJINET
;**********************
                TAX
                JSR FN_WRITE

                RTS

 ;*****************************************************               
NCTRL:
; &NCTRL UNIT,COMMAND, PAYLOAD$
; Sends a specific control message to the network device 
; to do a special command. The payload for this command 
; is specified as the very last parameter.

.IF .NOT STRIP_TRACE
                LDA TRACE_FLAG
                BEQ NO_TRACE5
                PRINT_STR NCTRL_STR_ADDR        ; "NCTRL"
NO_TRACE5:
.ENDIF
                JSR GETBYT     ; GET UNIT
                STX BASIC_UNIT

.IF .NOT STRIP_TRACE
                LDA TRACE_FLAG
                BEQ NO_TRACE38
                SAVE_REGS
                JSR PRTX
                JSR CROUT
                RESTORE_REGS
NO_TRACE38:
.ENDIF

                JSR CHKCOM
                JSR GETBYT     ; GET COMMAND
                STX COMMAND

                JSR CHKCOM
                JSR CHRGOT     ; WHAT ARE WE POINTING AT IN BASIC?
                CMP #QUOTE     ; IS IT A STATIC STRING?
                BNE GETVAR3

                JSR GETSTR     ; GET THE STATIC STRING
                CLC
                BCC STORE3

GETVAR3:
                JSR GETSTRVAR

STORE3:

; MOVE STRING TO PAYLOAD
                LDY DSCTMP
CPY2BUF:
                LDA (DSCTMP+1),Y
                STA BASIC_PAYLOAD,Y
                DEY
                BPL CPY2BUF

                LDA BASIC_UNIT
                TAX
                LDA OPEN_LIST,X
                CMP #FN_NO_NETWORK
                BNE UNIT_OK4

                PRINT_STR NOT_OPENED_STR_ADDR
                JMP SYNERR
                
UNIT_OK4:
;****** TO DO *******
; UNIT, COMMAND ARE STORED
; AND PAYLOAD$ IS IN BASIC_PAYLOAD
; CALL FUJINET
;*******************
                RTS

;*******************************************
NSTATUS:
; &NSTATUS UNIT,BW,CONNECTED,NERR
; To get the status of network unit. BW = bytes waiting, 
; CONNECTED equals 1 if connect and NERR returns 
; the network error code

.IF .NOT STRIP_TRACE
                LDA TRACE_FLAG
                BEQ NO_TRACE6
                PRINT_STR NSTATUS_STR_ADDR
NO_TRACE6:                
.ENDIF
                JSR GETBYT
                STX BASIC_UNIT       ; STORE THE UNIT NUMBER

.IF .NOT STRIP_TRACE
                LDA TRACE_FLAG
                BEQ NO_TRACE39
                SAVE_REGS
                JSR PRTX
                JSR CROUT
                RESTORE_REGS
NO_TRACE39:
.ENDIF
                JSR CHKCOM

                LDX BASIC_UNIT
                LDA OPEN_LIST,X                
                CMP #FN_NO_NETWORK
                BNE INFO

                LDA #$FF                        ; USER HASN'T OPENED THE
                STA BW                          ; CONNECTION, SO JUST
                STA BW+1                        ; SET EVERYTHING TO -1/255
                STA NERR
                LDA #$00
                STA CONNECT                     ; NO CONNECTION
                CLC
                BCC SAVE_INFO

                ; we have a network

INFO:
                TAX
                
                JSR FN_STATUS           ; THIS SETS BW AND CONNECT              

SAVE_INFO:
                ; SEND TO BASIC
                LDA BW+1       ; NUMBER OF BYTES WAITING
                LDY BW
                JSR WORDSAV    ; CONVERT TO FLOAT AND STORE IN BW VAR

                JSR CHKCOM

                LDY CONNECT
                JSR BYTESAV    ; CONVERT TO FLOAT AND STORE IN CONNECT VAR

                JSR CHKCOM

                LDA BASIC_UNIT
                TAX

                LDA NERR,X 
                TAY
                JSR BYTESAV    ; CONVERT TO FLOAT AND STORE IN NERR VAR
                RTS

;*******************************************
NEND:
; &NEND
; Remove the fujiapple vector and
; put the original vector back

.IF .NOT STRIP_TRACE
                LDA TRACE_FLAG
                BEQ NO_TRACE7
                PRINT_STR NEND_STR_ADDR
NO_TRACE7:
.ENDIF

.IF RELOCATE

                LDA HIMEM
                CMP RELOC_FUJIAPPLE
                BNE NO_RESTORE
                LDA HIMEM+1
                CMP RELOC_FUJIAPPLE+1
                BNE NO_RESTORE

                PRINT_STR RESTORE_HIMEM_STR_ADDR

                LDA OLDHIMEM
                STA HIMEM
                LDA OLDHIMEM+1
                STA HIMEM+1

                JMP RESTORE_VECT

NO_RESTORE:
                PRINT_STR CANT_RESTORE_STR_ADDR

.ENDIF

;*****************************************************
RESTORE_VECT:

                LDA PREVECT
                STA AMPVECT
                LDA PREVECT+1
                STA AMPVECT+1
                LDA PREVECT+2
                STA AMPVECT+2

                PRINT_STR EXTREMOVED_STR_ADDR      ; LET THE USER KNOW
                RTS

;*******************************************
NLIST:
; &NLIST
; &NLIST A$
; Display devices

.IF .NOT STRIP_TRACE
                LDA TRACE_FLAG
                BEQ NO_TRACE8
                PRINT_STR NLIST_STR_ADDR
NO_TRACE8:                
.ENDIF

                JSR CHRGOT
                BEQ NO_ARG
                CMP #':'
                BEQ NO_ARG

                JSR FN_LIST

                JSR PTRGET                      ; GET THE STRING TO RECEIVED OUR DATA

                LDA STRLEN                      ; USE THE APPLESOFT ROUTINES TO
                JSR STRINI                      ; CREATE A NEW STRING OF APPROPRIATE SIZE

                LDY #$00
                LDA DSCTMP                      ; DESCRIPTOR FOR NEW STRING
                STA (VARPTR),Y                  ; UPDATE THE LENGTH
                INY
                LDA DSCTMP+1                    ; UPDATE THE LOCATION OF THE STRING
                STA (VARPTR),Y 
                INY
                LDA DSCTMP+2
                STA (VARPTR),Y

                LDY STRBUF_ADDR+1               ; MOVE OUR STRING BUFFER INTO THE
                LDX STRBUF_ADDR                 ; ACTUAL STRING
                JSR MOVSTR                      ; COPY BUFFER TO STRING (VAR$)
               
                RTS

NO_ARG:
                JSR DISPLAY_SP_DEVICES

                RTS


.IF .NOT STRIP_TRACE
;*******************************************
NTRACE:
; &NTRACE
; Display debug messages

                PRINT_STR NTRACE_STR_ADDR
             
                LDA #$01
                STA TRACE_FLAG

                RTS

;*******************************************
NNOTRACE:
; &NNOTRACE
; Display debug messages

                LDA #$00
                STA TRACE_FLAG

                RTS
.ENDIF

                .include "SMARTPORTCMDS.S"
                .include "FAKESMARTPORT.S"
                .include "FUJINET.S"

RELOCATE_CODE_END:

;***********
;***********
;***********
;* DATA SECTION
;***********
;***********
;***********


;**************************************

relocate000:
RELOC_FUJIAPPLE: .WORD NSTART

COMMANDS:
                .ASCIIZ "NOPEN"                 ; NOPEN
relocate001:    .WORD   NOPEN-1

                .BYTE   'N', TOK_READ, 00       ; NREAD
relocate002:    .WORD   NREAD-1

                .ASCIIZ "NWRITE"                ; NWRITE
relocate003:    .WORD   NWRITE-1

                .ASCIIZ "NCTRL"                 ; NCTRL
relocate004:    .WORD   NCTRL-1

                .BYTE   "NST", TOK_AT, "US", 0  ; NSTATUS
relocate005:    .WORD   NSTATUS-1

                .ASCIIZ "NCLOSE"                ; NCLOSE
relocate006:    .WORD   NCLOSE-1

                .BYTE   "N", TOK_END, 0         ; NEND
relocate007:    .WORD   NEND-1   

                .BYTE   "N", TOK_LIST, 0        ; NLIST
relocate008:    .WORD   NLIST-1

.IF .NOT STRIP_TRACE
                .BYTE   "N", TOK_TRACE, 0       ; NTRACE
trace028:       .WORD   NTRACE-1

                .BYTE   "N",TOK_NOTRACE, 0      ; NNOTRACE
trace029:       .WORD   NNOTRACE-1
.ENDIF

;*******************************************
;* END OF TABLE
;*******************************************
                .BYTE   00      ; END OF TABLE

.IF .NOT STRIP_TRACE            
TRACE_FLAG:     .BYTE   $01
.ENDIF
RELOC_SIZE:     .BYTE   $0D

PREVECT:        .RES    3       ; JUMP TO CONTENTS OF THE PREVIOUS AMPERSAND VECTOR
OLDHIMEM:       .RES    2       ; VALUE OF ORIGINAL HIMEM



;***************************************
BASIC_UNIT:     .BYTE   0       ; BASIC UNIT 0-4 NOT FUJINET UNIT
MODE:           .BYTE   4       ; 4=READ ONLY, 6=READ DIRECTORY, 8= WRITE ONLY, 12=READ/WRITE, 13= HTTP POST
TRANSLATION:    .BYTE   0       ; 0 = NO TRANSLATION, 1=CR to ATASCII EOL, 2=LF to ATASCII EOL, 3=CR/LF to ATASCII EOL
URL_LEN:        .BYTE   45
URL:            
.IF .NOT STRIP_TRACE
                .ASCIIZ "N:HTTPS://www.gnu.org/licenses/gpl-3.0.txt"
.ENDIF
                .RES    255       
relocate009:
URL_ADDR:       .WORD   URL
COMMAND:        .BYTE   0       ; FUJINET COMMAND
BASIC_PAYLOAD:  .RES    255     ; PAYLOAD TO SEND
BW:             .WORD   0       ; BYTES WAITING
CONNECT:        .BYTE   0       ; 1=CONNECTED
BUFLEN:         .BYTE   0
BUF:            .RES    255     ; GENERIC BUFFER FOR READ/WRITE
STRADDR:        .WORD   0
STRLEN:         .BYTE   0
STRBUF:         .RES    255
relocate010:
STRBUF_ADDR:    .WORD   STRBUF
NETWORK_CACHE:  .BYTE   FN_NO_NETWORK, FN_NO_NETWORK, FN_NO_NETWORK, FN_NO_NETWORK
OPEN_LIST:      .BYTE   FN_NO_NETWORK, FN_NO_NETWORK, FN_NO_NETWORK, FN_NO_NETWORK      ; BASIC UNIT INDEX TO ACTUAL UNIT
NERR:           .BYTE   FN_ERR, FN_ERR, FN_ERR, FN_ERR                                  ; LAST ERROR

STR_DSC_LEN:    .BYTE   0
STR_DSC_LO:     .BYTE   0
STR_DSC_HI:     .BYTE   0

.include "STRINGS.S"

RELOCATE_DATA_END:

; Anything here is only used during setup and doesn't need to be relocated.


.include "RELOCATION.S" 

RELOCATION_TABLE:
		.WORD 	relocate000+1,relocate001+1,relocate002,relocate003,relocate004,relocate005,relocate006,relocate007,relocate008,relocate009
		.WORD 	relocate010,relocate011;,relocate012,relocate013,relocate014,relocate015,relocate016,relocate017,relocate018,relocate019
;		.WORD   relocate020,relocate021,relocate022,relocate023,relocate024,relocate025,relocate026,relocate027,relocate028,relocate029

.include "STR_RELOC.S"

.IF USE_SP
               .WORD    relocatesp00,relocatesp01,relocatesp02,relocatesp03,relocatesp04,relocatesp05,relocatesp06,relocatesp07;,relocatesp08,relocatesp09
.ELSE
;                .WORD   relocatefsp00
.ENDIF
END_RELOCATION_TABLE:	
                .WORD 	0 ; end of table

; We should generate an error if there are too many entries (greater than 255)

ENDOFFILE:      NOP

