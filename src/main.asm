TITLE   主程式入口  ; file: src/main.asm

INCLUDE common.inc  ; 引入結構

EXTERN ExitProcess: PROC
EXTERN GetMessageW: PROC
EXTERN TranslateMessage: PROC
EXTERN DispatchMessageW: PROC

; --- 公開變數 ---
PUBLIC gaming

.data
    gaming  BYTE    0

.data?
    msg     WinMsg  <>

.code
main_asm PROC
    sub     rsp, 40

    ; 1. 呼叫外部模組初始化視窗
    call    InitWindow
    
    ; 檢查是否成功 (RAX != 0)
    cmp     rax, 0
    je      ExitApp

    ; 2. 訊息迴圈
MsgLoop:
    lea     rcx, msg
    mov     rdx, 0
    mov     r8, 0
    mov     r9, 0
    call    GetMessageW
    
    cmp     eax, 0
    jle     ExitApp

    ; ... (檢查 Timer 訊息) ...
    cmp     msg.message, 0113h
    jne     SkipGameLogic

    call    UpdateInput
    
    ; 1. 玩家移動
    call    Movement

    ; 2. [新增] 更新特效物件狀態
    call    UpdateObjects

    ; 3. [新增] 測試生成：按下 Z 鍵時產生特效
    ; 我們在玩家當前位置生成一個物件，並讓它隨機或固定方向飄走
    cmp     Key_Z, 1
    jne     SkipSpawn
    
    ; 參數: X=PlayerX, Y=PlayerY, DirX=2, DirY=-2 (往右上方飛)
    mov     ecx, [PlayerX]
    mov     edx, [PlayerY]
    mov     r8d, 2
    mov     r9d, -2
    call    SpawnObject
    
    ; (為了避免按住 Z 一次噴太多，您可以加一個冷卻機制，但暫時先這樣看效果)

SkipSpawn:
    ; --------------------------------------

SkipGameLogic:
    ; 3. 繼續原本的 Windows 訊息分派 (處理繪圖、視窗操作等)
    lea     rcx, msg
    call    TranslateMessage
    
    lea     rcx, msg
    call    DispatchMessageW
    jmp     MsgLoop

ExitApp:
    mov     rcx, 0
    call    ExitProcess

main_asm ENDP
END