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