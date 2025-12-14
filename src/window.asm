; file: src/window.asm
; 視窗管理模組

INCLUDE common.inc  ; 引入結構定義

; --- 宣告 Windows API ---
EXTERN GetModuleHandleW: PROC
EXTERN LoadCursorW: PROC
EXTERN RegisterClassExW: PROC
EXTERN CreateWindowExW: PROC
EXTERN ShowWindow: PROC
EXTERN UpdateWindow: PROC
EXTERN DefWindowProcW: PROC
EXTERN PostQuitMessage: PROC
EXTERN BeginPaint: PROC
EXTERN EndPaint: PROC
EXTERN FillRect: PROC
EXTERN CreateSolidBrush: PROC
EXTERN DeleteObject: PROC
EXTERN SetTimer: PROC
EXTERN InvalidateRect: PROC

; --- 公開函式 (讓 main.asm 使用) ---
PUBLIC InitWindow
PUBLIC WndProc

.data
    ClassName       DW 'M', 'y', 'W', 'i', 'n', 'C', 'l', 'a', 's', 's', 0
    WindowName      DW 'M', 'A', 'S', 'M', ' ', 'M', 'o', 'd', 'u', 'l', 'a', 'r', 0
    hInstance       QWORD   0
    hWnd            QWORD   0
    
    ; 渲染相關變數
    color_val       DWORD   0
    color_step      DWORD   5

.data?
    wc              WNDCLASSEXW <>
    ps              PAINTSTRUCT <>

.code

; ==========================================================
; InitWindow: 負責註冊類別、建立視窗、設定 Timer
; 回傳: RAX = 視窗句柄 (hWnd), 失敗回傳 0
; ==========================================================
InitWindow PROC
    sub     rsp, 40                 ; Shadow space

    ; 1. GetModuleHandle
    mov     rcx, 0
    call    GetModuleHandleW
    mov     [hInstance], rax

    ; 2. 設定 WNDCLASSEXW
    mov     wc.cbSize, SIZEOF WNDCLASSEXW
    mov     wc.style, 3
    lea     rax, WndProc            ; 指向本檔案下方的 WndProc
    mov     wc.lpfnWndProc, rax
    mov     wc.cbClsExtra, 0
    mov     wc.cbWndExtra, 0
    mov     rax, [hInstance]
    mov     wc.hInstance, rax
    mov     wc.hIcon, 0
    
    mov     rcx, 0
    mov     rdx, 32512              ; IDC_ARROW
    call    LoadCursorW
    mov     wc.hCursor, rax
    
    mov     wc.hbrBackground, 6     ; WHITE_BRUSH
    mov     wc.lpszMenuName, 0
    lea     rax, ClassName
    mov     wc.lpszClassName, rax
    mov     wc.hIconSm, 0

    ; 3. 註冊
    lea     rcx, wc
    call    RegisterClassExW
    test    rax, rax
    jz      InitFail

    ; 4. 建立視窗 (Stack Args)
    sub     rsp, 96
    mov     qword ptr [rsp + 88], 0 ; lpParam
    mov     rax, [hInstance]
    mov     qword ptr [rsp + 80], rax
    mov     qword ptr [rsp + 72], 0 ; hMenu
    mov     qword ptr [rsp + 64], 0 ; Parent
    mov     qword ptr [rsp + 56], 600 ; H
    mov     qword ptr [rsp + 48], 800 ; W
    mov     qword ptr [rsp + 40], 80000000h ; Y
    mov     qword ptr [rsp + 32], 80000000h ; X

    mov     r9d, 0CF0000h           ; Style
    lea     r8, WindowName
    lea     rdx, ClassName
    mov     rcx, 0                  ; ExStyle
    call    CreateWindowExW
    add     rsp, 96

    mov     [hWnd], rax
    test    rax, rax
    jz      InitFail

    ; 5. 顯示與更新
    mov     rcx, [hWnd]
    mov     rdx, 1
    call    ShowWindow

    mov     rcx, [hWnd]
    call    UpdateWindow

    ; 6. Timer
    mov     rcx, [hWnd]
    mov     rdx, 1
    mov     r8, 10
    mov     r9, 0
    call    SetTimer

    mov     rax, [hWnd]             ; 回傳 hWnd
    add     rsp, 40
    ret

InitFail:
    mov     rax, 0
    add     rsp, 40
    ret
InitWindow ENDP

; ==========================================================
; WndProc: 訊息處理 (邏輯不變)
; ==========================================================
WndProc PROC
    mov     [rsp+8], rcx
    mov     [rsp+16], rdx
    mov     [rsp+24], r8
    mov     [rsp+32], r9
    sub     rsp, 40

    cmp     edx, 0002h
    je      HandleDestroy
    cmp     edx, 000Fh
    je      HandlePaint
    cmp     edx, 0113h
    je      HandleTimer

    mov     rcx, [rsp+48]
    mov     rdx, [rsp+56]
    mov     r8, [rsp+64]
    mov     r9, [rsp+72]
    call    DefWindowProcW
    jmp     FinishWndProc

HandleTimer:
    ; 顏色邏輯
    mov     eax, [color_val]
    add     eax, [color_step]
    cmp     eax, 255
    jle     CheckLow
    mov     dword ptr [color_step], -5
    mov     eax, 255
    jmp     UpdateColor
CheckLow:
    cmp     eax, 0
    jge     UpdateColor
    mov     dword ptr [color_step], 5
    mov     eax, 0
UpdateColor:
    mov     [color_val], eax

    mov     rcx, [rsp+48]
    mov     rdx, 0
    mov     r8, 0
    call    InvalidateRect
    mov     rax, 0
    jmp     FinishWndProc

HandlePaint:
    mov     rcx, [rsp+48]
    lea     rdx, ps
    call    BeginPaint
    mov     rbx, rax

    mov     ecx, [color_val]
    call    CreateSolidBrush
    mov     r12, rax

    mov     rcx, rbx
    lea     rdx, ps.rc.left
    mov     r8, r12
    call    FillRect

    mov     rcx, r12
    call    DeleteObject

    mov     rcx, [rsp+48]
    lea     rdx, ps
    call    EndPaint
    mov     rax, 0
    jmp     FinishWndProc

HandleDestroy:
    mov     rcx, 0
    call    PostQuitMessage
    mov     rax, 0

FinishWndProc:
    add     rsp, 40
    ret
WndProc ENDP

END