STKSEG SEGMENT STACK            ; 堆栈段
    DW 32 DUP(0)
STKSEG ENDS

DATASEG SEGMENT                 ; 数据段
    MSG_TITLE  DB "ThE 9mul9 table:",0DH,0AH,'$'
    SPACE      DB ' ','$'
    STAR       DB '*','$'
    EQUAL      DB '=','$'
    NEWLINE    DB 0DH,0AH,'$'
DATASEG ENDS

CODESEG SEGMENT
    ASSUME CS:CODESEG, DS:DATASEG, SS:STKSEG

; ----------------------------
; 基础输出过程
; ----------------------------
PRINT_STRING PROC NEAR          ; DX->'$' 结尾字符串
    MOV AH,09H
    INT 21H
    RET
PRINT_STRING ENDP

PRINT_CHAR PROC NEAR            ; DL = 字符
    MOV AH,02H
    INT 21H
    RET
PRINT_CHAR ENDP

PRINT_NEWLINE PROC NEAR
    PUSH DX
    MOV DX,OFFSET NEWLINE
    CALL PRINT_STRING
    POP DX
    RET
PRINT_NEWLINE ENDP

; 打印 0..9 的一位十进制数 (AL)
PRINT_DIGIT PROC NEAR
    PUSH AX
    PUSH DX
    AND AL,0FH
    ADD AL,'0'
    MOV DL,AL
    CALL PRINT_CHAR
    POP DX
    POP AX
    RET
PRINT_DIGIT ENDP

; 打印 0..99 的十进制 (AX)
PRINT_2D PROC NEAR
; 入参: AX=值(0..99)
; 可能输出 1 或 2 位
    PUSH AX
    PUSH DX
    CMP AX,10
    JB P2D_ONES            ; <10 只输出个位

    MOV DL,AL
    MOV AH,0
    MOV BL,10
    DIV BL                 ; AL=商(十位) AH=余(个位)
    PUSH AX                ; [AH=个位, AL=十位]
    MOV AL,AL              ; 十位
    CALL PRINT_DIGIT
    POP AX
    MOV AL,AH              ; 个位
    CALL PRINT_DIGIT
    JMP SHORT P2D_END

P2D_ONES:
    ; AX < 10, AL 即为个位
    CALL PRINT_DIGIT

P2D_END:
    POP DX
    POP AX
    RET
PRINT_2D ENDP

; 计算乘法 i*j (入参: AL=i, BL=j, 出参: AX = i*j)
MUL_AB PROC NEAR
    PUSH BX
    PUSH DX
    MOV AH,0
    MUL BL                 ; AL*BL -> AX
    POP DX
    POP BX
    RET
MUL_AB ENDP

; 打印 "a*b=c "
PRINT_ITEM PROC NEAR
; 入参: AL=a, BL=b
; 改变: AX,BX,DX
    PUSH AX
    PUSH BX
    PUSH DX

    ; 打印 a
    MOV AH,0
    CALL PRINT_2D
    ; 打印 '*'
    MOV DL,'*'
    CALL PRINT_CHAR

    ; 打印 b
    MOV AL,BL
    MOV AH,0
    CALL PRINT_2D

    ; 打印 '='
    MOV DL,'='
    CALL PRINT_CHAR

    ; 恢复寄存器以进行计算
    POP DX
    POP BX
    POP AX

    ; 重新用 AL,BL 计算 a*b
    CALL MUL_AB            ; AX = a*b
    CALL PRINT_2D

    ; 打印空格
    MOV DL,' '
    CALL PRINT_CHAR

    RET
PRINT_ITEM ENDP

; ----------------------------
; 打印九九乘法表，从 9 到 1
; ----------------------------
PRINT_TABLE PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX

    MOV AL,9               ; 外层: 被乘数 9..1
OUTER_LOOP:
    CMP AL,0
    JE PT_END

    MOV BL,1               ; 内层: 乘数 1..AL
INNER_LOOP:
    CMP BL,AL
    JA  ROW_END

    PUSH AX
    PUSH BX
    CALL PRINT_ITEM        ; a=AL, b=BL
    POP BX
    POP AX

    INC BL
    JMP INNER_LOOP

ROW_END:
    CALL PRINT_NEWLINE
    DEC AL
    JMP OUTER_LOOP

PT_END:
    POP CX
    POP BX
    POP AX
    RET
PRINT_TABLE ENDP

; ----------------------------
; 主程序
; ----------------------------
MAIN PROC FAR
    MOV AX,DATASEG
    MOV DS,AX
    MOV AX,STKSEG
    MOV SS,AX
    MOV SP,64

    ; 标题
    MOV DX,OFFSET MSG_TITLE
    CALL PRINT_STRING

    ; 打印九九表
    CALL PRINT_TABLE

    MOV AX,4C00H
    INT 21H
MAIN ENDP

CODESEG ENDS
    END MAIN
