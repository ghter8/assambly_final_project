

IS_GAME_MODULE EQU 1

INCLUDE common.inc

PUBLIC Status

.data

    ; 遊戲相關變數
    PlayerX     DWORD   100
    PlayerY     DWORD   100
    Status      BYTE    0
    HP          BYTE    92
    KR          BYTE    0
    Jumping     BYTE    0
    Falling     BYTE    0
    TopBound    BYTE    0
    BottomBound BYTE    0
    RightBound  BYTE    0
    LeftBound   BYTE    0


.code

Throw PROC
    mov     Status, al
    mov     Falling, ah
Throw ENDP

END