; file: src/game.asm
; 恐龍遊戲邏輯核心

IS_GAME_MODULE EQU 1
INCLUDE common.inc

PUBLIC PlayerX, PlayerY
PUBLIC GameState, Score
PUBLIC Obstacles
PUBLIC UpdateGame
PUBLIC DinoFrame

; 遊戲常數
GROUND_Y        EQU 400     ; 地板高度 (Y座標)
GRAVITY         EQU 1       ; 重力加速度
JUMP_FORCE      EQU -15     ; 跳躍初速度 (負值往上)
GAME_SPEED      EQU 8       ; 障礙物移動速度
SPAWN_RATE      EQU 60      ; 障礙物生成頻率 (約每 60 幀一次)

; 狀態常數
STATE_PLAYING   EQU 0
STATE_GAMEOVER  EQU 1

.data
    PlayerX     SDWORD  100     ; 恐龍固定在左側
    PlayerY     SDWORD  GROUND_Y
    
    VelocityY   SDWORD  0       ; Y 軸速度
    IsJumping   BYTE    0       ; 是否在空中

    GameState   DWORD   STATE_PLAYING
    Score       DWORD   0
    
    ; 障礙物池
    Obstacles   GameObject MAX_OBSTACLES DUP(<>)
    
    SpawnTimer  DWORD   0       ; 生成計時器

    ; [新增] 動畫相關變數
    DinoFrame   DWORD   0       ; 目前是第幾張圖 (0或1)
    AnimTimer   DWORD   0       ; 動畫計時器
    ANIM_SPEED  EQU     10      ; 每 10 幀換一次圖 (數字越大跑越慢)

.code

; ==========================================================
; UpdateGame: 主遊戲迴圈
; ==========================================================
UpdateGame PROC
    ; 如果遊戲結束，就不更新邏輯 (按下 Space 重來)
    cmp     GameState, STATE_GAMEOVER
    je      CheckRestart

    ; 1. 玩家物理運算 (重力與跳躍)
    call    UpdatePhysics

    ; 2. 障礙物管理 (移動與生成)
    call    UpdateObstacles

    ; 3. 碰撞檢測
    call    CheckCollision

    ; [新增] 更新恐龍動畫
    call    UpdateAnimation

    ; 4. 分數增加
    inc     Score
    ret

CheckRestart:
    ; 遊戲結束狀態：按 Space 重置遊戲
    cmp     Key_Space, 1
    je      ResetGame
    ret

UpdateGame ENDP

; ==========================================================
; UpdatePhysics: 處理跳躍與重力
; ==========================================================
UpdatePhysics PROC
    ; --- 施加重力 ---
    mov     eax, VelocityY
    add     eax, GRAVITY
    mov     VelocityY, eax

    ; --- 更新 Y 座標 ---
    mov     eax, PlayerY
    add     eax, VelocityY
    mov     PlayerY, eax

    ; --- 地板碰撞檢測 ---
    cmp     PlayerY, GROUND_Y
    jl      CheckJumpInput      ; 如果在空中 (Y < Ground)，檢查是否要跳 (二段跳? 這裡先不做)
    
    ; 著地處理
    mov     PlayerY, GROUND_Y
    mov     VelocityY, 0
    mov     IsJumping, 0

    ; --- 跳躍輸入檢測 (只有在地板上才能跳) ---
    cmp     Key_Space, 1        ; 檢查 Space
    je      DoJump
    cmp     Key_Up, 1           ; 或是 Up 也可以跳
    je      DoJump
    jmp     EndPhysics

DoJump:
    mov     VelocityY, JUMP_FORCE
    mov     IsJumping, 1

EndPhysics:
    ret
CheckJumpInput:
    ret
UpdatePhysics ENDP

; ==========================================================
; UpdateObstacles: 障礙物移動與生成
; ==========================================================
UpdateObstacles PROC
    ; --- 1. 移動現有障礙物 ---
    mov     r10, 0              ; Loop index
    lea     rbx, Obstacles      ; 指向陣列

MoveLoop:
    cmp     [rbx].GameObject.active, 1
    jne     NextObs

    ; X -= Speed
    mov     eax, [rbx].GameObject.x
    sub     eax, GAME_SPEED
    mov     [rbx].GameObject.x, eax

    ; 檢查是否超出左邊界 (回收)
    cmp     eax, -50
    jg      NextObs
    mov     [rbx].GameObject.active, 0  ; 關閉

NextObs:
    add     rbx, SIZEOF GameObject
    inc     r10
    cmp     r10, MAX_OBSTACLES
    jl      MoveLoop

    ; --- 2. 生成新障礙物 ---
    inc     SpawnTimer
    cmp     SpawnTimer, SPAWN_RATE
    jl      EndObs
    
    ; 重置計時器 (可以加入隨機性讓遊戲更有趣，這裡先固定)
    mov     SpawnTimer, 0
    call    SpawnObstacle

EndObs:
    ret
UpdateObstacles ENDP

; ==========================================================
; SpawnObstacle: 找一個空位生成障礙物
; ==========================================================
SpawnObstacle PROC
    mov     r10, 0
    lea     rbx, Obstacles

FindSlot:
    cmp     [rbx].GameObject.active, 0
    je      FoundSlot
    
    add     rbx, SIZEOF GameObject
    inc     r10
    cmp     r10, MAX_OBSTACLES
    jl      FindSlot
    ret ; 沒空位就不生了

FoundSlot:
    mov     [rbx].GameObject.active, 1
    mov     [rbx].GameObject.x, 800     ; 從螢幕最右邊出現
    mov     [rbx].GameObject.y, 420     ; 障礙物高度 (比地板低一點，因為圖片原點在左上)
    mov     [rbx].GameObject.w, 40      ; 碰撞箱寬
    mov     [rbx].GameObject.h, 40      ; 碰撞箱高
    ret
SpawnObstacle ENDP

; ==========================================================
; CheckCollision: 簡單矩形碰撞 (AABB)
; ==========================================================
CheckCollision PROC
    ; 玩家碰撞箱 (假設 40x40)
    ; Player Box: x1=PlayerX, x2=PlayerX+40, y1=PlayerY, y2=PlayerY+40
    
    mov     r10, 0
    lea     rbx, Obstacles

ColLoop:
    cmp     [rbx].GameObject.active, 1
    jne     NextCol

    ; 檢查 X 軸重疊
    ; if (PlayerRight > ObsLeft && PlayerLeft < ObsRight)
    mov     eax, PlayerX
    add     eax, 40             ; PlayerRight
    cmp     eax, [rbx].GameObject.x
    jle     NextCol             ; 沒撞到 (玩家在障礙物左邊)

    mov     eax, [rbx].GameObject.x
    add     eax, [rbx].GameObject.w ; ObsRight
    cmp     PlayerX, eax
    jge     NextCol             ; 沒撞到 (玩家在障礙物右邊)

    ; 檢查 Y 軸重疊
    ; if (PlayerBottom > ObsTop && PlayerTop < ObsBottom)
    mov     eax, PlayerY
    add     eax, 40             ; PlayerBottom
    cmp     eax, [rbx].GameObject.y
    jle     NextCol             ; 沒撞到 (玩家在障礙物上面)
    
    ; 這裡簡化：只要 X 重疊且玩家不夠高 (Y > ObsY - PlayerH) 就算撞到
    ; 實際上只要檢測玩家是否跳過障礙物
    mov     eax, [rbx].GameObject.y
    add     eax, [rbx].GameObject.h
    cmp     PlayerY, eax
    jge     NextCol             ; 沒撞到 (玩家在障礙物下面?? 不太可能)

    ; --- 撞到了！ ---
    mov     GameState, STATE_GAMEOVER
    ret

NextCol:
    add     rbx, SIZEOF GameObject
    inc     r10
    cmp     r10, MAX_OBSTACLES
    jl      ColLoop
    ret
CheckCollision ENDP

; ==========================================================
; [新增] UpdateAnimation: 控制跑步動作
; ==========================================================
UpdateAnimation PROC
    ; 1. 如果在跳躍中，固定顯示第 0 張 (或是您可以設成第 1 張當作跳躍姿勢)
    cmp     IsJumping, 1
    je      SetJumpFrame

    ; 2. 跑步動畫：計時器累加
    inc     AnimTimer
    cmp     AnimTimer, ANIM_SPEED
    jl      EndAnim

    ; 3. 時間到，切換 Frame (0 -> 1, 1 -> 0)
    mov     AnimTimer, 0
    xor     DinoFrame, 1        ; XOR 1 可以讓 0變1, 1變0
    jmp     EndAnim

SetJumpFrame:
    mov     DinoFrame, 0        ; 跳躍時固定姿勢
    mov     AnimTimer, 0        ; 重置計時

EndAnim:
    ret
UpdateAnimation ENDP

; ==========================================================
; ResetGame: 重置所有變數
; ==========================================================
ResetGame PROC
    mov     PlayerY, GROUND_Y
    mov     VelocityY, 0
    mov     Score, 0
    mov     SpawnTimer, 0
    mov     GameState, STATE_PLAYING

    ; 清空所有障礙物
    mov     r10, 0
    lea     rbx, Obstacles
ClearLoop:
    mov     [rbx].GameObject.active, 0
    add     rbx, SIZEOF GameObject
    inc     r10
    cmp     r10, MAX_OBSTACLES
    jl      ClearLoop
    ret
ResetGame ENDP

END