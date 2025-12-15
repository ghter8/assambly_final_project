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
; 遊戲物件結構 (用於障礙物)
; ==========================================
GameObject STRUCT
    active      DWORD   0   ; 0=無效, 1=有效
    x           SDWORD  0   ; X 座標
    y           SDWORD  0   ; Y 座標 (通常固定在地板)
    w           DWORD   0   ; 寬度 (碰撞檢測用)
    h           DWORD   0   ; 高度
GameObject ENDS

MAX_OBSTACLES   EQU 5       ; 同時存在的最大障礙物數量

IFNDEF IS_INPUT_MODULE
    EXTERN UpdateInput: PROC
    EXTERN Key_Up:      BYTE
    EXTERN Key_Down:    BYTE
    EXTERN Key_Left:    BYTE
    EXTERN Key_Right:   BYTE
    EXTERN Key_Space:   BYTE ; [新增] 空白鍵
    EXTERN Key_Escape:  BYTE
ENDIF

IFNDEF IS_WINDOW_MODULE
    EXTERN InitWindow:  PROC
ENDIF

IFNDEF IS_GAME_MODULE
    EXTERN UpdateGame:  PROC
    EXTERN PlayerX:     SDWORD
    EXTERN PlayerY:     SDWORD
    EXTERN GameState:   DWORD
    EXTERN Score:       DWORD
    EXTERN Obstacles:   GameObject
    
    ; [新增] 恐龍動畫幀數 (0 或 1)
    EXTERN DinoFrame:   DWORD
ENDIF