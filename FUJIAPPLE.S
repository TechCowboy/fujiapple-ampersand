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
;*****************************************************
        .ORG $2000 

; HEADER FOR BINARY FILES

        .WORD NINIT
        .WORD (ENDOFFILE - STARTOFFILE)

AMPVECT     =   $03F5     ; AMPERSAND VECTOR FOR APPLESOFT
GETBYT      =   $E6F8     ; EVAL BYTE -> X
CHKCOM      =   $DEBE     ; CHECK FOR COMMA
FRMNUM      =   $DD67     ; EVALUATE NUMERIC EXPRESSION
GETADR      =   $DD67     ; CONVERT FAC TO INT (MAX 65535)
PTRGET      =   $DFE3     ; FIND NAMED VARIABLE (ADDRESS IN VARPTR)
STRINI      =   $E3D5     ; CREATE NEW STRING SPACE
MOVSTR      =   $E5E2     ; MOVE STRING INTO NEW SPACE
MOVFM       =   $EAF9     ; UNPACK (Y,A) TO FAC
MOVMF       =   $EB2B     ; PACK FAC TO (Y,A)
GIVAYF      =   $E2F2     ; CONVERT SIGNED WORD (A,Y) TO FLOAT
SNGFLT      =   $E301     ; CONVERT UNSIGNED BYTE Y TO FLOAT
FLOAT       =   $EB90     ; CONVERT SIGNED BYTE A TO FLOAT
COUT        =   $FDED     ; DISPLAY A AS CHAR ON SCREEN
STROUT      =   $DB3A     ; PRINTS STRING POINT BY Y (HI) AND A(LO)
CONINT      =   $E6FB     ; CONVERT FAC TO INT (MAX 255)
SYNERR      =   $DEC9     ; ?SYNTAX ERROR
PRTYX       =   $F940     ; PRINT Y AND X AS HEX
PRTAX       =   $F941     ; PRINT A AND X AS HEX
PRTX        =   $F944     ; PRINT X AS HEX
DOSWARM     =   $03D0     ; CALL TO EXIT BRUN'D PROGRAM
TXTPTR      =   $B8       ; WHERE WE ARE IN THE BASIC FILE
VARPTR      =   $83       ; POINTER TO OUR VARIABLE
DSCTMP      =   $9D       ; TEMPORARY DESCRIPTION STORAGE
CHRGET      =   $B1       ; ADVANCE TXTPTR, GET CHAR INTO A
CHRGOT      =   $B7       ; CHARACTER ALREADY PROCESSED BY BASIC
TOK_READ    =   135       ; APPLESOFT TOKEN FOR READ
TOK_AT      =   197       ; APPLESOFT TOKEN FOR AT
TOK_END     =   128       ; APPLESOFT TOKEN FOR END
HIMEM       =   $73       ; APPLESOFT HIMEM
QUOTE       =   $22       ; ASCII QUOTE CHARACTER
                          
;*********************************************************                           

STARTOFFILE:
RELOCATE_CODE_START:

NINIT:

        LDA   AMPVECT+1
        CMP   RELOC_FUJIAPPLE
        BNE   SAVEVECT
        LDA   AMPVECT+2
        CMP   RELOC_FUJIAPPLE+1
        BNE   SAVEVECT
;
; WE'RE ALREADY SET
; DON'T DO ANYTHING
;
                RTS

; SAVE PREVIOUS VECTOR INFO

SAVEVECT:
        LDA   AMPVECT
        STA   PREVECT
        LDA   AMPVECT+1
        STA   PREVECT+1
        LDA   AMPVECT+2
        STA   PREVECT+2
;
; UPDATE THE AMPERSAND VECTOR TO OUR ROUTINE
;
        LDA   RELOC_FUJIAPPLE  ; SET THE AMPERSAND VECTOR
        STA   AMPVECT+1
        LDA   RELOC_FUJIAPPLE+1
        STA   AMPVECT+2
;
; ANNOUNCE OUR SUCCESS
;
        LDA   #.LOBYTE(EXTADDED)
        LDY   #.HIBYTE(EXTADDED) ; LET THE USER KNOW
        JSR   STROUT
        JMP   DOSWARM    ; WARM START DOS-NEEDED FOR BRUN
        RTS

;****************************************
; NSTART - FUJINET EXTENSION START
;   THIS IS THE ENTRY POINT OF THE AMPERSAND ROUTINE
;   CHECK FOR OUR COMMANDS AND EXECUTE IF FOUND
;   IF IT DOESN'T MATCH OUR COMMANDS, THEN
;   GO TO THE PREVIOUS AMPERSAND ROUTINE
;****************************************
NSTART:
        LDX   #$00
NEXTCMD:
        LDY   #$00       ; INDEX INTO TXTPTR
        LDA   COMMANDS,X ; COMMAND TEXT IN TABLE
        BEQ   NOMORECMDS ; WE'VE EXAUSTED OUR CMD LIST
COMP:
        LDA   COMMANDS,X
        CMP   (TXTPTR),Y ; DOES COMMAND TEXT MATCH?
        BNE   SKIPCMD    ; IT'S NOT A MATCH
        INY              ; MOVE TO NEXT CHARACTER
        INX
        LDA   COMMANDS,X ; IS THE CHARACTER A NULL?
        BNE   COMP       ; NOPE, COMPARE NEXT CHARACTER
        BEQ   FOUNDCMD   ; YES, WE'VE FOUND OUR COMMAND
SKIPCMD:
        INX              ; MOVE TO THE NEXT CHARACTER
        LDA   COMMANDS,X ; KEEP READING UNTIL NULL
        BNE   SKIPCMD
        INX              ; IGNORE THE NULL
        INX              ; IGNORE THE ADDRESS
        INX

        CLC
        BCC   NEXTCMD    ; CHECK NEXT CMD
FOUNDCMD:
        TXA
        PHA
RMCMD:
        JSR   CHRGET     ; REMOVE CHAR FROM BASIC
        DEY
        BNE   RMCMD

        PLA
        TAX

; PUSHADDR ON STACK AND "RETURN" TO OUR ROUTINE

        INX
        LDA   COMMANDS+1,X
        PHA
        LDA   COMMANDS,X
        PHA              ; ADDRESS OF OUR ROUTINE IS ON STACK
        RTS              ; RETURN TO ADDRESS ON STACK

; IF WE'RE HERE, IT'S NOT ONE OF OUR COMMAN.RES
; JUMP TO THE PREVIOUS VECTOR AND LET IT PROCESS IT

NOMORECMDS:
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

GETSTR:                    ; GET STATIC STRING
        LDY   #01
CONSUME:
        LDA   (TXTPTR),Y ; GET CHARACTER FROM BASIC
        CMP   #QUOTE     ; WE NEED TO STOP ON THE ENDING QUOTE
        BEQ   NULLSTR1   ; WE'RE DONE
        STA   STRBUF-1,Y ; SAVE THE CHARACTER
        INY
        CLC              ; RELOCATIBLE JUMP
        BCC   CONSUME    ; GET THE NEXT CHARACTER
NULLSTR1:
        LDA   #00
        STA   STRBUF-1,Y ; TERMINATE THE STRING WITH A NULL
        DEY
        STY   STRLEN     ; SAVE THE LENGTH OF THE STRING
        JSR   CHRGET
GOBBLE:
        JSR   CHRGET     ; GET THE CHARACTER FROM BASIC
        CMP   #QUOTE     ; HAVE WE FOUND THE ENDING QUOTE?
        BEQ   COMPLETED  ; WE'RE DONE
        INY
        CLC
        BCC   GOBBLE

COMPLETED:
        JSR   CHRGET     ;
        RTS

;*******************************************
; GETSTRVAR - GET STRING VARIABLE
; RETURNS:
;   STRING LENGTH IN DSCTMP
;   STRING ADDR LO IN DSCTMP+1
;   STRING ADDR HI IN DSCTMP+2
;*********************************
GETSTRVAR:
        JSR   PTRGET     ; GET URL (STRING)
        LDY   #0
        LDA   (VARPTR),Y ; STRING LENGTH
        STA   DSCTMP
        INY
        LDA   (VARPTR),Y ; ADDR LO
        STA   DSCTMP+1
        INY
        LDA   (VARPTR),Y ; ADDR HI
        STA   DSCTMP+2
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
        LDA   #0
WORDSAV:
        JSR   GIVAYF     ; CONVERT TO FLOATING POINT
        JSR   PTRGET     ; FIND ADDRESS OF THE VARIABLE
        TAX
        JSR   MOVMF      ; STORE VALUE INTO VARIABLE
        RTS
;*************************************
;*************************************
;*************************************
NOPEN:

; &NOPEN UNIT,MODE,TRANS,URL$
; &NOPEN UNIT,MODE,TRANS,"URL"
; Opens a specified URL for use.

        JSR   GETBYT     ; GET THE UNIT
        STX   UNIT

        JSR   CHKCOM
        JSR   GETBYT     ; GET MODE
        STX   MODE

        JSR   CHKCOM
        JSR   GETBYT     ; GET TRANS
        STX   TRANS

        JSR   CHKCOM
        JSR   CHRGOT     ; WHAT ARE WE POINTING AT IN BASIC
        CMP   #QUOTE     ; IS IT A STATIC STRING?
        BNE   VARSTR

        JSR   GETSTR     ; GETS THE STATIC STRING, STORED IN STRBUF

; WE'RE GOING TO CREATE A NEW DESCRIPTION
; THE SAME WAY APPLESOFT DOES

        LDA   STRLEN     ; GETSTR STORES THE STRING LENGTH HERE
        STA   DSCTMP
        LDA   #.LOBYTE(STRBUF)   ; THE ADDRESS OF OUR STATIC STRING
        STA   DSCTMP+1
        LDA   #.HIBYTE(STRBUF)
        STA   DSCTMP+2
        CLC
        BCC   STORE

VARSTR:
        JSR   GETSTRVAR  ; IT'S A STRING VARIABLE
STORE:
        LDY   DSCTMP     ; GET THE STRING LENGTH
STORING:
        LDA   (DSCTMP+1),Y
        STA   URL,Y
        DEY
        BPL   STORING

; MAKE THE STRING C COMPATIBLE

        LDY   DSCTMP
        LDA   #0         ; NULL TERMINATE STRING
        STA   URL,Y

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

        JSR   GETBYT     ; GET THE UNIT
        STX   UNIT
        JSR   CHKCOM
        JSR   PTRGET     ; GET THE STRING

        JSR   CHKCOM
        JSR   GETBYT     ; GET THE LENGTH
        STX   BUFLEN
        TXA

        JSR   STRINI     ; CREATE STRING OF LENGTH A
        LDY   #0
        LDA   DSCTMP     ; COPY NEW DESCRIPTON
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
        JSR   MOVSTR     ; COPY BUFFER TO STRING (VAR$)
        RTS
;*****************************************************
NWRITE:
; &NWRITE UNIT,VAR$,LEN
; &NWRITE UNIT,"STRING",LEN
; Gets len number of bytes and puts them into string variable var$

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

        JSR   GETBYT     ; GET UNIT
        STX   UNIT

        JSR   CHKCOM
        JSR   GETBYT     ; GET COMMAND
        STX   COMMAND

; ONLY ALLOW A VARIABLE, NOT A STATIC STRING

        JSR   GETSTRVAR

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

        LDA PREVECT
        STA AMPVECT
        LDA PREVECT+1
        STA AMPVECT+1
        LDA PREVECT+2
        STA AMPVECT+2

        LDA   #.LOBYTE(EXTREMOVED)
        LDY   #.HIBYTE(EXTREMOVED) ; LET THE USER KNOW
        JSR   STROUT
        RTS
RELOCATE_CODE_END:

;***********
;***********
;***********
;* DATA SECTION
;***********
;***********
;***********

;*********************

EXTADDED:
    .BYTE   $0D
    .ASCIIZ   "FUJINET EXTENSIONS ADDED."

EXTREMOVED:
    .BYTE   $0D
    .ASCIIZ   "FUJINET EXTENSIONS REMOVED."

;**************************************

relocate000:
RELOC_FUJIAPPLE: .WORD NSTART

COMMANDS:
                .ASCIIZ "NOPEN"         ; NOPEN
relocate001:    .WORD   NOPEN-1

                .BYTE   'N'             ; NREAD
                .BYTE   TOK_READ
                .BYTE   00
relocate002:    .WORD   NREAD-1

                .ASCIIZ "NWRITE"        ; NWRITE
relocate003:    .WORD   NWRITE-1

                .ASCIIZ "NCTRL"         ; NCTRL
relocate004:    .WORD   NCTRL-1

                .BYTE   'N','S','T'     ; NSTATUS
                .BYTE   TOK_AT
                .ASCIIZ "US"
relocate005:    .WORD   NSTATUS-1

                .ASCIIZ "NCLOSE"        ; NCLOSE
relocate006:    .WORD   NCLOSE-1

                .BYTE   "N"             ; NEND
                .BYTE   TOK_END
                .BYTE   00
relocate007:    .WORD   NEND-1   
        
;*******************************************
;* END OF TABLE
;*******************************************
                .BYTE   00              ; END OF TABLE

PREVECT:        .RES 3                  ; JUMP TO CONTENTS OF THE PREVIOUS AMPERSAND VECTOR

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

ENDOFFILE:

RELOCATE_DATA_END:

; Anything here is only used during setup and doesn't need to be relocated.

.include "RELOCATION.S" 

RELOCATION_TABLE:
		.WORD 	relocate000,relocate001,relocate002,relocate003,relocate004,relocate005,relocate006,relocate007;,relocate008+1,relocate009+1
;		.WORD 	relocate010+1,relocate011+1,relocate012+1,relocate013+1,relocate014+1,relocate015+1,relocate016+1,relocate017+1,relocate018+1,relocate019+1
;		.WORD   relocate020+1,relocate021+1,relocate022+1

END_RELOCATION_TABLE:	.WORD 	0 ; end of table
			.RES	1024

; This should generate an error if there are too many entries (greater than 255)


