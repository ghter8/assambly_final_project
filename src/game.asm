

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
    xSpeed      SWORD   0
    ySpeed      SWORD   0
    Jumping     BYTE    0
    Falling     BYTE    0
    TopBound    BYTE    0
    BottomBound BYTE    0
    RightBound  BYTE    0
    LeftBound   BYTE    0


.code

Movement PROC
    ; 根據按鍵狀態更新玩家位置
    cmp     Status, 0
    jne     blue

    mov     xSpeed, 0
    mov     ySpeed, 0

    cmp     Key_Left, 1
    jne     MoveLeft
    sub     xSpeed, 2
MoveLeft:
    cmp     Key_Right, 1
    jne     MoveRight
    add     xSpeed, 2
MoveRight:
    cmp     Key_Up, 1
    jne     MoveUp
    add     ySpeed, 2
MoveUp:
    cmp     Key_Down, 1
    jne     MoveDown
    sub     ySpeed, 2
MoveDown:
    jmp     EndMovement

blue:
EndMovement:
    ; 更新玩家位置
    mov     eax, PlayerX
    add     eax, xSpeed
    mov     PlayerX, eax

    mov     eax, PlayerY
    add     eax, ySpeed
    mov     PlayerY, eax

    ret

Movement ENDP

Throw PROC
    mov     Status, al
    mov     Falling, ah
Throw ENDP

END