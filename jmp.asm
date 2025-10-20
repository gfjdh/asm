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
	; 使用更稳健的循环：
	; CX = 剩余要打印的字母数 (26)
	; BH = 每行剩余计数 (初始 13)
	MOV CX,26
	MOV BH,13
	MOV AL,'a'

print_letter:
	; 输出当前字母
	MOV DL,AL
	MOV AH,02h
	INT 21h

	; 处理分隔/换行
	DEC BH
	CMP BH,0
	JNE do_space
	; BH == 0: 行已满，输出 CRLF
	MOV AH,09h
	MOV DX,OFFSET CRLF
	INT 21h
	MOV BH,13
	JMP after_sep

do_space:
	MOV DL,' '
	MOV AH,02h
	INT 21h

after_sep:
	INC AL
	DEC CX
	JNZ print_letter	; 如果还有字母，继续

	; 循环结束后，如果最后一行未满（BH != 13）则输出换行
	CMP BH,13
	JE finish
	MOV AH,09h
	MOV DX,OFFSET CRLF
	INT 21h

finish:
	MOV AX,4C00H			; 设置程序正常结束功能号(4CH)和返回码(00H)
	INT 21H				; 调用DOS中断21H，结束程序并返回到DOS
MAIN ENDP				; 主程序结束
CODESEG ENDS			; 代码段结束
		END MAIN			; 程序结束，指定程序入口点为MAIN