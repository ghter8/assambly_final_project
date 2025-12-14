; file: src/common.inc
; 共用結構定義

WNDCLASSEXW STRUCT
    cbSize          DWORD   ?
    style           DWORD   ?
    lpfnWndProc     QWORD   ?
    cbClsExtra      DWORD   ?
    cbWndExtra      DWORD   ?
    hInstance       QWORD   ?
    hIcon           QWORD   ?
    hCursor         QWORD   ?
    hbrBackground   QWORD   ?
    lpszMenuName    QWORD   ?
    lpszClassName   QWORD   ?
    hIconSm         QWORD   ?
WNDCLASSEXW ENDS

POINT STRUCT
    x               SDWORD  ?
    y               SDWORD  ?
POINT ENDS

WinMsg STRUCT
    hwnd            QWORD   ?
    message         DWORD   ?
    padding1        DWORD   ?
    wParam          QWORD   ?
    lParam          QWORD   ?
    time            DWORD   ?
    pt              POINT   <>
    padding2        DWORD   ?
WinMsg ENDS

RECT STRUCT
    left            SDWORD  ?
    top             SDWORD  ?
    right           SDWORD  ?
    bottom          SDWORD  ?
RECT ENDS

PAINTSTRUCT STRUCT
    hdc             QWORD   ?
    fErase          DWORD   ?
    rc              RECT    <>
    fRestore        DWORD   ?
    fIncUpdate      DWORD   ?
    rgbReserved     BYTE    32 DUP(?)
PAINTSTRUCT ENDS

; 讓所有引入此檔案的模組都能「看見」這些變數
EXTERN Key_Up:      BYTE
EXTERN Key_Down:    BYTE
EXTERN Key_Left:    BYTE
EXTERN Key_Right:   BYTE
EXTERN Key_Space:   BYTE

; 宣告函式
EXTERN UpdateInput: PROC