
		.WORD 	str000,str001,str002,str003,str004,str005,str006,str007,str008,str009
		.WORD 	str010,str011,str012,str013,str014,str015,str016,str017;,str018,str019
;		.WORD   str020,str021,str022,str023,str024,str025,str026,str027,str028,str029
;        .WORD   str030,str031,str032,str033,str034,str035,str036,str037,str038,str039
;        .WORD   str040,str041,str042,str043,str044,str045,str046,str047,str048,str049


.IF .NOT STRIP_TRACE

		.WORD 	trace000,trace001,trace002,trace003,trace004,trace005,trace006,trace007,trace008,trace009
		.WORD 	trace010,trace011,trace012,trace013,trace014,trace015,trace016,trace017,trace018,trace019
		.WORD   trace020,trace021,trace022,trace023,trace024,trace025,trace026,trace027,trace028,trace029
		.WORD   trace042,trace043,trace044,trace045, trace047

.IF .NOT USE_SP
        .WORD   trace030, trace031,trace032,trace033,trace034,trace035,trace036,trace037,trace038;,trace039
		.WORD	trace046
.ENDIF
;        .WORD   trace040,trace041,trace042,trace043;,trace044,trace045,trace046,trace047,trace048,trace049
.ENDIF