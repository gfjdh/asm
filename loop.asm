STKSEG SEGMENT STACK	; 定义堆栈段
	DW 32 DUP(0)
STKSEG ENDS

DATASEG SEGMENT
	CRLF DB 13,10,'$'
	CUR DB 'a'
DATASEG ENDS

CODESEG SEGMENT
	ASSUME CS:CODESEG,DS:DATASEG
MAIN PROC FAR
	MOV AX,DATASEG
	MOV DS,AX

	; 外层循环：行数（2 行，每行 13 字母）
	MOV CX,2
outer_loop:
	; 保存外层 CX，因为内层也要使用 CX/LOOP
	PUSH CX

	; 内层循环：每行 13 个输出项
	MOV CX,13
inner_loop:
	; 输出当前字母
	MOV DL,[CUR]
	MOV AH,02h
	INT 21h

	; 如果这是本行的最后一个（CX==1），打印换行；否则打印空格
	CMP CX,1
	JE .print_crlf
	MOV DL,' '
	MOV AH,02h
	INT 21h
	JMP .after_sep
.print_crlf:
	MOV AH,09h
	MOV DX,OFFSET CRLF
	INT 21h
.after_sep:
	; 递增字符
	INC BYTE PTR [CUR]
	LOOP inner_loop

	; 恢复外层 CX 并由 LOOP 控制外层迭代
	POP CX
	LOOP outer_loop

	; 程序正常结束
	MOV AX,4C00H
	INT 21H
MAIN ENDP
CODESEG ENDS
	END MAIN

