; file: src/window.asm
; 顯示 BMP 圖片 (Debug Mode + Register Safety)

__WINDOW_ASM__ EQU 1
INCLUDE common.inc

; ==========================================================
; API 宣告
; ==========================================================
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
EXTERN LoadImageW: PROC
EXTERN CreateCompatibleDC: PROC
EXTERN SelectObject: PROC
EXTERN BitBlt: PROC
EXTERN DeleteDC: PROC
EXTERN GetObjectW: PROC
EXTERN MessageBoxW: PROC

PUBLIC InitWindow
PUBLIC WndProc

; ==========================================================
; 常數與資料
; ==========================================================
IMAGE_BITMAP    EQU 0
LR_LOADFROMFILE EQU 10h
SRCCOPY         EQU 00CC0020h

.data
    ClassName       DW 'M', 'y', 'I', 'm', 'g', 'C', 'l', 'a', 's', 's', '_', 'v', '4', 0
    WindowName      DW 'M', 'A', 'S', 'M', ' ', 'D', 'e', 'b', 'u', 'g', 0
    
    ; 請確認檔名正確
    BitmapFileName      DW 'r', 'e', 's', 'o', 'u', 'r', 'c', 'e', 's', '\', 's', 'o', 'u', 'l', '_', 'r', 'e', 'd', '.', 'b', 'm', 'p', 0
    BitmapFileName_bd   DW 'r', 'e', 's', 'o', 'u', 'r', 'c', 'e', 's', '\', 's', 'o', 'u', 'l', '_', 'b', 'l', 'u', 'e', '_', 'd', 'o', 'w', 'n', '.', 'b', 'm', 'p', 0
    BitmapFileName_bu   DW 'r', 'e', 's', 'o', 'u', 'r', 'c', 'e', 's', '\', 's', 'o', 'u', 'l', '_', 'b', 'l', 'u', 'e', '_', 'u', 'p', '.', 'b', 'm', 'p', 0
    BitmapFileName_bl   DW 'r', 'e', 's', 'o', 'u', 'r', 'c', 'e', 's', '\', 's', 'o', 'u', 'l', '_', 'b', 'l', 'u', 'e', '_', 'l', 'e', 'f', 't', '.', 'b', 'm', 'p', 0
    BitmapFileName_br   DW 'r', 'e', 's', 'o', 'u', 'r', 'c', 'e', 's', '\', 's', 'o', 'u', 'l', '_', 'b', 'l', 'u', 'e', '_', 'r', 'i', 'g', 'h', 't', '.', 'b', 'm', 'p', 0

    ErrTitle        DW 'D', 'e', 'b', 'u', 'g', 0
    ErrLoadImg      DW 'L', 'o', 'a', 'd', 'I', 'm', 'a', 'g', 'e', ' ', 'F', 'a', 'i', 'l', 'e', 'd', 0
    ErrSize         DW 'I', 'm', 'a', 'g', 'e', ' ', 'S', 'i', 'z', 'e', ' ', 'i', 's', ' ', '0', 0
    ErrRegister     DW 'R', 'e', 'g', 'i', 's', 't', 'e', 'r', ' ', 'E', 'r', 'r', 'o', 'r', 0
    ErrCreate       DW 'C', 'r', 'e', 'a', 't', 'e', ' ', 'E', 'r', 'r', 'o', 'r', 0

    hInstance       QWORD   0
    hWnd            QWORD   0
    hBitmap         QWORD   0
    hBitmap_bd      QWORD   0
    hBitmap_bu      QWORD   0
    hBitmap_bl      QWORD   0
    hBitmap_br      QWORD   0
    bmWidth         DWORD   0
    bmHeight        DWORD   0

    ; 手動加入 padding 確保對齊
    BITMAP_STRUCT STRUCT
        bmType       DWORD ?
        bmWidth      DWORD ?
        bmHeight     DWORD ?
        bmWidthBytes DWORD ?
        bmPlanes     WORD  ?
        bmBitsPixel  WORD  ?
        padding      DWORD ? ; 補齊 4 bytes 讓 bmBits 在 offset 24
        bmBits       QWORD ?
    BITMAP_STRUCT ENDS

.data?
    wc              WNDCLASSEXW   <>
    ps              PAINTSTRUCT   <>
    bmInfo          BITMAP_STRUCT <>

.code

; ==========================================================
; InitWindow
; ==========================================================
InitWindow PROC
    sub     rsp, 104

    ; 1. GetModuleHandle
    mov     rcx, 0
    call    GetModuleHandleW
    mov     [hInstance], rax

    ; 2. LoadImageW
    call    InitPictures

    ; 檢查載入結果
    cmp     rax, 0
    jne     GetImgInfo

    ; 失敗報錯
    mov     rcx, 0
    lea     rdx, ErrLoadImg
    lea     r8, ErrTitle
    mov     r9, 10h
    call    MessageBoxW
    jmp     RegisterWin

GetImgInfo:
    mov     rcx, [hBitmap]
    mov     rdx, SIZEOF BITMAP_STRUCT
    lea     r8, bmInfo
    call    GetObjectW
    
    mov     eax, bmInfo.bmWidth
    mov     [bmWidth], eax
    mov     eax, bmInfo.bmHeight
    mov     [bmHeight], eax

    ; [DEBUG] 檢查寬度是否為 0
    cmp     eax, 0
    jg      RegisterWin

    ; 如果寬度是 0，報錯
    mov     rcx, 0
    lea     rdx, ErrSize
    lea     r8, ErrTitle
    mov     r9, 10h
    call    MessageBoxW

RegisterWin:
    ; 3. Register Class
    mov     wc.cbSize, SIZEOF WNDCLASSEXW
    mov     wc.style, 3
    lea     rax, WndProc
    mov     wc.lpfnWndProc, rax
    mov     wc.cbClsExtra, 0
    mov     wc.cbWndExtra, 0
    mov     rax, [hInstance]
    mov     wc.hInstance, rax
    mov     wc.hIcon, 0
    
    mov     rcx, 0
    mov     rdx, 32512
    call    LoadCursorW
    mov     wc.hCursor, rax
    
    mov     wc.hbrBackground, 6 ; WHITE_BRUSH
    mov     wc.lpszMenuName, 0
    lea     rax, ClassName
    mov     wc.lpszClassName, rax
    mov     wc.hIconSm, 0

    lea     rcx, wc
    call    RegisterClassExW
    
    test    rax, rax
    jz      FailRegister

    ; 4. Create Window
    mov     qword ptr [rsp+88], 0
    mov     rax, [hInstance]
    mov     qword ptr [rsp+80], rax
    mov     qword ptr [rsp+72], 0
    mov     qword ptr [rsp+64], 0
    mov     qword ptr [rsp+56], 600
    mov     qword ptr [rsp+48], 800
    mov     qword ptr [rsp+40], 80000000h
    mov     qword ptr [rsp+32], 80000000h

    mov     r9d, 0CF0000h
    lea     r8, WindowName
    lea     rdx, ClassName
    mov     rcx, 0
    call    CreateWindowExW

    mov     [hWnd], rax
    test    rax, rax
    jz      FailCreate

    ; 5. Show & Update
    mov     rcx, [hWnd]
    mov     rdx, 1
    call    ShowWindow

    mov     rcx, [hWnd]
    call    UpdateWindow

    mov     rax, [hWnd]
    add     rsp, 104
    ret

FailRegister:
    mov     rcx, 0
    lea     rdx, ErrRegister
    lea     r8, ErrTitle
    mov     r9, 10h
    call    MessageBoxW
    mov     rax, 0
    add     rsp, 104
    ret

FailCreate:
    mov     rcx, 0
    lea     rdx, ErrCreate
    lea     r8, ErrTitle
    mov     r9, 10h
    call    MessageBoxW
    mov     rax, 0
    add     rsp, 104
    ret
InitWindow ENDP

; ==========================================================
; WndProc
; ==========================================================
WndProc PROC
    ; [核心修正] 保存非依電性暫存器 (Non-Volatile Registers)
    ; 這是 Windows x64 呼叫約定強制要求的，否則會導致不預期的行為
    push    rbx
    push    r12
    push    r13

    ; 堆疊對齊計算:
    ; 進入時 RSP尾數=8
    ; push 3次 (24 bytes) -> RSP尾數=8-24 = -16 (0) -> 對齊了
    ; 我們需要分配 Shadow Space + BitBlt參數 (72 bytes)
    ; 選用 80 bytes (16的倍數)
    sub     rsp, 80

    mov     [rsp+80+32+8], rcx  ; 參數保存位置要加上 offset (80 + 32 pushes/ret)
    mov     [rsp+80+32+16], rdx
    mov     [rsp+80+32+24], r8
    mov     [rsp+80+32+32], r9

    cmp     edx, 0002h
    je      HandleDestroy
    cmp     edx, 000Fh
    je      HandlePaint

    ; Default
    mov     rcx, [rsp+80+32+8]
    mov     rdx, [rsp+80+32+16]
    mov     r8,  [rsp+80+32+24]
    mov     r9,  [rsp+80+32+32]
    call    DefWindowProcW
    jmp     FinishWndProc

HandlePaint:
    mov     rcx, [rsp+80+32+8]
    lea     rdx, ps
    call    BeginPaint
    mov     rbx, rax            ; RBX = hDestDC

    ; [DEBUG TEST 1] 先畫一個紅色矩形
    ; 如果您看到這個紅框，表示繪圖系統正常
    mov     ecx, 000000FFh      ; 紅色 (0x00BBGGRR)
    call    CreateSolidBrush
    mov     r12, rax
    
    ; 畫在 (10, 10) 到 (60, 60)
    mov     ps.rc.left, 10
    mov     ps.rc.top, 10
    mov     ps.rc.right, 60
    mov     ps.rc.bottom, 60
    
    mov     rcx, rbx
    lea     rdx, ps.rc
    mov     r8, r12
    call    FillRect
    
    mov     rcx, r12
    call    DeleteObject

    ; [DEBUG TEST 2] 繪製圖片
    cmp     [hBitmap], 0
    je      EndPaintJob

    mov     rcx, rbx
    call    CreateCompatibleDC
    mov     r13, rax

    mov     rcx, r13
    mov     rdx, [hBitmap]
    call    SelectObject

    ; BitBlt
    mov     qword ptr [rsp+64], SRCCOPY
    mov     qword ptr [rsp+56], 0
    mov     qword ptr [rsp+48], 0
    mov     qword ptr [rsp+40], r13
    
    mov     eax, [bmHeight]
    mov     qword ptr [rsp+32], rax

    mov     r9d, [bmWidth]
    mov     r8, 100             ; Y = 100
    mov     rdx, 100            ; X = 100 (避開紅框)
    mov     rcx, rbx
    call    BitBlt

    mov     rcx, r13
    call    DeleteDC

EndPaintJob:
    mov     rcx, [rsp+80+32+8]
    lea     rdx, ps
    call    EndPaint
    mov     rax, 0
    jmp     FinishWndProc

HandleDestroy:
    cmp     [hBitmap], 0
    je      DoQuit
    mov     rcx, [hBitmap]
    call    DeleteObject

DoQuit:
    mov     rcx, 0
    call    PostQuitMessage
    mov     rax, 0

FinishWndProc:
    add     rsp, 80
    pop     r13
    pop     r12
    pop     rbx
    ret
WndProc ENDP

InitPictures PROC
    sub     rsp, 56         ; Shadow Space
    mov     rcx, 0
    lea     rdx, BitmapFileName
    mov     r8, IMAGE_BITMAP
    mov     r9, 0
    mov     qword ptr [rsp+32], 0
    mov     qword ptr [rsp+40], 10h
    call    LoadImageW
    
    mov     [hBitmap], rax
    
    mov     rcx, 0
    lea     rdx, BitmapFileName_bd
    mov     r8, IMAGE_BITMAP
    mov     r9, 0
    mov     qword ptr [rsp+32], 0
    mov     qword ptr [rsp+40], 10h
    call    LoadImageW
    
    mov     [hBitmap_bd], rax
    
    mov     rcx, 0
    lea     rdx, BitmapFileName_bu
    mov     r8, IMAGE_BITMAP
    mov     r9, 0
    mov     qword ptr [rsp+32], 0
    mov     qword ptr [rsp+40], 10h
    call    LoadImageW
    
    mov     [hBitmap_bu], rax
    
    mov     rcx, 0
    lea     rdx, BitmapFileName_bl
    mov     r8, IMAGE_BITMAP
    mov     r9, 0
    mov     qword ptr [rsp+32], 0
    mov     qword ptr [rsp+40], 10h
    call    LoadImageW
    
    mov     [hBitmap_bl], rax
    
    mov     rcx, 0
    lea     rdx, BitmapFileName_br
    mov     r8, IMAGE_BITMAP
    mov     r9, 0
    mov     qword ptr [rsp+32], 0
    mov     qword ptr [rsp+40], 10h
    call    LoadImageW
    
    mov     [hBitmap_br], rax
    add     rsp, 56
    ret
InitPictures ENDP

END