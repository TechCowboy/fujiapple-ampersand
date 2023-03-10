
.IF .NOT .DEFINED(CIDERPRESS_CORRUPTION_TEST)

; THESE STRINGS ARE USED DURING INITIALIZATION AND
; WON'T BE USED AFTERWARDS SO DON'T NEED TO BE RELOCATED

CIDERPRESS_CORRUPTION_TEST:                 .BYTE $0A, "CIDERPRESS CORRUPTED FILE", $00

EXTADDED_STR:                               .BYTE "FUJINET EXTENSIONS ADDED.", $0D, $00
SP_NOT_FOUND_STR:                           .BYTE "NO SMARTPORT! EXTENSIONS NOT LOADED", $0D, $00
EXITING_STR:                                .BYTE "EXITING...", $0D, $00
FUJIAPPLE_VER_STR:                          .BYTE "FUJIAPPLE VERSION: YYYYMMDD.HHMM", $0D, $00

.IF .NOT USE_SP

TEST_BLOCK_STR_LEN: .BYTE 255
TEST_BLOCK_STR:
    .BYTE "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt "
    .BYTE $00
    .BYTE "labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco "
    .BYTE "laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in "
    .BYTE "voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat "
    .BYTE "non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    .BYTE $00

trace046:
TEST_BLOCK_STR_ADDR: .WORD TEST_BLOCK_STR
.ENDIF

.IF .NOT STRIP_TRACE

HERE1:  .BYTE "HERE1", $0D, $00
HERE2:  .BYTE "HERE2", $0D, $00
HERE3:  .BYTE "HERE3", $0D, $00
HERE4:  .BYTE "HERE4", $0D, $00
HERE5:  .BYTE "HERE5", $0D, $00
HERE6:  .BYTE "HERE6", $0D, $00
HERE7:  .BYTE "HERE7", $0D, $00
HERE8:  .BYTE "HERE8", $0D, $00

; NOT NEEDED IF WE'RE NOT DEBUGGING

HIMEM_IS_STR:                               .ASCIIZ "OLD HIMEM: "
RELOC_SIZE_STR:                             .ASCIIZ "RELOCATION SIZE: "
RELOCATING_STR:                             .BYTE   " NEW HIMEM: ", $00

OPEN_ERR_STR:                               .ASCIIZ "FN_OPEN: OPEN ERR:"
CTRL_ERR_STR:                               .ASCIIZ "FN_OPEN: CTRL ERR:"


.ENDIF

; THESE STRING ARE USED AFTER RELOCATING

.IF .NOT STRIP_TRACE

; NOT NEEDED IF WE'RE NOT USING TRACE

NOPEN_STR:                                  .BYTE "NOPEN ", $00
trace000:
NOPEN_STR_ADDR:                             .WORD NOPEN_STR

NREAD_STR:                                  .BYTE "NREAD ", $00
trace001:
NREAD_STR_ADDR:                             .WORD NREAD_STR

NCLOSE_STR:                                 .BYTE "NCLOSE ",  $00
trace002:
NCLOSE_STR_ADDR:                            .WORD NCLOSE_STR, $0D, $00

NSTATUS_STR:                                .BYTE "NSTATUS ", $00
trace003:
NSTATUS_STR_ADDR:                           .WORD NSTATUS_STR

NEND_STR:                                   .BYTE "NEND", $0D, $00
trace004:
NEND_STR_ADDR:                              .WORD NEND_STR

NLIST_STR:                                  .BYTE "NLIST", $0D, $00
trace005:
NLIST_STR_ADDR:                             .WORD NLIST_STR

NTRACE_STR:                                 .BYTE "NTRACE", $0D, $00 
trace006:
NTRACE_STR_ADDR:                            .WORD NTRACE_STR

NWRITE_STR:                                 .BYTE "NWRITE", $0D, $00
trace007:
NWRITE_STR_ADDR:                            .WORD NWRITE_STR

NCTRL_STR:                                  .BYTE "NCTRL", $0D, $00
trace008:
NCTRL_STR_ADDR:                             .WORD NCTRL_STR

FIND_SMARTPORT_SLOT_STR:                    .BYTE "FIND_SMARTPORT_SLOT", $0D, $00
trace009:
FIND_SMARTPORT_SLOT_STR_ADDR:               .WORD FIND_SMARTPORT_SLOT_STR

GET_SMARTPORT_DISPATCH_ADDRESS_STR:         .BYTE "GET_SMARTPORT_DISPATCH_ADDRESS", $0D, $00
trace010:
GET_SMARTPORT_DISPATCH_ADDRESS_STR_ADDR:    .WORD GET_SMARTPORT_DISPATCH_ADDRESS_STR

DISPATCHER_ADDRESS_STR:                     .ASCIIZ "DISPATCHER ADDRESS:" 
trace011:
DISPATCHER_ADDRESS_STR_ADDR:                .WORD DISPATCHER_ADDRESS_STR

SP_OPEN_STR:                                .BYTE "SP_OPEN:",    $00
trace012:
SP_OPEN_STR_ADDR:                           .WORD SP_OPEN_STR

SP_READ_STR:                                .BYTE "SP_READ:", $00
trace042:
SP_READ_STR_ADDR:                           .WORD SP_READ_STR

SP_WRITE_STR:                               .BYTE "SP_WRITE:", $00
trace043:
SP_WRITE_STR_ADDR:                          .WORD SP_WRITE_STR



SP_CLOSE_STR:                               .BYTE "SP_CLOSE:",   $00
trace013:
SP_CLOSE_STR_ADDR:                          .WORD SP_CLOSE_STR

SP_CONTROL_STR:                             .BYTE $0D, "SP_CONTROL:", $00
trace014:
SP_CONTROL_STR_ADDR:                        .WORD SP_CONTROL_STR

SP_STATUS_STR:                              .BYTE $0D, "SP_STATUS:", $00
trace015:
SP_STATUS_STR_ADDR:                         .WORD SP_STATUS_STR

CALL_DISPATCHER_STR:                        .BYTE "CALL_DISPATCHER",   $0D, $00
trace016:
CALL_DISPATCHER_STR_ADDR:                   .WORD CALL_DISPATCHER_STR

DISPLAY_SP_STATUS_STR:                      .BYTE "DISPLAY_SP_STATUS", $0D, $00
trace017:
DISPLAY_SP_STATUS_STR_ADDR:                 .WORD DISPLAY_SP_STATUS_STR

SP_FIND_DEVICE_STR:                         .BYTE "SP_FIND_DEVICE:",    $00
trace018:
SP_FIND_DEVICE_STR_ADDR:                    .WORD SP_FIND_DEVICE_STR

REAL_SMARTPORT_STR:                         .BYTE "REAL SMARTPORT", $0D, $00
trace019:
REAL_SMARTPORT_STR_ADDR:                    .WORD REAL_SMARTPORT_STR

FN_FIND_NETWORK_STR:                        .BYTE "FN_FIND_NETWORK"    , $0D, $00
trace021:
FN_FIND_NETWORK_STR_ADDR:                   .WORD FN_FIND_NETWORK_STR

FN_BYTES_WAITING_STR:                       .BYTE "FN_BYTES_WAITING:", $00
trace022:
FN_BYTES_WAITING_STR_ADDR:                  .WORD FN_BYTES_WAITING_STR

FN_IS_CONNECTED_STR:                        .BYTE "FN_IS_CONNECTED:" , $00
trace023:
FN_IS_CONNECTED_STR_ADDR:                   .WORD FN_IS_CONNECTED_STR

FN_OPEN_STR:                                .BYTE "FN_OPEN:"         , $00
trace024:
FN_OPEN_STR_ADDR:                           .WORD FN_OPEN_STR

FN_CLOSE_STR:                               .BYTE "FN_CLOSE:"        , $00
trace025:
FN_CLOSE_STR_ADDR:                          .WORD FN_CLOSE_STR

CPY_URL_TO_PAYLOAD_STR:                     .BYTE "CPY_URL_TO_PAYLOAD", $0D, $00
trace026:
CPY_URL_TO_PAYLOAD_STR_ADDR:                .WORD CPY_URL_TO_PAYLOAD_STR

URL_STR:                                    .ASCIIZ "URL: "
trace027:
URL_STR_ADDR:                               .WORD URL_STR

MODE_STR:                                   .ASCIIZ "MODE: "
trace031:
MODE_STR_ADDR:                              .WORD MODE_STR

TRANS_STR:                                  .ASCIIZ "TRANS: "
trace032:
TRANS_STR_ADDR:                             .WORD TRANS_STR

LEN_STR:                                    .ASCIIZ "LEN:"
trace033:
LEN_STR_ADDR:                               .WORD LEN_STR

PAYLOAD_STR:                                .BYTE "PAY:", $00
trace034:
PAYLOAD_STR_ADDR:                           .WORD PAYLOAD_STR

CMD_LIST_STR:                               .BYTE $0D, "CMD_LIST: ", $00
trace047:
CMD_LIST_STR_ADDR:                          .WORD CMD_LIST_STR

FOUND_DEVICE_STR:                           .BYTE "FOUND DEVICE!", $0D, $00
trace035:
FOUND_DEVICE_STR_ADDR:                      .WORD FOUND_DEVICE_STR

CLOSE_ERROR_STR:                            .BYTE "CLOSE ERROR", $00
trace036:
CLOSE_ERROR_STR_ADDR:                       .WORD CLOSE_ERROR_STR

FN_READ_STR:                                .BYTE "FN_READ:", $00
trace037:       
FN_READ_STR_ADDR:                           .WORD FN_READ_STR

FN_READ_ERROR_STR:                          .BYTE "FN_READ ERROR", $0D, $00
trace038:
FN_READ_ERROR_STR_ADDR:                     .WORD FN_READ_ERROR_STR

FN_WRITE_STR:                               .BYTE "FN_WRITE", $00
trace039:
FN_WRITE_STR_ADDR:                          .WORD FN_WRITE_STR

FN_WRITE_ERROR_STR:                         .BYTE "FN WRITE ERROR", $0D, $00
trace045:
FN_WRITE_ERROR_STR_ADDR:                    .WORD FN_WRITE_ERROR_STR

SP_READ_ERROR_STR:                          .BYTE "SP_READ ERROR", $0D, $00
trace040:
SP_READ_ERROR_STR_ADDR:                     .WORD SP_READ_ERROR_STR

NREAD_ERROR_STR:                            .BYTE "NREAD_ERROR", $0D, $00
trace041:
NREAD_ERROR_STR_ADDR:                       .WORD NREAD_ERROR_STR

SP_FIND_DEVICE_ERROR_STR:                   .BYTE $0D, "SP_FIND_DEVICE ERROR!", $00
trace044:
SP_FIND_DEVICE_ERROR_STR_ADDR:              .WORD SP_FIND_DEVICE_ERROR_STR

.ENDIF

NOT_OPENED_STR:                             .ASCIIZ "UNIT NOT OPENED!"
str000:
NOT_OPENED_STR_ADDR:                        .WORD NOT_OPENED_STR

CANT_RESTORE_STR:                           .BYTE $0D,"SOMETHING ELSE CHANGED HIMEM; CAN'T RESTORE ORIGINAL HIMEM.", $00
str001:
CANT_RESTORE_STR_ADDR:                      .WORD CANT_RESTORE_STR 

RESTORE_HIMEM_STR:                          .BYTE   $0D, "RESTORING HIMEM...", $00
str002:
RESTORE_HIMEM_STR_ADDR:                     .WORD RESTORE_HIMEM_STR

EXTREMOVED_STR:                             .BYTE   $0D, "FUJINET EXTENSIONS REMOVED.", $0D, $00
str003:
EXTREMOVED_STR_ADDR:                        .WORD EXTREMOVED_STR

NOTFOUND_STR:                               .BYTE   $0D, "FUJINET COMMAND NOT FOUND -- FORWARDING TO NEXT AMPERSAND ROUTINE", $0D, $00
str004:
NOT_FOUND_STR_ADDR:                         .WORD NOTFOUND_STR

DEV_LIST_STR:                               .ASCIIZ " SMARTPORT DEVICE LIST "
str005:
DEV_LIST_STR_ADDR:                          .WORD DEV_LIST_STR

UNIT_STR:                                   .ASCIIZ "UNIT #"
str006:         
UNIT_STR_ADDR:                              .WORD UNIT_STR

NAME_STR:                                   .ASCIIZ " NAME: "
str007:
NAME_STR_ADDR:                              .WORD NAME_STR

VENDER_STR:                                 .ASCIIZ "VENDER ID: "
str008:
VENDER_STR_ADDR:                            .WORD VENDER_STR

VENDER_VERSION_STR:                         .ASCIIZ "VENDER VERSION: "
str009:
VENDER_VERSION_STR_ADDR:                    .WORD VENDER_VERSION_STR

COUNT_STR:                                  .ASCIIZ "DEVICE COUNT: "
str010:
COUNT_STR_ADDR:                             .WORD COUNT_STR

SP_ERROR_STR:                               .ASCIIZ "SMARTPORT ERROR: "
str011:
SP_ERROR_STR_ADDR:                          .WORD SP_ERROR_STR

SP_SUCCESS_STR:                             .ASCIIZ "SMARTPORT SUCCESS:  "
str012:
SP_SUCCESS_STR_ADDR:                        .WORD SP_SUCCESS_STR

FUJI_DISK_0_STR_LEN:                        .BYTE 14
FUJI_DISK_0_STR:                            .ASCIIZ "FUJINET_DISK_0"
str013:
FUJI_DISK_0_STR_ADDR:                       .WORD FUJI_DISK_0_STR

NETWORK_STR_LEN:                            .BYTE 7
NETWORK_STR:                                .ASCIIZ "NETWORK"
str014:
NETWORK_STR_ADDR:                           .WORD NETWORK_STR

NETWORK_STR_WITH_NUMBER_LEN:                .BYTE 9
NETWORK_STR_WITH_NUMBER:                    .ASCIIZ "NETWORK_1"
str015:
NETWORK_STR_WITH_NUMBER_ADDR:               .WORD NETWORK_STR_WITH_NUMBER
NETWORK_STR_WITH_NUMBER_INDEX:              .BYTE 8

DEVICE_NOT_FOUND_STR:                       .ASCIIZ "DEVICE NOT FOUND!"
str016:
DEVICE_NOT_FOUND_STR_ADDR:                  .WORD DEVICE_NOT_FOUND_STR

NETWORK_NOT_FOUND_STR:                      .ASCIIZ "NETWORK DEVICE NOT FOUND!"
str017:
NETWORK_NOT_FOUND_STR_ADDR:                 .WORD NETWORK_NOT_FOUND_STR

; NOT A STRING, BUT NEEDED ANYWAY

.IF .NOT USE_SP
trace030:
FAKE_DISPATCHER_ADDR:                       .WORD FAKE_DISPATCHER

FAKE_SMARTPORT_STR:                         .BYTE "**** FAKE SMARTPORT ****", $0D, $00
trace020:
FAKE_SMARTPORT_STR_ADDR:                    .WORD FAKE_SMARTPORT_STR

.ENDIF

.ENDIF