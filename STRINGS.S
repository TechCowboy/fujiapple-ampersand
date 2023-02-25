; THESE STRINGS ARE USED DURING INITIALIZATION AND
; WON'T BE USED AFTERWARDS SO DON'T NEED TO BE RELOCATED
EXTADDED_STR:                               .BYTE   $0D, "FUJINET EXTENSIONS ADDED.", $0D, $00
SP_NOT_FOUND_STR:                           .BYTE   "NO SMARTPORT! EXTENSIONS NOT LOADED", $0D, $00

.IF .NOT STRIP_TRACE

HIMEM_IS_STR:                               .ASCIIZ "CURRENT ADDRESS OF HIMEM: "
RELOC_SIZE_STR:                             .ASCIIZ "RELOCATION SIZE: "
EXITING_STR:                                .BYTE   "EXITING...", $0D, $00
FUJIAPPLE_VER_STR:                          .BYTE   "FUJIAPPLE VERSION: YYYYMMDD.HHMM", $00, $0D
ADJUST_HIMEM_STR:                           .BYTE   $0D, "ADJUSTING HIMEM TO: ", $00 
RELOCATING:                                 .BYTE   $0D, "RELOCATING TO HIMEM...", $00

.ENDIF

; THESE STRING ARE USED AFTER RELOCATING

NOPEN_STR:                                  .BYTE "NOPEN", $0D, $00
str000:
NOPEN_STR_ADDR:                             .WORD NOPEN_STR

NREAD_STR:                                  .BYTE "NREAD", $0D, $00
str030:
NREAD_STR_ADDR:                             .WORD NREAD_STR_ADDR

NCLOSE_STR:                                 .BYTE "NCLOSE", $0D, $00
str031:
NCLOSE_STR_ADDR:                            .WORD NCLOSE_STR, $0D, $00

NSTATUS_STR:                                .BYTE "NSTATUS", $0D, $00
str001:
NSTATUS_STR_ADDR:                           .WORD NSTATUS_STR

NEND_STR:                                   .BYTE "NEND", $0D, $00
str002:
NEND_STR_ADDR:                              .WORD NEND_STR

NLIST_STR:                                  .BYTE "NLIST", $0D, $00
str003:
NLIST_STR_ADDR:                             .WORD NLIST_STR

NTRACE_STR:                                 .BYTE   "NTRACE", $0D, $00 
str004:
NTRACE_STR_ADDR:                            .WORD NTRACE_STR

NWRITE_STR:
str032:
NWRITE_STR_ADDR:                            .WORD NWRITE_STR

NCTRL_STR:
str043:
NCTRL_STR_ADDR:                             .WORD NCTRL_STR

FIND_SMARTPORT_SLOT_STR:                    .BYTE "FIND_SMARTPORT_SLOT", $0D, $00
str005:
FIND_SMARTPORT_SLOT_STR_ADDR:               .WORD FIND_SMARTPORT_SLOT_STR

GET_SMARTPORT_DISPATCH_ADDRESS_STR:         .BYTE "GET_SMARTPORT_DISPATCH_ADDRESS", $0D, $00
str006:
GET_SMARTPORT_DISPATCH_ADDRESS_STR_ADDR:    .WORD GET_SMARTPORT_DISPATCH_ADDRESS_STR

DISPATCHER_ADDRESS_STR:                     .ASCIIZ "DISPATCHER ADDRESS:" 
str007:
DISPATCH_ADDRESS_STR_ADDR:                  .WORD DISPATCHER_ADDRESS_STR

SP_OPEN_STR:                                .BYTE "SP_OPEN",    $0D, $00
str008:
SP_OPEN_STR_ADDR:                           .WORD SP_OPEN_STR

SP_CLOSE_STR:                               .BYTE "SP_CLOSE",   $0D, $00
str009:
SP_CLOSE_STR_ADDR:                          .WORD SP_CLOSE_STR

SP_CONTROL_STR:                             .BYTE "SP_CONTROL", $00
str010:
SP_CONTROL_STR_ADDR:                        .WORD SP_CONTROL_STR

SP_STATUS_STR:                              .BYTE "SP_STATUS",  $0D, $00
str011:
SP_STATUS_STR_ADDR:                         .WORD SP_STATUS_STR

CALL_DISPATCHER_STR:                        .BYTE "CALL_DISPATCHER",   $0D, $00
str012:
CALL_DISPATCHER_STR_ADDR:                   .WORD CALL_DISPATCHER_STR

DISPLAY_SP_STATUS_STR:                      .BYTE "DISPLAY_SP_STATUS", $0D, $00
str013:
DISPLAY_SP_STATUS_STR_ADDR:                 .WORD DISPLAY_SP_STATUS_STR

SP_FIND_DEVICE_STR:                         .BYTE "SP_FIND_DEVICE",    $0D, $00
str014:
SP_FIND_DEVICE_STR_ADDR:                    .WORD SP_FIND_DEVICE_STR

REAL_SMARTPORT_STR:                         .BYTE "REAL SMARTPORT", $0D, $00
str015:
REAL_SMARTPORT_STR_ADDR:                    .WORD REAL_SMARTPORT_STR

FAKE_SMARTPORT_STR:                         .BYTE "**** FAKE SMARTPORT ****", $0D, $00
str016:
FAKE_SMARTPORT_STR_ADDR:                    .WORD FAKE_SMARTPORT_STR

FIND_NETWORK_STR:                           .BYTE "FIND_NETWORK"    , $0D, $00
str017:
FIND_NETWORK_STR_ADDR:                      .WORD FIND_NETWORK_STR

FN_BYTES_WAITING_STR:                       .BYTE "FN_BYTES_WAITING", $0D, $00
str018:
FN_BYTES_WAITING_STR_ADDR:                  .WORD FN_BYTES_WAITING_STR

FN_IS_CONNECTED_STR:                        .BYTE "FN_IS_CONNECTED" , $0D, $00
str019:
FN_IS_CONNECTED_STR_ADDR:                   .WORD FN_IS_CONNECTED_STR

FN_OPEN_STR:                                .BYTE "FN_OPEN"         , $0D, $00
str020:
FN_OPEN_STR_ADDR:                           .WORD FN_OPEN_STR

FN_CLOSE_STR:                               .BYTE "FN_CLOSE"        , $0D, $00
str021:
FN_CLOSE_STR_ADDR:                          .WORD FN_CLOSE_STR

CPY_URL_TO_PAYLOAD_STR:                     .BYTE "CPY_URL_TO_PAYLOAD", $0D, $00
str022:
CPY_URL_TO_PAYLOAD_STR_ADDR:                .WORD CPY_URL_TO_PAYLOAD_STR

URL_STR:                                    .ASCIIZ "URL: "
str023:
URL_STR_ADDR:                               .WORD URL_STR



NOT_OPENED_STR:                             .ASCIIZ "UNIT NOT OPENED!"
str025:
NOT_OPENED_STR_ADDR:                        .WORD NOT_OPENED_STR

CANT_RESTORE_STR:                           .BYTE $0D,"SOMETHING ELSE CHANGED HIMEM; CAN'T RESTORE ORIGINAL HIMEM.", $00
str026:
CANT_RESTORE_STR_ADDR:                      .WORD CANT_RESTORE_STR 

RESTORE_HIMEM_STR:                          .BYTE   $0D, "RESTORING HIMEM...", $00
str027:
RESTORE_HIMEM_STR_ADDR:                     .WORD RESTORE_HIMEM_STR

EXTREMOVED_STR:                             .BYTE   $0D, "FUJINET EXTENSIONS REMOVED.", $0D, $00
str028:
EXTREMOVED_STR_ADDR:                        .WORD EXTREMOVED_STR

NOTFOUND_STR:                               .BYTE   $0D, "FUJINET COMMAND NOT FOUND -- FORWARDING TO NEXT AMPERSAND ROUTINE", $0D, $00
str029:
NOT_FOUND_STR_ADDR:                         .WORD NOTFOUND_STR

DEV_LIST_STR:                               .ASCIIZ " SMARTPORT DEVICE LIST "
str033:
DEV_LIST_STR_ADDR:                          .WORD DEV_LIST_STR


UNIT_STR:                                   .ASCIIZ "UNIT #"
str034:         
UNIT_STR_ADDR:                              .WORD UNIT_STR

NAME_STR:                                   .ASCIIZ " NAME: "
str035:
NAME_STR_ADDR:                              .WORD NAME_STR


VENDER_STR:                                 .ASCIIZ "VENDER ID: "
str036:
VENDER_STR_ADDR:                            .WORD VENDER_STR


VENDER_VERSION_STR:                         .ASCIIZ "VENDER VERSION: "
str037:
VENDER_VERSION_STR_ADDR:                    .WORD VENDER_VERSION_STR

COUNT_STR:                                  .ASCIIZ "DEVICE COUNT: "
str038:
COUNT_STR_ADDR:                             .WORD COUNT_STR

SP_ERROR_STR:                               .ASCIIZ "SMARTPORT ERROR: "
str039:
SP_ERROR_STR_ADDR:                          .WORD SP_ERROR_STR

SP_SUCCESS_STR:                             .ASCIIZ "SMARTPORT SUCCESS:  "
str024:
SP_SUCCESS_STR_ADDR:                        .WORD SP_SUCCESS_STR

FUJI_DISK_0_STR:                            .ASCIIZ "FUJINET_DISK_0"
str040:
FUJI_DISK_0_STR_ADDR:                       .WORD FUJI_DISK_0_STR

NETWORK_STR:                                .ASCIIZ "NETWORK"
str041:
NETWORK_STR_ADDR:                           .WORD NETWORK_STR

; NOT A STRING, BUT NEEDED ANYWAY
str042:
FAKE_DISPATCHER_ADDR:                       .WORD FAKE_DISPATCHER