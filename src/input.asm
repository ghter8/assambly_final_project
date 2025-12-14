; file: src/input.asm
; 輸入系統 (使用 GetAsyncKeyState 進行輪詢)

; 【新增】定義一個旗標，告訴 common.inc 不要宣告 input 的 EXTERN
IS_INPUT_MODULE EQU 1

INCLUDE common.inc

; --- 引入 Windows API ---
EXTERN GetAsyncKeyState: PROC

; --- 公開變數與函式 ---
PUBLIC UpdateInput
PUBLIC Key_Up, Key_Down, Key_Left, Key_Right, Key_Z

.data
    ; 定義 5 個按鍵的狀態 (0 = 放開, 1 = 按下)
    Key_Up      BYTE    0
    Key_Down    BYTE    0
    Key_Left    BYTE    0
    Key_Right   BYTE    0
    Key_Z       BYTE    0

.code

; ==========================================================
; UpdateInput: 檢查按鍵狀態並寫入變數
; 建議在 main 的訊息迴圈中呼叫
; ==========================================================
UpdateInput PROC
    sub     rsp, 40         ; Shadow Space

    ; --- 1. 檢查 UP (VK_UP = 0x26) ---
    mov     rcx, 26h
    call    GetAsyncKeyState
    ; GetAsyncKeyState 回傳 SHORT (AX)。若最高位元 (Bit 15) 為 1，表示按下。
    test    ax, 8000h
    setnz   [Key_Up]        ; 若非零 (按下)，將 Key_Up 設為 1，否則設為 0

    ; --- 2. 檢查 DOWN (VK_DOWN = 0x28) ---
    mov     rcx, 28h
    call    GetAsyncKeyState
    test    ax, 8000h
    setnz   [Key_Down]

    ; --- 3. 檢查 LEFT (VK_LEFT = 0x25) ---
    mov     rcx, 25h
    call    GetAsyncKeyState
    test    ax, 8000h
    setnz   [Key_Left]

    ; --- 4. 檢查 RIGHT (VK_RIGHT = 0x27) ---
    mov     rcx, 27h
    call    GetAsyncKeyState
    test    ax, 8000h
    setnz   [Key_Right]

    ; --- 5. 檢查 Z (VK_Z = 0x5A) ---
    mov     rcx, 5Ah
    call    GetAsyncKeyState
    test    ax, 8000h
    setnz   [Key_Z]

    add     rsp, 40
    ret
UpdateInput ENDP

END