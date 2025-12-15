; file: src/input.asm
; 輸入系統

IS_INPUT_MODULE EQU 1
INCLUDE common.inc

EXTERN GetAsyncKeyState: PROC

PUBLIC UpdateInput
PUBLIC Key_Up, Key_Down, Key_Left, Key_Right, Key_Space, Key_Escape

.data
    Key_Up      BYTE    0
    Key_Down    BYTE    0
    Key_Left    BYTE    0
    Key_Right   BYTE    0
    Key_Space   BYTE    0
    Key_Escape  BYTE    0

.code
UpdateInput PROC
    sub     rsp, 40

    ; UP
    mov     rcx, 26h
    call    GetAsyncKeyState
    test    ax, 8000h
    setnz   [Key_Up]

    ; DOWN
    mov     rcx, 28h
    call    GetAsyncKeyState
    test    ax, 8000h
    setnz   [Key_Down]

    ; LEFT
    mov     rcx, 25h
    call    GetAsyncKeyState
    test    ax, 8000h
    setnz   [Key_Left]

    ; RIGHT
    mov     rcx, 27h
    call    GetAsyncKeyState
    test    ax, 8000h
    setnz   [Key_Right]

    ; SPACE (VK_SPACE = 0x20)
    mov     rcx, 20h
    call    GetAsyncKeyState
    test    ax, 8000h
    setnz   [Key_Space]

    ; ESCAPE
    mov     rcx, 1Bh
    call    GetAsyncKeyState
    test    ax, 8000h
    setnz   [Key_Escape]

    add     rsp, 40
    ret
UpdateInput ENDP
END