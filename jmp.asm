STKSEG SEGMENT STACK		; 定义堆栈段，用于程序运行时的堆栈空间
	DW 32 DUP(0)			; 分配32个字(64字节)的堆栈空间，初始化为0
STKSEG ENDS					; 堆栈段结束

; 定义数据段，用于存储程序的数据
DATASEG SEGMENT
	CRLF DB 13,10,'$'	        ; 不使用单一 MSG 字符串，用按字符输出
DATASEG ENDS					; 数据段结束

; 定义代码段，包含程序的执行代码
CODESEG SEGMENT
	ASSUME CS:CODESEG,DS:DATASEG	; 告诉汇编器CS指向代码段，DS指向数据段
MAIN PROC FAR			; 定义主程序，FAR表示远过程调用
	MOV AX,DATASEG			; 将数据段的段地址加载到AX寄存器
	MOV DS,AX			; 将AX的值赋给DS寄存器，设置数据段寄存器

	; BL 用作当前行字符计数 (0..12)
	MOV BL,0
	; AL 保存当前字符，初始为 'a'
	MOV AL,'a'

print_loop:
	; 打印当前字符 (INT 21h AH=02h, DL=char)
	MOV DL,AL
	MOV AH,02h
	INT 21h

	; 增加本行计数
	INC BL
	CMP BL,13
	JNE not_line_end
	; 行满，输出 CRLF（使用功能9输出以 $ 结束的字符串）
	MOV AH,09h
	MOV DX,OFFSET CRLF
	INT 21h
	MOV BL,0
	JMP next_char

not_line_end:
	; 输出空格作为分隔
	MOV DL,' '
	MOV AH,02h
	INT 21h

next_char:
	INC AL
	; 如果超过 'z' 则结束
	CMP AL,'z'
	JG done_printing
	JMP print_loop

done_printing:
	; 如果最后一行未满，则输出回车换行
	CMP BL,0
	JE skip_crlf
	MOV AH,09h
	MOV DX,OFFSET CRLF
	INT 21h
skip_crlf:
	MOV AX,4C00H			; 设置程序正常结束功能号(4CH)和返回码(00H)
	INT 21H				; 调用DOS中断21H，结束程序并返回到DOS
MAIN ENDP				; 主程序结束
CODESEG ENDS			; 代码段结束
	END MAIN			; 程序结束，指定程序入口点为MAIN