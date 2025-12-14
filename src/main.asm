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

    ; ==========================================================
    ; [核心修正] 固定時間步 (Fixed Time Step)
    ; 只有當訊息是 WM_TIMER (0x0113) 時，才執行遊戲邏輯
    ; 這樣可以避免滑鼠移動導致角色速度暴衝
    ; ==========================================================
    cmp     msg.message, 0113h  ; 檢查是否為 WM_TIMER
    jne     SkipGameLogic       ; 如果不是 Timer，跳過邏輯，直接處理訊息

    ; --- 遊戲邏輯區塊 (每 10ms 執行一次) ---
    call    UpdateInput         ; 1. 更新按鍵狀態

    ; 檢查離開
    cmp     Key_Escape, 1
    je      ExitApp

    call    Movement            ; 2. 計算角色移動

    ; 檢查 Z 鍵 (範例功能)
    cmp     Key_Z, 1
    jne     SkipZ
    mov     gaming, 1
SkipZ:
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