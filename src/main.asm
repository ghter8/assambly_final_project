; file: src/main.asm
; 主程式入口

INCLUDE common.inc  ; 引入結構

EXTERN ExitProcess: PROC
EXTERN GetMessageW: PROC
EXTERN TranslateMessage: PROC
EXTERN DispatchMessageW: PROC

; --- 引入我們在 window.asm 寫的函式 ---
EXTERN InitWindow: PROC

.data?
    msg     WinMsg      <>

.code
main_asm PROC
    sub     rsp, 40

    ; 1. 呼叫外部模組初始化視窗
    call    InitWindow
    
    ; 檢查是否成功 (RAX != 0)
    cmp     rax, 0
    je      ExitApp

    ; 2. 訊息迴圈 (只剩下這個邏輯)
MsgLoop:
    lea     rcx, msg
    mov     rdx, 0
    mov     r8, 0
    mov     r9, 0
    call    GetMessageW
    
    cmp     eax, 0
    jle     ExitApp

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