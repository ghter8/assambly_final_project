; file: src/common.inc
; 共用結構定義

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
; 輸入模組宣告
; 邏輯：如果 "不是" Input 模組在讀我，我就告訴他這些是 EXTERN
; ==========================================
IFNDEF IS_INPUT_MODULE
    EXTERN UpdateInput: PROC
    EXTERN Key_Up:      BYTE
    EXTERN Key_Down:    BYTE
    EXTERN Key_Left:    BYTE
    EXTERN Key_Right:   BYTE
    EXTERN Key_Z:       BYTE
    EXTERN Key_Escape:  BYTE
ENDIF

IFNDEF IS_WINDOW_MODULE
    EXTERN InitWindow:  PROC
ENDIF

IFNDEF IS_GAME_MODULE
    EXTERN Movement:    PROC
    EXTERN PlayerX:     SDWORD
    EXTERN PlayerY:     SDWORD
ENDIF

; ==========================================
; 5. 特效物件系統 (Object System)
; ==========================================

; 物件狀態常數
OBJ_DEAD        EQU 0   ; 死亡 (可以被新的覆蓋)
OBJ_FADE_IN     EQU 1   ; 淡入中
OBJ_ACTIVE      EQU 2   ; 顯示中 (倒數計時)
OBJ_FADE_OUT    EQU 3   ; 淡出中

; 物件資料結構
GameObject STRUCT
    state       DWORD   0   ; 當前狀態
    x           SDWORD  0   ; X 座標
    y           SDWORD  0   ; Y 座標
    dirX        SDWORD  0   ; X 速度
    dirY        SDWORD  0   ; Y 速度
    alpha       DWORD   0   ; 透明度 (0~255)
    lifeTime    DWORD   0   ; 停留時間計數器
GameObject ENDS

; 最大同時存在物件數 (可自行調整)
MAX_OBJECTS     EQU 100

IFNDEF IS_GAME_MODULE
    EXTERN ObjectPool: GameObject
    EXTERN SpawnObject: PROC
    EXTERN UpdateObjects: PROC
ENDIF