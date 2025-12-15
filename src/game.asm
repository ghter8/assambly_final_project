

IS_GAME_MODULE EQU 1

INCLUDE common.inc

PUBLIC Status
PUBLIC PlayerX
PUBLIC PlayerY
PUBLIC HP
PUBLIC KR
PUBLIC Movement

PUBLIC ObjectPool
PUBLIC SpawnObject
PUBLIC UpdateObjects

.data

    ; 遊戲相關變數
    PlayerX     SDWORD   400
    PlayerY     SDWORD   300
    Status      BYTE    0
    HP          BYTE    92
    KR          BYTE    92
    xSpeed      SDWORD   0
    ySpeed      SDWORD   0
    Jumping     BYTE    0
    Falling     BYTE    0
    TopBound    SDWORD    200
    BottomBound SDWORD    400
    RightBound  SDWORD    300
    LeftBound   SDWORD    500

    ; --- 物件池 (陣列) ---
    ; 宣告 10 個 GameObject，記憶體連續排列
    ObjectPool  GameObject MAX_OBJECTS DUP(<>)

    ; 參數設定
    FadeSpeed   DWORD   35       ; 淡入淡出速度
    StayTime    DWORD   50      ; 物件完全顯示後停留多久 (幀數)

.code

Movement PROC
    ; 根據按鍵狀態更新玩家位置
    cmp     Status, 0
    jne     blue

    mov     xSpeed, 0
    mov     ySpeed, 0

    cmp     Key_Left, 1
    jne     MoveLeft
    sub     xSpeed, 3
MoveLeft:
    cmp     Key_Right, 1
    jne     MoveRight
    add     xSpeed, 3
MoveRight:
    cmp     Key_Up, 1
    jne     MoveUp
    sub     ySpeed, 3
MoveUp:
    cmp     Key_Down, 1
    jne     MoveDown
    add     ySpeed, 3
MoveDown:
    jmp     EndMovement

blue:
    cmp     Key_Left, 1
    jne     bMoveLeft
    sub     xSpeed, 3
bMoveLeft:
    cmp     Key_Right, 1
    jne     bMoveRight
    add     xSpeed, 3
bMoveRight:
    cmp     Key_Up, 1
    jne     EndMovement
    mov     eax, PlayerY
    cmp     eax, bottomBound
    jne     MoveNoJump
    mov     ySpeed, -3
    mov     Jumping, 1
MoveNoJump:

EndMovement:
    ; 更新玩家位置
    mov     eax, PlayerX
    add     eax, xSpeed
    mov     PlayerX, eax

    mov     eax, PlayerY
    add     eax, ySpeed
    mov     PlayerY, eax

    mov     eax, PlayerY
    cmp     eax, topBound
    jg      noTopBound
    mov     eax, topBound
noTopBound:
    cmp     eax, bottomBound
    jl      noBottomBound
    mov     eax, bottomBound
noBottomBound:
    mov     PlayerY, eax
    mov     eax, PlayerX
    cmp     eax, leftBound
    jl      noLeftBound
    mov     eax, leftBound
noLeftBound:
    cmp     eax, rightBound
    jg      noRightBound
    mov     eax, rightBound
noRightBound:
    mov     PlayerX, eax

    ret

Movement ENDP

setRed PROC
    mov     Status, 0
    mov     Falling, 0
    mov     Jumping, 0
setRed ENDP

Throw PROC
    mov     Status, al
    mov     Falling, ah
    mov     ySpeed, 30
Throw ENDP

; ==========================================
; SpawnObject
; 功能：在指定位置產生一個淡入物件
; 參數：ECX = X, EDX = Y, R8D = DirX, R9D = DirY
; ==========================================
SpawnObject PROC
    ; 保存暫存器 (因為我們會用到迴圈)
    push    rbx
    push    rsi

    ; 初始化迴圈
    mov     rsi, 0                  ; 索引 Index
    lea     rbx, ObjectPool         ; RBX 指向陣列開頭

FindSlotLoop:
    ; 檢查這個位置是否是「死掉」的物件
    cmp     [rbx].GameObject.state, OBJ_DEAD
    je      FoundSlot               ; 找到空位了！

    ; 下一個
    add     rbx, SIZEOF GameObject  ; 移動指標到下一個物件
    inc     rsi
    cmp     rsi, MAX_OBJECTS
    jl      FindSlotLoop
    
    ; 如果找完一圈都沒空位，就直接放棄不生成
    jmp     SpawnEnd

FoundSlot:
    ; 重置物件狀態
    mov     [rbx].GameObject.state, OBJ_FADE_IN
    mov     [rbx].GameObject.x, ecx
    mov     [rbx].GameObject.y, edx
    mov     [rbx].GameObject.dirX, r8d
    mov     [rbx].GameObject.dirY, r9d
    mov     [rbx].GameObject.alpha, 0       ; 初始透明度 0
    mov     [rbx].GameObject.lifeTime, 0

SpawnEnd:
    pop     rsi
    pop     rbx
    ret
SpawnObject ENDP

; ==========================================
; UpdateObjects
; 功能：更新所有存活物件的狀態 (移動、淡入淡出)
; ==========================================
UpdateObjects PROC
    push    rbx
    push    rsi

    mov     rsi, 0
    lea     rbx, ObjectPool

UpdateLoop:
    ; 如果是死的，跳過
    cmp     [rbx].GameObject.state, OBJ_DEAD
    je      NextObj

    ; 1. 更新位置 (X += dirX, Y += dirY)
    mov     eax, [rbx].GameObject.dirX
    add     [rbx].GameObject.x, eax
    mov     eax, [rbx].GameObject.dirY
    add     [rbx].GameObject.y, eax

    ; 2. 狀態機處理
    mov     eax, [rbx].GameObject.state
    
    cmp     eax, OBJ_FADE_IN
    je      DoFadeIn
    cmp     eax, OBJ_ACTIVE
    je      DoActive
    cmp     eax, OBJ_FADE_OUT
    je      DoFadeOut
    jmp     NextObj

DoFadeIn:
    ; 透明度增加
    mov     eax, [rbx].GameObject.alpha
    add     eax, [FadeSpeed]
    cmp     eax, 255
    jl      SaveAlphaIn
    
    ; 淡入完成 -> 轉為 ACTIVE
    mov     eax, 255
    mov     [rbx].GameObject.state, OBJ_ACTIVE
    
    ; 設定停留時間
    mov     ecx, [StayTime]
    mov     [rbx].GameObject.lifeTime, ecx

SaveAlphaIn:
    mov     [rbx].GameObject.alpha, eax
    jmp     NextObj

DoActive:
    ; 倒數計時
    dec     [rbx].GameObject.lifeTime
    cmp     [rbx].GameObject.lifeTime, 0
    jg      NextObj
    
    ; 時間到 -> 轉為 FADE_OUT
    mov     [rbx].GameObject.state, OBJ_FADE_OUT
    jmp     NextObj

DoFadeOut:
    ; 透明度減少
    mov     eax, [rbx].GameObject.alpha
    sub     eax, [FadeSpeed]
    cmp     eax, 0
    jg      SaveAlphaOut
    
    ; 淡出完成 -> 死亡 (釋放位置)
    mov     eax, 0
    mov     [rbx].GameObject.state, OBJ_DEAD

SaveAlphaOut:
    mov     [rbx].GameObject.alpha, eax
    jmp     NextObj

NextObj:
    add     rbx, SIZEOF GameObject
    inc     rsi
    cmp     rsi, MAX_OBJECTS
    jl      UpdateLoop

    pop     rsi
    pop     rbx
    ret
UpdateObjects ENDP

END