; 100sum-3.asm - 读取整数 n (1..100)，计算 1..n 之和，将结果压栈保存，再从栈取出打印
; 使用栈保存中间结果（求和后留下一个栈单元），随后弹出用于转换输出

DATA SEGMENT
	NOTICE   DB 'please input a number(1~100)$'
	IN_BUF   DB 4,0,4 DUP(0)
	STR_BUF  DB 6 DUP(0)            ; 结果最多 5050 ('$' 结束) 需要 5 + 1
	CRLF     DB 0Dh,0Ah,'$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA
START:
	MOV AX, DATA
	MOV DS, AX

	; 提示输入
	LEA DX, NOTICE
	MOV AH, 09h
	INT 21h

	; 输入字符串
	LEA DX, IN_BUF
	MOV AH, 0Ah
	INT 21h

	; 转换为数字 AX
	LEA SI, IN_BUF+2
	MOV CL, IN_BUF+1
	CALL STR_TO_NUM
	; AX = n

	; 求和，结果放入 BX
	MOV CX, AX          ; CX = n (循环计数)
	MOV BX, 0
SUM_LOOP:
	ADD BX, CX
	LOOP SUM_LOOP       ; 直到 CX=0

	; 将结果 BX 压栈
	PUSH BX             ; [SP] = sum

	; 输出换行
	LEA DX, CRLF
	MOV AH, 09h
	INT 21h

	; 从栈中取出结果 -> BX
	POP BX              ; 恢复 sum 到 BX 供转换

	; 数字转字符串
	LEA DI, STR_BUF
	CALL NUM_TO_STR

	; 输出结果
	LEA DX, STR_BUF
	MOV AH, 09h
	INT 21h

	; 正常结束
	MOV AH, 4Ch
	INT 21h

; ---------------- 字符串转数字 ----------------
STR_TO_NUM PROC
	PUSH BX
	PUSH CX
	PUSH DX
	PUSH SI

	MOV AX, 0
	MOV CH, 0
STN_NEXT:
	MOV BL, [SI]
	SUB BL, '0'
	MOV BH, 0
	MOV DX, 10
	MUL DX
	ADD AX, BX
	INC SI
	LOOP STN_NEXT

	POP SI
	POP DX
	POP CX
	POP BX
	RET
STR_TO_NUM ENDP

; ---------------- 数字转字符串 ----------------
NUM_TO_STR PROC
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	PUSH SI

	MOV SI, 0
	MOV AX, BX
	MOV BX, 10
	CMP AX, 0
	JNE NTS_NOT_ZERO
	MOV BYTE PTR [DI], '0'
	INC DI
	JMP NTS_DONE_DIGITS
NTS_NOT_ZERO:
NTS_DIV_LOOP:
	MOV DX, 0
	DIV BX
	ADD DL, '0'
	PUSH DX
	INC SI
	CMP AX, 0
	JNE NTS_DIV_LOOP
NTS_POP_LOOP:
	POP DX
	MOV [DI], DL
	INC DI
	DEC SI
	JNZ NTS_POP_LOOP
NTS_DONE_DIGITS:
	MOV BYTE PTR [DI], '$'

	POP SI
	POP DX
	POP CX
	POP BX
	POP AX
	RET
NUM_TO_STR ENDP

CODE ENDS
END START
