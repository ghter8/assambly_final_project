; file: src/window.asm
; 恐龍遊戲渲染模組 (雙緩衝防閃爍版)

IS_WINDOW_MODULE EQU 1
INCLUDE common.inc

; --- API 宣告 ---
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
EXTERN TextOutW: PROC
EXTERN SetTextColor: PROC
EXTERN SetBkMode: PROC

; [新增] 雙緩衝需要用到的 API
EXTERN CreateCompatibleBitmap: PROC

PUBLIC InitWindow
PUBLIC WndProc

; 常數
IMAGE_BITMAP    EQU 0
LR_LOADFROMFILE EQU 10h
SRCCOPY         EQU 00CC0020h
TRANSPARENT     EQU 1

.data
    ClassName       DW 'D', 'i', 'n', 'o', 'G', 'a', 'm', 'e', 0
    WindowName      DW 'M', 'A', 'S', 'M', ' ', 'D', 'i', 'n', 'o', 0
    
    DinoImg1        DW 'r', 'e', 's', 'o', 'u', 'r', 'c', 'e', 's', '\', 'd', 'i', 'n', 'o', '2', '.', 'b', 'm', 'p', 0
    DinoImg2        DW 'r', 'e', 's', 'o', 'u', 'r', 'c', 'e', 's', '\', 'd', 'i', 'n', 'o', '1', '.', 'b', 'm', 'p', 0
    ObsImg          DW 'r', 'e', 's', 'o', 'u', 'r', 'c', 'e', 's', '\', 'c', 'a', 'c', 't', 'u', 's', '.', 'b', 'm', 'p', 0

    ScorePrefix     DW 'S', 'c', 'o', 'r', 'e', ':', ' ', 0
    
    hInstance       QWORD   0
    hWnd            QWORD   0
    
    ; [新增] 兩個 Bitmap Handle
    hBitmapDino1    QWORD   0
    hBitmapDino2    QWORD   0
    hBitmapObs      QWORD   0
    
    bmWidth         DWORD   0
    bmHeight        DWORD   0

    BITMAP_STRUCT STRUCT
        bmType       DWORD ?
        bmWidth      DWORD ?
        bmHeight     DWORD ?
        bmWidthBytes DWORD ?
        bmPlanes     WORD  ?
        bmBitsPixel  WORD  ?
        padding      DWORD ?
        bmBits       QWORD ?
    BITMAP_STRUCT ENDS

.data?
    wc              WNDCLASSEXW   <>
    ps              PAINTSTRUCT   <>
    bmInfo          BITMAP_STRUCT <>
    ScoreBuffer     WORD    32 DUP(?) 

.code

InitWindow PROC
    sub     rsp, 104
    mov     rcx, 0
    call    GetModuleHandleW
    mov     [hInstance], rax

    call    InitPictures

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
    
    ; 背景設為 NULL，告訴 Windows 不要幫我們擦除背景 (避免第一次閃爍)
    mov     wc.hbrBackground, 0 
    
    mov     wc.lpszMenuName, 0
    lea     rax, ClassName
    mov     wc.lpszClassName, rax
    mov     wc.hIconSm, 0

    lea     rcx, wc
    call    RegisterClassExW
    
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

    mov     rcx, [hWnd]
    mov     rdx, 1
    call    ShowWindow
    mov     rcx, [hWnd]
    call    UpdateWindow

    mov     rcx, [hWnd]
    mov     rdx, 1
    mov     r8, 10
    mov     r9, 0
    call    SetTimer

    mov     rax, [hWnd]
    add     rsp, 104
    ret
InitWindow ENDP

WndProc PROC
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 112    ; 增加堆疊空間

    ; 保存參數
    mov     [rsp+112+40+8], rcx
    mov     [rsp+112+40+16], rdx
    mov     [rsp+112+40+24], r8
    mov     [rsp+112+40+32], r9

    cmp     edx, 0002h
    je      HandleDestroy
    cmp     edx, 000Fh
    je      HandlePaint
    cmp     edx, 0113h
    je      HandleTimer

    mov     rcx, [rsp+112+40+8]
    mov     rdx, [rsp+112+40+16]
    mov     r8,  [rsp+112+40+24]
    mov     r9,  [rsp+112+40+32]
    call    DefWindowProcW
    jmp     FinishWndProc

HandleTimer:
    mov     rcx, [rsp+112+40+8]
    mov     rdx, 0
    mov     r8, 0
    call    InvalidateRect
    mov     rax, 0
    jmp     FinishWndProc

HandlePaint:
    mov     rcx, [rsp+112+40+8]
    lea     rdx, ps
    call    BeginPaint
    mov     rbx, rax            ; RBX = hDC (真實螢幕)

    ; ==========================================================
    ; [雙緩衝] 1. 建立虛擬畫布 (Memory DC)
    ; ==========================================================
    mov     rcx, rbx
    call    CreateCompatibleDC
    mov     r12, rax            ; R12 = hMemDC (虛擬畫布)

    ; ==========================================================
    ; [雙緩衝] 2. 建立與螢幕相容的點陣圖 (Canvas)
    ; ==========================================================
    mov     r8, 600             ; Height
    mov     rdx, 800            ; Width
    mov     rcx, rbx            ; hDC
    call    CreateCompatibleBitmap
    mov     r13, rax            ; R13 = hBitmap (虛擬紙張)

    ; ==========================================================
    ; [雙緩衝] 3. 將紙張選入虛擬畫布
    ; ==========================================================
    mov     rcx, r12
    mov     rdx, r13
    call    SelectObject
    ; (這裡應該保存舊的 bitmap 以便還原，這裡簡化省略)

    ; ==========================================================
    ; [開始繪圖] 注意：所有繪圖指令的目標 (RCX) 都要改成 R12 (hMemDC)
    ; ==========================================================

    ; A. 塗黑背景
    mov     ecx, 0
    call    CreateSolidBrush
    mov     r14, rax
    
    ; 設定全螢幕範圍
    mov     ps.rc.left, 0
    mov     ps.rc.top, 0
    mov     ps.rc.right, 800
    mov     ps.rc.bottom, 600
    
    mov     rcx, r12            ; <--- 改用 hMemDC
    lea     rdx, ps.rc
    mov     r8, r14
    call    FillRect
    mov     rcx, r14
    call    DeleteObject

    ; B. 畫地板
    mov     ecx, 0FFFFFFh
    call    CreateSolidBrush
    mov     r14, rax
    
    mov     ps.rc.left, 0
    mov     ps.rc.top, 440
    mov     ps.rc.right, 800
    mov     ps.rc.bottom, 442
    
    mov     rcx, r12            ; <--- 改用 hMemDC
    lea     rdx, ps.rc
    mov     r8, r14
    call    FillRect
    mov     rcx, r14
    call    DeleteObject

    ; C. 畫恐龍
    ; [修改] 根據 DinoFrame 決定要畫哪張圖
    cmp     [hBitmapDino1], 0   ; 確保至少第一張圖存在
    je      DrawObs

    mov     rcx, r12
    call    CreateCompatibleDC
    mov     r14, rax
    
    ; --- 判斷 Frame ---
    cmp     [DinoFrame], 1
    je      UseFrame2
    
UseFrame1:
    mov     rdx, [hBitmapDino1]
    jmp     SelectDino
    
UseFrame2:
    ; 如果第二張圖沒讀到 (Handle=0)，就還是用第一張
    cmp     [hBitmapDino2], 0
    je      UseFrame1
    mov     rdx, [hBitmapDino2]

SelectDino:
    mov     rcx, r14
    call    SelectObject

    ; BitBlt (參數根據您的圖片尺寸調整)
    mov     qword ptr [rsp+64], SRCCOPY
    mov     qword ptr [rsp+56], 0
    mov     qword ptr [rsp+48], 0
    mov     qword ptr [rsp+40], r14
    
    ; [注意] 這裡假設兩張圖尺寸一樣 (例如高 47)
    mov     qword ptr [rsp+32], 47      ; Height
    mov     r9d, 44                     ; Width
    
    ; 如果要對齊底部，這裡記得做偏移 (例如 Y - 7)
    mov     r8d, [PlayerY]
    sub     r8d, 7                      ; [選用] 視覺偏移修正
    
    mov     edx, [PlayerX]
    mov     rcx, r12
    call    BitBlt

    mov     rcx, r14
    call    DeleteDC

DrawObs:
    ; D. 畫障礙物
    cmp     [hBitmapObs], 0
    je      DrawUI

    mov     rcx, r12
    call    CreateCompatibleDC
    mov     r14, rax
    mov     rcx, r14
    mov     rdx, [hBitmapObs]
    call    SelectObject

    mov     r15, 0
    lea     rsi, Obstacles      ; 使用 RSI 遍歷障礙物

ObsLoop:
    cmp     [rsi].GameObject.active, 1
    jne     NextObsDraw

    mov     qword ptr [rsp+64], SRCCOPY
    mov     qword ptr [rsp+56], 0
    mov     qword ptr [rsp+48], 0
    mov     qword ptr [rsp+40], r14     ; 來源
    mov     eax, [rsi].GameObject.h
    mov     [rsp+32], rax
    mov     r9d, 51
    mov     r8d, [rsi].GameObject.y
    mov     edx, [rsi].GameObject.x
    mov     rcx, r12                    ; <--- 目標是 hMemDC
    call    BitBlt

NextObsDraw:
    add     rsi, SIZEOF GameObject
    inc     r15
    cmp     r15, MAX_OBSTACLES
    jl      ObsLoop

    mov     rcx, r14
    call    DeleteDC

DrawUI:
    ; E. 畫分數
    mov     rdx, TRANSPARENT
    mov     rcx, r12            ; <--- hMemDC
    call    SetBkMode

    mov     rdx, 00FFFFFFh
    mov     rcx, r12            ; <--- hMemDC
    call    SetTextColor

    mov     qword ptr [rsp+32], 7
    lea     r9, ScorePrefix
    mov     r8, 20
    mov     rdx, 20
    mov     rcx, r12            ; <--- hMemDC
    call    TextOutW

    lea     rdi, ScoreBuffer
    mov     eax, [Score]
    call    IntToUnicode

    mov     qword ptr [rsp+32], rax
    lea     r9, ScoreBuffer
    mov     r8, 20
    mov     rdx, 80
    mov     rcx, r12            ; <--- hMemDC
    call    TextOutW

    ; ==========================================================
    ; [雙緩衝] 4. 一次性貼到螢幕 (BitBlt)
    ; ==========================================================
    mov     qword ptr [rsp+64], SRCCOPY
    mov     qword ptr [rsp+56], 0
    mov     qword ptr [rsp+48], 0
    mov     qword ptr [rsp+40], r12     ; 來源是 hMemDC
    mov     qword ptr [rsp+32], 600     ; Height
    mov     r9d, 800                    ; Width
    mov     r8d, 0                      ; Y
    mov     edx, 0                      ; X
    mov     rcx, rbx                    ; 目標是 真實螢幕 (hDC)
    call    BitBlt

    ; ==========================================================
    ; [雙緩衝] 5. 清理資源 (非常重要，否則記憶體會洩漏)
    ; ==========================================================
    
    ; 刪除虛擬畫布 (hMemDC)
    mov     rcx, r12
    call    DeleteDC

    ; 刪除虛擬紙張 (hBitmap) - 這一點很容易忘記！
    mov     rcx, r13
    call    DeleteObject

EndPaintJob:
    mov     rcx, [rsp+112+40+8]
    lea     rdx, ps
    call    EndPaint
    mov     rax, 0
    jmp     FinishWndProc

HandleDestroy:
    mov     rcx, 0
    call    PostQuitMessage
    mov     rax, 0

FinishWndProc:
    add     rsp, 112
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
WndProc ENDP

InitPictures PROC
    sub     rsp, 56
    
    ; 載入恐龍 1
    mov     rcx, 0
    lea     rdx, DinoImg1
    mov     r8, IMAGE_BITMAP
    mov     r9, 0
    mov     qword ptr [rsp+32], 0
    mov     qword ptr [rsp+40], 10h
    call    LoadImageW
    mov     [hBitmapDino1], rax

    ; [新增] 載入恐龍 2
    mov     rcx, 0
    lea     rdx, DinoImg2
    mov     r8, IMAGE_BITMAP
    mov     r9, 0
    mov     qword ptr [rsp+32], 0
    mov     qword ptr [rsp+40], 10h
    call    LoadImageW
    mov     [hBitmapDino2], rax

    ; 載入障礙物
    mov     rcx, 0
    lea     rdx, ObsImg
    mov     r8, IMAGE_BITMAP
    mov     r9, 0
    mov     qword ptr [rsp+32], 0
    mov     qword ptr [rsp+40], 10h
    call    LoadImageW
    mov     [hBitmapObs], rax

    add     rsp, 56
    ret
InitPictures ENDP

IntToUnicode PROC
    push    rbx
    push    rdx
    push    rdi
    test    eax, eax
    jnz     ConvertLoop
    mov     word ptr [rdi], '0'
    mov     rax, 1
    jmp     ConvertEnd
ConvertLoop:
    mov     rbx, 0
    mov     ecx, 10
PushDigits:
    xor     edx, edx
    div     ecx
    add     dx, '0'
    push    dx
    inc     rbx
    test    eax, eax
    jnz     PushDigits
    mov     rax, rbx
PopDigits:
    pop     dx
    mov     [rdi], dx
    add     rdi, 2
    dec     rbx
    jnz     PopDigits
    mov     word ptr [rdi], 0
ConvertEnd:
    pop     rdi
    pop     rdx
    pop     rbx
    ret
IntToUnicode ENDP

END