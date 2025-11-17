STKSEG SEGMENT STACK            ; 定义堆栈段
    DW 32 DUP(0)                ; 分配堆栈空间
STKSEG ENDS                     ; 堆栈段结束

DATASEG SEGMENT                 ; 定义数据段
    TABLE DW 7, 2,  3,  4,  5,  6,  7,  8,  9      ; 定义9x9乘法表数据（字类型）
          DW 2, 4,  7,  8,  10, 12, 14, 16, 18
          DW 3, 6,  9,  12, 15, 18, 21, 24, 27
          DW 4, 8,  12, 16, 7,  24, 28, 32, 36
          DW 5, 10, 15, 20, 25, 30, 35, 40, 45
          DW 6, 12, 18, 24, 30, 7,  42, 48, 54
          DW 7, 14, 21, 28, 35, 42, 49, 56, 63
          DW 8, 16, 24, 32, 40, 48, 56, 7,  72
          DW 9, 18, 27, 36, 45, 54, 63, 72, 81
    MSG1 DB "x y$"              ; 定义字符串"x y"
    MSG2 DB "  error$"          ; 定义字符串"  error"
    MSG3 DB "accomplish!$"      ; 定义字符串"accomplish!"
    NEWLINE DB 0DH, 0AH, '$'    ; 定义回车换行字符串
DATASEG ENDS                    ; 数据段结束

CODESEG SEGMENT             ; 定义代码段
    ASSUME CS:CODESEG, DS:DATASEG, SS:STKSEG ; 设置段寄存器关联

; ----------------------------
; 基础输出过程
; ----------------------------
PRINT_STRING PROC NEAR
; 入参: DX = 指向以'$'结尾的字符串
    MOV AH, 09H
    INT 21H
    RET
PRINT_STRING ENDP

PRINT_CHAR PROC NEAR
; 入参: DL = 字符
    MOV AH, 02H
    INT 21H
    RET
PRINT_CHAR ENDP

PRINT_NEWLINE PROC NEAR
; 打印 CRLF
    PUSH DX
    MOV DX, OFFSET NEWLINE
    CALL PRINT_STRING
    POP DX
    RET
PRINT_NEWLINE ENDP

PRINT_DIGIT PROC NEAR
; 入参: AL = 0..9 的数字，打印为字符
    PUSH AX
    PUSH DX
    ADD AL, '0'
    MOV DL, AL
    CALL PRINT_CHAR
    POP DX
    POP AX
    RET
PRINT_DIGIT ENDP

; ----------------------------
; 计算与数据读取过程
; ----------------------------
CALC_EXPECTED PROC NEAR
; 入参: SI=i, DI=j
; 出参: CX = (i+1)*(j+1)
; 改变: AX, BX, CX
    PUSH AX
    PUSH BX
    MOV AX, SI       ; AX = i
    INC AX           ; AX = i+1 (AL 有效)
    MOV BX, DI       ; BX = j
    INC BX           ; BX = j+1 (BL 有效)
    MUL BL           ; AL * BL -> AX = (i+1)*(j+1)
    MOV CX, AX       ; 期望值
    POP BX
    POP AX
    RET
CALC_EXPECTED ENDP

GET_ACTUAL PROC NEAR
; 入参: SI=i, DI=j
; 出参: DX = TABLE[(i*9 + j)]
; 改变: AX, BX, DX
    PUSH AX
    PUSH BX
    MOV AX, SI       ; AX = i
    MOV BX, 9
    MUL BX           ; DX:AX = AX * BX (此处使用 16位乘，但 i<9，DX=0，AX=i*9)
    ADD AX, DI       ; AX = i*9 + j
    SHL AX, 1        ; 每项是字，偏移*2
    MOV BX, AX
    MOV DX, TABLE[BX]
    POP BX
    POP AX
    RET
GET_ACTUAL ENDP

; ----------------------------
; 输出错误信息过程
; ----------------------------
PRINT_ERROR PROC NEAR
; 入参: SI=i, DI=j
; 功能: 打印 "(i+1) (j+1)  error" 并换行
    PUSH AX
    PUSH DX
    ; 打印行号 i+1
    MOV AX, SI
    INC AX
    CALL PRINT_DIGIT
    ; 空格
    MOV DL, ' '
    CALL PRINT_CHAR
    ; 打印列号 j+1
    MOV AX, DI
    INC AX
    CALL PRINT_DIGIT
    ; 打印"  error"
    MOV DX, OFFSET MSG2
    CALL PRINT_STRING
    ; 换行
    CALL PRINT_NEWLINE
    POP DX
    POP AX
    RET
PRINT_ERROR ENDP

; ----------------------------
; 主检查循环过程
; ----------------------------
CHECK_TABLE PROC NEAR
; 遍历 9x9，比较期望值与实际表值，若不等则打印错误
    PUSH SI
    PUSH DI
    MOV SI, 0
OUTER_LOOP:
    CMP SI, 9
    JGE CT_END
    MOV DI, 0
INNER_LOOP:
    CMP DI, 9
    JGE CT_NEXT_ROW

    CALL CALC_EXPECTED  ; 出: CX
    CALL GET_ACTUAL     ; 出: DX
    CMP CX, DX
    JE CT_SKIP_ERR
    CALL PRINT_ERROR
CT_SKIP_ERR:
    INC DI
    JMP INNER_LOOP

CT_NEXT_ROW:
    INC SI
    JMP OUTER_LOOP

CT_END:
    POP DI
    POP SI
    RET
CHECK_TABLE ENDP

; ----------------------------
; 程序入口（远过程）
; ----------------------------
MAIN PROC FAR               ; 主程序（远过程）
    MOV AX, DATASEG         ; 设置 DS
    MOV DS, AX
    ; 初始化堆栈段和栈指针（使用 CALL/RET 必须保证栈可用）
    MOV AX, STKSEG
    MOV SS, AX
    MOV SP, 64              ; 32 个字 = 64 字节

    ; 打印标题并换行
    MOV DX, OFFSET MSG1
    CALL PRINT_STRING
    CALL PRINT_NEWLINE

    ; 执行检查
    CALL CHECK_TABLE

    ; 收尾输出
    MOV DX, OFFSET MSG3
    CALL PRINT_STRING
    CALL PRINT_NEWLINE

    ; 退出到 DOS
    MOV AX, 4C00H
    INT 21H
MAIN ENDP                   ; 主程序结束
CODESEG ENDS                ; 代码段结束
    END MAIN                ; 程序入口点