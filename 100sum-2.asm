; 100sum-2.asm - 读取一个整数 n (1..100)，将 1..n 的求和结果存入数据段变量 SUM，并打印
; 与 100sum-1.asm 区别：不只保存在寄存器里，最终数字写入数据段中的 SUM 变量

DATA SEGMENT
	NOTICE   DB 'please input a number(1~100)$'
	IN_BUF   DB 4,0,4 DUP(0)            ; DOS 0Ah 输入缓冲：最大长度, 实际长度, 数据...
	STR_BUF  DB 5 DUP(0)                ; 结果字符串缓冲(最多 '5050' + '$')
	CRLF     DB 0Dh,0Ah,'$'
	N        DW 0                       ; 输入的数字 n
	SUM      DW 0                       ; 求和结果 sum = 1 + 2 + ... + n
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA
START:
	MOV AX, DATA
	MOV DS, AX

	; 输出提示
	LEA DX, NOTICE
	MOV AH, 09h
	INT 21h

	; 读取输入字符串
	LEA DX, IN_BUF
	MOV AH, 0Ah
	INT 21h

	; 将输入 ASCII 转换为数字 -> AX
	LEA SI, IN_BUF+2
	MOV CL, IN_BUF+1
	CALL STR_TO_NUM
	MOV N, AX                ; 保存输入 n 到数据段变量 N

	; 计算 1..n 的和，结果保存在 SUM
	MOV AX, N                ; AX = n
	MOV CX, AX               ; 使用 CX 作为递减计数器
	MOV BX, 0                ; BX 累加器
SUM_LOOP:
	ADD BX, CX               ; BX += CX
	LOOP SUM_LOOP            ; CX--, 直到 0 结束
	MOV SUM, BX              ; 保存结果到数据段变量 SUM

	; 换行
	LEA DX, CRLF
	MOV AH, 09h
	INT 21h

	; 把数据段里的 SUM 转为字符串
	MOV BX, SUM              ; NUM_TO_STR 约定：BX=数字
	LEA DI, STR_BUF
	CALL NUM_TO_STR

	; 输出结果字符串
	LEA DX, STR_BUF
	MOV AH, 09h
	INT 21h

	; 结束程序
	MOV AH, 4Ch
	INT 21h

; ---------------- 子程序：字符串转数字 ----------------
; 输入：SI=数字字符串首地址  CL=位数
; 输出：AX=数字
STR_TO_NUM PROC
	PUSH BX
	PUSH CX
	PUSH DX
	PUSH SI

	MOV AX, 0
	MOV CH, 0              ; 使用 CX 的低8位 CL 做循环计数
STR_NEXT:
	MOV BL, [SI]
	SUB BL, '0'
	MOV BH, 0
	MOV DX, 10
	MUL DX                 ; DX:AX = AX * 10，此处 AX < 6553 保证不溢出 (n 最大 100)
	ADD AX, BX
	INC SI
	LOOP STR_NEXT

	POP SI
	POP DX
	POP CX
	POP BX
	RET
STR_TO_NUM ENDP

; ---------------- 子程序：数字转字符串 ----------------
; 输入：BX=数字  DI=目标缓冲区地址
; 输出：以 '$' 结尾的 ASCII 数字串
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
	JNE NT_ZERO
	MOV BYTE PTR [DI], '0'
	INC DI
	JMP NT_END
NT_ZERO:
NT_DIV_LOOP:
	MOV DX, 0
	DIV BX              ; AX=商 DX=余
	ADD DL, '0'
	PUSH DX             ; 逆序入栈
	INC SI
	CMP AX, 0
	JNE NT_DIV_LOOP
NT_POP_LOOP:
	POP DX
	MOV [DI], DL
	INC DI
	DEC SI
	JNZ NT_POP_LOOP
NT_END:
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
