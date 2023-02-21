;*****************************************************
; FUJIAPPLE
; Ampersand extension for Fujinet commands
; By Norman Davie
;
; VERSION: 1.05 - updated to use ca65
;
; With ca65 task
;{
;    "version": "2.0.0",
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

USE_TRACE  = 1
RELOCATE   = 0
PRODOS     = 1
APPLEII    = 1

.IF PRODOS
        .ORG $2000

; NO HEADER FOR PRODOS

.ELSE

; WE SUBRACT 4 TO ALLOW ROOM FOR THE ADDRESS AND LENGTH FIELDS AT THE START OF THE FILE

        .ORG $2000 - 4 

; HEADER FOR BINARY FILES ON DOS 3.3

        .WORD NINIT                             ; Starting address
        .WORD (ENDOFFILE - RELOCATE_CODE_START) ; Length

.ENDIF
; VARIOUS SYSTEM ROUTINES AND LOCATIONS 

        .include "APPLEEQU.S"
        .include "ZEROPAGE.S"


TOK_READ                =       135       ; APPLESOFT TOKEN FOR READ
TOK_AT                  =       197       ; APPLESOFT TOKEN FOR AT
TOK_END                 =       128       ; APPLESOFT TOKEN FOR END
QUOTE                   =       $22       ; ASCII QUOTE CHARACTER
                          

;*********************************************************                           

STARTOFFILE:

NINIT:

                LDA #<FUJIAPPLE_VER_STR                 ; "VERSON: YYYYMMDD.HHMM"
                LDY #>FUJIAPPLE_VER_STR
                JSR STROUT
                JSR CROUT

.IF USE_TRACE
                LDA #<DISPATCH_ADDRESS_STR              ; "SMARTPORT ADDRESS:"
                LDY #>DISPATCH_ADDRESS_STR
                JSR STROUT
.ENDIF
                JSR GET_SMARTPORT_DISPATCH_ADDRESS      ; FIND THE ADDRESS
                STA SMARTPORT_DISPATCHER+1              ; REMEMBER THE ADDRESS
                STX SMARTPORT_DISPATCHER

.IF USE_TRACE
                JSR PRTAX                               ; PRINT THE ADDRESS
                JSR CROUT
.ENDIF

                LDA SMARTPORT_DISPATCHER+1
                CMP #$FF                                ; WAS THE CARD FOUND?
                BNE FOUND_SMARTPORT

                LDA #<SP_NOT_FOUND                      ; "SMARTPORT NOT FOUND!"
                LDY #>SP_NOT_FOUND
                JSR STROUT
                RTS

FOUND_SMARTPORT:

.IF USE_TRACE
                JSR DISPLAY_SP_STATUS                   ; SHOW THE ID AND VERSION
                JSR DISPLAY_SP_DEVICES                  ; SHOW ALL THE DEVICES

                LDA #<FUJI_DISK_0_STR
                LDY #>FUJI_DISK_0_STR
                JSR SP_FIND_DEVICE
                JSR PRTX
                JSR CROUT


                LDA #<NETWORK_STR
                LDY #>NETWORK_STR
                JSR SP_FIND_DEVICE
                JSR PRTX
                JSR CROUT
.ENDIF

; RELOCATE US TO WHERE IT'S SAFE

.IF USE_TRACE
                JSR CROUT               ; CARRIAGE RETURN
                LDA #<HIMEM_IS          ; "HIMEM IS:"
                LDY #>HIMEM_IS
                JSR STROUT

                LDA HIMEM+1
                STA OLDHIMEM+1          ; KEEP TRACK OF HIMEM
		LDX HIMEM
                STX OLDHIMEM
		JSR PRTAX               ; PRINT ADDRESS
.ENDIF

.IF RELOCATE
		JSR ADJUST_HIMEM        ; Move HIMEM so we can put our code at it. 

		LDA #<RELOCATING        ; "RELOCATING TO:"
		LDY #>RELOCATING
		JSR STROUT
		LDA HIMEM+1
		LDX HIMEM
		JSR PRTAX               ; PRINT NEW HIMEM ADDRESS
                JSR CROUT

                JSR RELOCATE_TO_HIMEM   ; copy the code and data, adjust all absolute addresses
.ENDIF

.IF RELOCATE
                LDA #<RELOC_SIZE        ; "CODE SIZE:"
                LDY #>RELOC_SIZE
                JSR STROUT
                LDX #<(RELOCATE_DATA_END - RELOCATE_CODE_START)
                LDA #>(RELOCATE_DATA_END - RELOCATE_CODE_START)
                JSR PRTAX               ; PRINT SIZE
                JSR CROUT
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

                LDA #<EXTADDED          ; "FUJINET EXTENSION ADDED"
                LDY #>EXTADDED          
                JSR STROUT
                JMP DOSWARM             ; WARM START DOS-NEEDED FOR BRUN
                RTS

RELOCATE_CODE_START:

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

.IF USE_TRACE

                LDA #<NOTFOUND  ; "COMMAND NOT FOUND"
                LDY #>NOTFOUND
                JSR STROUT
                JSR CROUT

.ENDIF

                JMP   PREVECT    ; WE DIDN'T FIND OUR COMAND SO GO TO OLD VECTOR

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
                CLC             ; RELOCATIBLE JUMP
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
;*************************************
;*************************************
NOPEN:

; &NOPEN UNIT,MODE,TRANS,URL$
; &NOPEN UNIT,MODE,TRANS,"URL"
; Opens a specified URL for use.

.IF USE_TRACE
                LDA #<NOPEN_STR ; "NOPEN"
                LDY #>NOPEN_STR
                JSR STROUT
                JSR CROUT
.ENDIF

                JSR GETBYT     ; GET THE UNIT
                STX UNIT

                JSR CHKCOM
                JSR GETBYT     ; GET MODE
                STX MODE

                JSR CHKCOM
                JSR GETBYT     ; GET TRANS
                STX TRANS

                JSR CHKCOM
                JSR CHRGOT     ; WHAT ARE WE POINTING AT IN BASIC
                CMP #QUOTE     ; IS IT A STATIC STRING?
                BNE VARSTR

                JSR GETSTR     ; GETS THE STATIC STRING, STORED IN STRBUF

; WE'RE GOING TO CREATE A NEW DESCRIPTION
; THE SAME WAY APPLESOFT DOES

                LDA STRLEN     ; GETSTR STORES THE STRING LENGTH HERE
                STA DSCTMP
                LDA #<STRBUF   ; THE ADDRESS OF OUR STATIC STRING
                STA DSCTMP+1
                LDA #>STRBUF
                STA DSCTMP+2
                CLC
                BCC STORE

VARSTR:
                JSR GETSTRVAR  ; IT'S A STRING VARIABLE
STORE:
                LDY DSCTMP     ; GET THE STRING LENGTH
STORING:
                LDA (DSCTMP+1),Y
                STA URL,Y
                DEY
                BPL STORING

; MAKE THE STRING C COMPATIBLE

                LDY DSCTMP
                LDA #0         ; NULL TERMINATE STRING
                STA URL,Y

;****** TO DO ******
; UNIT, MODE, TRANS AND URL HAVE BEEN FILLED
; CALL APPROPRIATE FUJINET ROUTINE
; TO OPEN
;******************

                RTS
;*********************************************
NCLOSE:
; &NCLOSE UNIT
; Closes a network connection.

.IF USE_TRACE
                LDA #<NCLOSE_STR
                LDY #>NCLOSE_STR
                JSR  STROUT
                JSR CROUT
.ENDIF

                JSR   GETBYT     ; GET THE UNIT
                STX   UNIT

;****** TO DO *****
; CALL FUJINET ROUTINE TO CLOSE
;*****************

                RTS

;*********************************************
NREAD:

; &NREAD UNIT, VAR$, LEN
; Gets len number of bytes and puts them into string variable var$

.IF USE_TRACE
                LDA #<NREAD_STR ; "NREAD"
                LDY #>NREAD_STR
                JSR  STROUT
                JSR CROUT
.ENDIF

                JSR   GETBYT    ; GET THE UNIT
                STX   UNIT
                JSR   CHKCOM
                JSR   PTRGET    ; GET THE STRING

                JSR   CHKCOM
                JSR   GETBYT    ; GET THE LENGTH
                STX   BUFLEN
                TXA

                JSR   STRINI    ; CREATE STRING OF LENGTH A
                LDY   #0
                LDA   DSCTMP    ; COPY NEW DESCRIPTON
                STA   (VARPTR),Y
                INY
                LDA   DSCTMP+1
                STA   (VARPTR),Y
                INY
                LDA   DSCTMP+2
                STA   (VARPTR),Y

;****** TO DO ******
; CALL FUJINET READ FOR 'BUFLEN' BYTES
; AND STORE THOSE BYTES IN BUF
;*******************

                LDA   BUFLEN
                LDY   #.HIBYTE(BUF)
                LDX   #.LOBYTE(BUF)
                JSR   MOVSTR    ; COPY BUFFER TO STRING (VAR$)
                RTS
;*****************************************************
NWRITE:
; &NWRITE UNIT,VAR$,LEN
; &NWRITE UNIT,"STRING",LEN
; Gets len number of bytes and puts them into string variable var$

.IF USE_TRACE
                LDA #<NWRITE_STR        
                LDY #>NWRITE_STR
                JSR STROUT
                JSR CROUT
.ENDIF

                JSR   GETBYT     ; GET UNIT
                STX   UNIT

                JSR   CHKCOM
                JSR   CHRGOT     ; WHAT ARE WE POINTING AT IN BASIC?
                CMP   #QUOTE     ; IS IT A STATIC STRING?
                BNE   GETVAR

                JSR   GETSTR     ; GET THE STATIC STRING
                CLC
                BCC   STORE2

GETVAR:
                JSR   GETSTRVAR ; GET VAR$

STORE2:
                JSR   CHKCOM
                JSR   GETBYT     ; GET LENGTH
                STX   BUFLEN

                LDY   BUFLEN
COPYBUF:
                LDA   (DSCTMP+1),Y
                STA   BUF,Y
                DEY
                BPL   COPYBUF

;****** TO DO *********
; BUF NOW CONTAINS DATA
; TO BE SENT
; CALL FUJINET
;**********************

                RTS
NCTRL:
; &NCTRL UNIT,COMMAND, PAYLOAD$
; Sends a specific control message to the network device 
; to do a special command. The payload for this command 
; is specified as the very last parameter.

.IF USE_TRACE
                LDA #<NCTRL_STR
                LDY #>NCTRL_STR
                JSR STROUT
                JSR CROUT
.ENDIF

                JSR   GETBYT     ; GET UNIT
                STX   UNIT

                JSR   CHKCOM
                JSR   GETBYT     ; GET COMMAND
                STX   COMMAND

                JSR   CHKCOM
                JSR   CHRGOT     ; WHAT ARE WE POINTING AT IN BASIC?
                CMP   #QUOTE     ; IS IT A STATIC STRING?
                BNE   GETVAR3

                JSR   GETSTR     ; GET THE STATIC STRING
                CLC
                BCC   STORE3

GETVAR3:
                JSR   GETSTRVAR

STORE3:

; MOVE STRING TO BUF
                LDY   DSCTMP
CPY2BUF:
                LDA   (DSCTMP+1),Y
                STA   PAYLOAD,Y
                DEY
                BPL   CPY2BUF
;*
;****** TO DO *******
; UNIT, COMMAND ARE STORED
; AND PAYLOAD$ IS IN PAYLOAD
; CALL FUJINET
;*******************
                RTS
;*******************************************

NSTATUS:
; &NSTATUS UNIT,BW,CONNECTED,NERR
; To get the status of network unit. BW = bytes waiting, 
; CONNECTED equals 1 if connect and NERR returns 
; the network error code

.IF USE_TRACE
                LDA #<NSTATUS_STR
                LDY #>NSTATUS_STR
                JSR  STROUT
                JSR CROUT
.ENDIF

                JSR   GETBYT
                STA   UNIT       ; STORE THE UNIT NUMBER

                JSR   CHKCOM

;******* TO DO *******
;* GET BYTES WAITING AND STORE IN BW
;* GET CONNECTED STATE AND STORE IN CONNECT
;* GET ERROR VALUE AND STORE IN NERR
;*********************

                LDA   BW+1       ; NUMBER OF BYTES WAITING
                LDY   BW
                JSR   WORDSAV    ; CONVERT TO FLOAT AND STORE IN BW VAR

                JSR   CHKCOM
                LDY   CONNECT
                JSR   BYTESAV    ; CONVERT TO FLOAT AND STORE IN CONNECT VAR

                JSR   CHKCOM
                LDY   NERR
                JSR   BYTESAV    ; CONVERT TO FLOAT AND STORE IN NERR VAR
                RTS

;*******************************************
NEND:
; &NEND
; Remove the fujiapple vector and
; put the original vector back

.IF USE_TRACE
                LDA #<NEND_STR
                LDY #>NEND_STR
                JSR  STROUT
                JSR CROUT
.ENDIF

.IF RELOCATE

                LDA HIMEM
                CMP RELOC_FUJIAPPLE
                BNE NO_RESTORE
                LDA HIMEM+1
                CMP RELOC_FUJIAPPLE+1
                BNE NO_RESTORE

                LDA #<RESTORE_HIMEM
                LDY #>RESTORE_HIMEM
                JSR STROUT

                LDA OLDHIMEM
                STA HIMEM
                LDA OLDHIMEM+1
                STA HIMEM+1

                CLC
                BCC RESTORE_VECT

NO_RESTORE:
                LDA #<CANT_RESTORE
                LDY #>CANT_RESTORE
                JSR STROUT

.ENDIF

RESTORE_VECT:

                LDA PREVECT
                STA AMPVECT
                LDA PREVECT+1
                STA AMPVECT+1
                LDA PREVECT+2
                STA AMPVECT+2

                LDA   #<EXTREMOVED
                LDY   #>EXTREMOVED      ; LET THE USER KNOW
                JSR   STROUT
                RTS

        .include "SMARTPORTCMDS.S"

RELOCATE_CODE_END:

;***********
;***********
;***********
;* DATA SECTION
;***********
;***********
;***********

;*********************
FUJIAPPLE_VER_STR:
                .ASCIIZ "FUJIAPPLE VERSION: 20220222.2215"

ADJUST_HIMEM_STR:
                .BYTE $0D, "ADJUSTING HIMEM TO: ", $00

RELOCATING:
                .BYTE $0D, "RELOCATING TO HIMEM...", $00

RESTORE_HIMEM:
                .BYTE $0D, "RESTORING HIMEM...", $00

CANT_RESTORE:
                .BYTE $0D,"SOMETHING ELSE CHANGED HIMEM; CAN'T RESTORE ORIGINAL HIMEM.", $00

EXTADDED:
                .BYTE   $0D, "FUJINET EXTENSIONS ADDED.", $0D, $00

EXTREMOVED:
                .BYTE   $0D, "FUJINET EXTENSIONS REMOVED.", $0D, $00

NOTFOUND:
                .BYTE   $0D, "FUJINET COMMAND NOT FOUND -- FORWARDING TO NEXT AMPERSAND ROUTINE", $0D, $00

;**************************************

relocate000:
RELOC_FUJIAPPLE: .WORD NSTART

COMMANDS:
NOPEN_STR:      .ASCIIZ "NOPEN"                 ; NOPEN
relocate001:    .WORD   NOPEN-1

                .BYTE   'N', TOK_READ, 00       ; NREAD

relocate002:    .WORD   NREAD-1

NWRITE_STR:     .ASCIIZ "NWRITE"                ; NWRITE
relocate003:    .WORD   NWRITE-1

NCTRL_STR:      .ASCIIZ "NCTRL"                 ; NCTRL
relocate004:    .WORD   NCTRL-1

                .BYTE   "NST", TOK_AT           ; NSTATUS
                .ASCIIZ "US"
relocate005:    .WORD   NSTATUS-1

NCLOSE_STR:     .ASCIIZ "NCLOSE"                ; NCLOSE
relocate006:    .WORD   NCLOSE-1

                .BYTE   "N", TOK_END, 00        ; NEND
relocate007:    .WORD   NEND-1   
        
;*******************************************
;* END OF TABLE
;*******************************************
                .BYTE   00              ; END OF TABLE

.IF USE_TRACE
NREAD_STR:      .ASCIIZ "NREAD"
NSTATUS_STR:    .ASCIIZ "NSTATUS"
NEND_STR:       .ASCIIZ "NEND"
HIMEM_IS:       .ASCIIZ "CURRENT ADDRESS OF HIMEM: "
RELOC_SIZE:     .BYTE   $0D
                .ASCIIZ "RELOCATION SIZE: "
DISPATCH_ADDRESS_STR: 
                .ASCIIZ "DISPATCHER ADDRESS: "
.ENDIF
SP_NOT_FOUND:   .ASCIIZ "SMARTPORT NOT FOUND!"

PREVECT:        .RES 3                  ; JUMP TO CONTENTS OF THE PREVIOUS AMPERSAND VECTOR
OLDHIMEM:       .RES 2                  ; VALUE OF ORIGINAL HIMEM



;***************************************
UNIT:           .BYTE         0
MODE:           .BYTE         0
TRANS:          .BYTE         0
URL:            .RES          255
COMMAND:        .BYTE         0
PAYLOAD:        .RES          255
BW:             .WORD         0        ; BYTES WAITING
CONNECT:        .BYTE         0
NERR:           .BYTE         0
BUF:            .RES          255      ; GENERIC BUFFER FOR READ/WRITE
BUFLEN:         .BYTE         0
STRADDR:        .WORD         0
STRBUF:         .RES          255
STRLEN:         .BYTE         0



RELOCATE_DATA_END:

; Anything here is only used during setup and doesn't need to be relocated.





.include "RELOCATION.S" 

RELOCATION_TABLE:
		.WORD 	relocate000+1,relocate001+1,relocate002,relocate003,relocate004,relocate005,relocate006,relocate007 ;,relocate008,relocate009

;		.WORD 	relocate010+1,relocate011+1,relocate012+1,relocate013+1,relocate014+1,relocate015+1,relocate016+1,relocate017+1,relocate018+1,relocate019+1
;		.WORD   relocate020+1,relocate021+1,relocate022+1

END_RELOCATION_TABLE:	.WORD 	0 ; end of table
			.RES	1024

; We should generate an error if there are too many entries (greater than 255)

ENDOFFILE:      NOP

