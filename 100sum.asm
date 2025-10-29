; 100sum.asm
STKSEG SEGMENT STACK
    DW 32 DUP(0)
STKSEG ENDS

DATASEG SEGMENT
    PROMPT DB 'Enter n (1-100):$'
    ERRMSG DB 'Input out of range (1-100).$'
    CRLF DB 13,10,'$'
    INBUF DB 6,?,6 DUP(0)    ; DOS buffered input: first byte = max, second = actual count, then chars
DATASEG ENDS

CODESEG SEGMENT
    ASSUME CS:CODESEG,DS:DATASEG
MAIN PROC FAR
    MOV AX,DATASEG
    MOV DS,AX

    ; 输出提示（字符串以 '$' 结束）
    MOV AH,09h
    MOV DX,OFFSET PROMPT
    INT 21h

    ; 设置输入缓冲区（DOS Buffered Input）
    MOV AH,0Ah
    MOV DX,OFFSET INBUF
    INT 21h

    ; INBUF+1 = 实际字符数 (不含回车)，INBUF+2.. = 字符
    ; 解析输入为整数
    LEA SI,INBUF
    MOV CL,[SI+1]     ; CL = count
    CMP CL,0
    JE bad_input
    XOR AX,AX         ; AX = accumulated value
    LEA DI,INBUF+2    ; DI 指向第一个字符
parse_loop:
    MOV DL,[DI]
    SUB DL,'0'
    CMP DL,9
    JA bad_input
    ; AX = AX * 10  (use 16x16 MUL to avoid improper operand types)
    MOV BX,10
    MUL BX            ; DX:AX = AX * BX
    ; result in AX (low word), DX may contain high word (but small here)
    ; add digit (DL)
    MOV BH,0
    MOV BL,DL
    ADD AX,BX
    INC DI
    DEC CL
    JNZ parse_loop
parse_done:
    ; 现在 AX 中为输入整数，但可能超过 16 位；限制 1..100
    CMP AX,1
    JB bad_input
    CMP AX,100
    JA bad_input

    ; 将 n 保存在 CX 做循环计数
    MOV CX,AX

    ; 计算 1+2+...+n = n*(n+1)/2
    ; 为确保结果放在寄存器中，使用 AX:DX 16x32 计算
    ; 计算 n*(n+1)
    MOV AX,CX         ; AX = n
    MOV BX,CX
    INC BX            ; BX = n+1
    ; 使用 16x16 -> 32 位乘法
    MUL BX            ; DX:AX = AX * BX
    ; 除以 2 -> 使用 DIV 得到 32 位除以 2 的商
    MOV BX,2
    DIV BX            ; AX = (n*(n+1))/2  （商在 AX，余数在 DX）

    ; 要求结果放在寄存器中：如果结果可以放入 AX，则将低字放入 AX，DX=0
    ; 100*(101)/2 = 5050 < 65536，所以结果小于 16 位，位于 AX
    ; 但我们 keep DX as high word just in case

    ; 输出换行
    MOV AH,09h
    MOV DX,OFFSET CRLF
    INT 21h

    ; 将 AX 中的数值转成 ASCII 并输出
    ; 如果 DX != 0, 仍只输出低 16 位（题目要求范围内）
    PUSH DX
    PUSH CX
    CALL print_decimal_ax
    POP CX
    POP DX

    ; 输出换行
    MOV AH,09h
    MOV DX,OFFSET CRLF
    INT 21h

    ; 退出
    MOV AX,4C00h
    INT 21h

bad_input:
    MOV AH,09h
    MOV DX,OFFSET ERRMSG
    INT 21h
    MOV AH,09h
    MOV DX,OFFSET CRLF
    INT 21h
    MOV AX,4C01h
    INT 21h

; --------------------
; 打印 AX 的无符号十进制数，使用堆栈/缓冲并调用 DOS 输出
; 约定：被调用时 AX = 值 (0..65535)，使用 DS 段，破坏 AX,BX,CX,DX
print_decimal_ax PROC
    ; 保存被调用者寄存器
    PUSH SI
    PUSH DI
    PUSH BX
    PUSH CX
    PUSH DX

    CMP AX,0
    JNE pda_nonzero
    MOV DL,'0'
    MOV AH,02h
    INT 21h
    JMP pda_done

pda_nonzero:
    LEA DI,INBUF+2    ; 使用 INBUF 后半保存数字字符（反序）
    MOV CX,0
pda_divloop:
    XOR DX,DX
    MOV BX,10
    DIV BX            ; DX:AX / 10 -> AX=quotient, DX=remainder
    MOV DL,DL         ; DL = low byte of remainder (DX)
    ADD DL,'0'
    MOV [DI],DL
    INC DI
    INC CX
    CMP AX,0
    JNE pda_divloop

    DEC DI
pda_outloop:
    MOV DL,[DI]
    MOV AH,02h
    INT 21h
    DEC DI
    DEC CX
    JNZ pda_outloop

pda_done:
    POP DX
    POP CX
    POP BX
    POP DI
    POP SI
    RET
print_decimal_ax ENDP

MAIN ENDP
CODESEG ENDS
    END MAIN
