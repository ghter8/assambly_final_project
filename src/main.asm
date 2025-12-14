; file: src/main.asm
; MASM x64 Windows GUI (Fixed CreateWindowEx Stack Layout)

EXTERN GetModuleHandleW: PROC
EXTERN LoadCursorW: PROC
EXTERN RegisterClassExW: PROC
EXTERN CreateWindowExW: PROC
EXTERN ShowWindow: PROC
EXTERN UpdateWindow: PROC
EXTERN GetMessageW: PROC
EXTERN TranslateMessage: PROC
EXTERN DispatchMessageW: PROC
EXTERN PostQuitMessage: PROC
EXTERN DefWindowProcW: PROC
EXTERN ExitProcess: PROC
EXTERN BeginPaint: PROC
EXTERN EndPaint: PROC
EXTERN FillRect: PROC
EXTERN CreateSolidBrush: PROC
EXTERN DeleteObject: PROC
EXTERN SetTimer: PROC
EXTERN InvalidateRect: PROC

; ==========================================
; 結構定義
; ==========================================
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

; ==========================================
; 資料區段
; ==========================================
.data
    ClassName       DW 'M', 'y', 'W', 'i', 'n', 'C', 'l', 'a', 's', 's', 0
    WindowName      DW 'M', 'A', 'S', 'M', ' ', 'R', 'e', 'n', 'd', 'e', 'r', 0
    hInstance       QWORD   0
    hWnd            QWORD   0
    color_val       DWORD   0
    color_step      DWORD   5

.data?
    wc              WNDCLASSEXW <>
    msg             WinMsg      <>
    ps              PAINTSTRUCT <>

; ==========================================
; 程式碼區段
; ==========================================
.code

main_asm PROC
    ; 進入點堆疊對齊 (Shadow Space 32 + Align 8 = 40)
    sub     rsp, 40

    ; 1. GetModuleHandle
    mov     rcx, 0
    call    GetModuleHandleW
    mov     [hInstance], rax

    ; 2. 準備 WNDCLASSEXW
    mov     wc.cbSize, SIZEOF WNDCLASSEXW
    mov     wc.style, 3             ; CS_HREDRAW | CS_VREDRAW
    lea     rax, WndProc
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

    ; 3. RegisterClassExW
    lea     rcx, wc
    call    RegisterClassExW
    ; 檢查註冊是否成功 (非 0 為成功)
    cmp     rax, 0
    je      ExitApp_Direct

    ; =================================================================
    ; 4. CreateWindowExW (關鍵修正部分)
    ; =================================================================
    ; 我們需要傳遞 12 個參數。
    ; 前 4 個在暫存器 (RCX, RDX, R8, R9)
    ; 後 8 個在堆疊。
    ; 我們需要分配：
    ;   32 bytes (Shadow Space for Callee)
    ; + 64 bytes (8 arguments * 8 bytes)
    ; = 96 bytes (0x60)
    ; 96 是 16 的倍數，所以堆疊保持對齊。
    
    sub     rsp, 96                 ; 一次性分配所有空間

    ; --- 填寫堆疊上的參數 (從 Param 5 到 Param 12) ---
    ; 偏移量算法： Shadow Space (32) + (ParamIndex - 5) * 8
    
    ; Param 12: lpParam (NULL) -> rsp + 32 + 7*8 = rsp + 88
    mov     qword ptr [rsp + 88], 0

    ; Param 11: hInstance
    mov     rax, [hInstance]
    mov     qword ptr [rsp + 80], rax

    ; Param 10: hMenu (NULL)
    mov     qword ptr [rsp + 72], 0

    ; Param 9: hWndParent (NULL)
    mov     qword ptr [rsp + 64], 0

    ; Param 8: nHeight (600)
    mov     qword ptr [rsp + 56], 600

    ; Param 7: nWidth (800)
    mov     qword ptr [rsp + 48], 800

    ; Param 6: y (CW_USEDEFAULT = 80000000h)
    mov     qword ptr [rsp + 40], 80000000h

    ; Param 5: x (CW_USEDEFAULT = 80000000h)
    mov     qword ptr [rsp + 32], 80000000h

    ; --- 填寫暫存器參數 (Param 1 到 Param 4) ---
    ; Param 4: dwStyle (WS_OVERLAPPEDWINDOW)
    mov     r9d, 0CF0000h           ; WS_OVERLAPPEDWINDOW hex value
    
    ; Param 3: lpWindowName
    lea     r8, WindowName
    
    ; Param 2: lpClassName
    lea     rdx, ClassName
    
    ; Param 1: dwExStyle (0)
    mov     rcx, 0

    call    CreateWindowExW
    
    ; 恢復堆疊
    add     rsp, 96

    ; --- 檢查視窗是否創建成功 ---
    mov     [hWnd], rax
    cmp     rax, 0
    je      ExitApp_Direct          ; 如果 rax 為 0，表示失敗，直接退出

    ; 5. ShowWindow
    mov     rcx, [hWnd]
    mov     rdx, 1                  ; SW_SHOWNORMAL
    call    ShowWindow

    ; 6. UpdateWindow
    mov     rcx, [hWnd]
    call    UpdateWindow

    ; 7. SetTimer
    mov     rcx, [hWnd]
    mov     rdx, 1
    mov     r8, 10
    mov     r9, 0
    call    SetTimer

    ; 8. Message Loop
MsgLoop:
    lea     rcx, msg
    mov     rdx, 0
    mov     r8, 0
    mov     r9, 0
    call    GetMessageW
    
    cmp     eax, 0
    jle     ExitApp                 ; GetMessage return 0 or -1 means exit

    lea     rcx, msg
    call    TranslateMessage
    
    lea     rcx, msg
    call    DispatchMessageW
    jmp     MsgLoop

ExitApp:
    mov     rcx, msg.wParam
    call    ExitProcess

ExitApp_Direct:
    mov     rcx, 0
    call    ExitProcess

main_asm ENDP

; ==========================================
; WndProc
; ==========================================
WndProc PROC
    mov     [rsp+8], rcx
    mov     [rsp+16], rdx
    mov     [rsp+24], r8
    mov     [rsp+32], r9
    sub     rsp, 40

    cmp     edx, 0002h              ; WM_DESTROY
    je      HandleDestroy
    
    cmp     edx, 000Fh              ; WM_PAINT
    je      HandlePaint

    cmp     edx, 0113h              ; WM_TIMER
    je      HandleTimer

    mov     rcx, [rsp+48]
    mov     rdx, [rsp+56]
    mov     r8, [rsp+64]
    mov     r9, [rsp+72]
    call    DefWindowProcW
    jmp     FinishWndProc

HandleTimer:
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

    mov     ecx, [color_val]        ; Red channel
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