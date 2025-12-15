; file: src/window.asm
; 恐龍遊戲渲染模組

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

PUBLIC InitWindow
PUBLIC WndProc

; 常數
IMAGE_BITMAP    EQU 0
LR_LOADFROMFILE EQU 10h
SRCCOPY         EQU 00CC0020h

.data
    ClassName       DW 'D', 'i', 'n', 'o', 'G', 'a', 'm', 'e', 0
    WindowName      DW 'M', 'A', 'S', 'M', ' ', 'D', 'i', 'n', 'o', 0
    
    ; 使用現有圖片：紅色當恐龍，藍色當障礙物
    DinoImg         DW 'r', 'e', 's', 'o', 'u', 'r', 'c', 'e', 's', '\', 's', 'o', 'u', 'l', '_', 'r', 'e', 'd', '.', 'b', 'm', 'p', 0
    ObsImg          DW 'r', 'e', 's', 'o', 'u', 'r', 'c', 'e', 's', '\', 's', 'o', 'u', 'l', '_', 'b', 'l', 'u', 'e', '_', 'l', 'e', 'f', 't', '.', 'b', 'm', 'p', 0

    hInstance       QWORD   0
    hWnd            QWORD   0
    
    hBitmapDino     QWORD   0
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

.code

InitWindow PROC
    sub     rsp, 104
    mov     rcx, 0
    call    GetModuleHandleW
    mov     [hInstance], rax

    ; 載入圖片
    call    InitPictures

    ; 註冊視窗
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
    mov     wc.hbrBackground, 0 ; 黑色背景
    mov     wc.lpszMenuName, 0
    lea     rax, ClassName
    mov     wc.lpszClassName, rax
    mov     wc.hIconSm, 0

    lea     rcx, wc
    call    RegisterClassExW
    
    ; 建立視窗
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

    ; Timer (10ms = 100 FPS)
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
    sub     rsp, 80
    mov     [rsp+80+32+8], rcx
    mov     [rsp+80+32+16], rdx
    mov     [rsp+80+32+24], r8
    mov     [rsp+80+32+32], r9

    cmp     edx, 0002h
    je      HandleDestroy
    cmp     edx, 000Fh
    je      HandlePaint
    cmp     edx, 0113h
    je      HandleTimer

    mov     rcx, [rsp+80+32+8]
    mov     rdx, [rsp+80+32+16]
    mov     r8,  [rsp+80+32+24]
    mov     r9,  [rsp+80+32+32]
    call    DefWindowProcW
    jmp     FinishWndProc

HandleTimer:
    mov     rcx, [rsp+80+32+8]
    mov     rdx, 0
    mov     r8, 0
    call    InvalidateRect
    mov     rax, 0
    jmp     FinishWndProc

HandlePaint:
    mov     rcx, [rsp+80+32+8]
    lea     rdx, ps
    call    BeginPaint
    mov     rbx, rax

    ; 1. 塗黑背景
    mov     ecx, 0
    call    CreateSolidBrush
    mov     r12, rax
    mov     rcx, rbx
    lea     rdx, ps.rc
    mov     r8, r12
    call    FillRect
    mov     rcx, r12
    call    DeleteObject

    ; 2. 畫地板 (白色線條)
    ; 這裡簡單用白色矩形代替
    mov     ecx, 0FFFFFFh
    call    CreateSolidBrush
    mov     r12, rax
    
    ; 設定地板矩形 (Left=0, Top=440, Right=800, Bottom=442)
    mov     ps.rc.left, 0
    mov     ps.rc.top, 440
    mov     ps.rc.right, 800
    mov     ps.rc.bottom, 442
    
    mov     rcx, rbx
    lea     rdx, ps.rc
    mov     r8, r12
    call    FillRect
    mov     rcx, r12
    call    DeleteObject

    ; 3. 畫恐龍
    cmp     [hBitmapDino], 0
    je      DrawObs

    mov     rcx, rbx
    call    CreateCompatibleDC
    mov     r13, rax
    mov     rcx, r13
    mov     rdx, [hBitmapDino]
    call    SelectObject

    ; BitBlt 恐龍
    mov     qword ptr [rsp+64], SRCCOPY
    mov     qword ptr [rsp+56], 0
    mov     qword ptr [rsp+48], 0
    mov     qword ptr [rsp+40], r13
    mov     qword ptr [rsp+32], 40  ; 假設高 40
    mov     r9d, 40                 ; 假設寬 40
    mov     r8d, [PlayerY]          ; Y 座標
    mov     edx, [PlayerX]          ; X 座標
    mov     rcx, rbx
    call    BitBlt

    mov     rcx, r13
    call    DeleteDC

DrawObs:
    ; 4. 畫障礙物
    cmp     [hBitmapObs], 0
    je      EndPaintJob

    ; 準備 DC
    mov     rcx, rbx
    call    CreateCompatibleDC
    mov     r13, rax
    mov     rcx, r13
    mov     rdx, [hBitmapObs]
    call    SelectObject

    ; 迴圈畫出所有有效障礙物
    mov     r15, 0
    lea     r14, Obstacles

ObsLoop:
    cmp     [r14].GameObject.active, 1
    jne     NextObsDraw

    mov     qword ptr [rsp+64], SRCCOPY
    mov     qword ptr [rsp+56], 0
    mov     qword ptr [rsp+48], 0
    mov     qword ptr [rsp+40], r13
    mov     eax, [r14].GameObject.h
    mov     [rsp+32], rax           ; Height
    mov     r9d, [r14].GameObject.w ; Width
    mov     r8d, [r14].GameObject.y ; Y
    mov     edx, [r14].GameObject.x ; X
    mov     rcx, rbx
    call    BitBlt

NextObsDraw:
    add     r14, SIZEOF GameObject
    inc     r15
    cmp     r15, MAX_OBSTACLES
    jl      ObsLoop

    mov     rcx, r13
    call    DeleteDC

EndPaintJob:
    mov     rcx, [rsp+80+32+8]
    lea     rdx, ps
    call    EndPaint
    mov     rax, 0
    jmp     FinishWndProc

HandleDestroy:
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
    sub     rsp, 56
    
    ; 載入恐龍 (紅)
    mov     rcx, 0
    lea     rdx, DinoImg
    mov     r8, IMAGE_BITMAP
    mov     r9, 0
    mov     qword ptr [rsp+32], 0
    mov     qword ptr [rsp+40], 10h
    call    LoadImageW
    mov     [hBitmapDino], rax

    ; 載入障礙物 (藍)
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
END