STKSEG SEGMENT STACK		; 定义堆栈段，用于程序运行时的堆栈空间
	DW 32 DUP(0)			; 分配32个字(64字节)的堆栈空间，初始化为0
STKSEG ENDS					; 堆栈段结束

; 定义数据段，用于存储程序的数据
DATASEG SEGMENT
	MSG DB "Hello World$"		; 定义字符串"Hello World$"，$符号是DOS字符串结束标记
DATASEG ENDS					; 数据段结束

; 定义代码段，包含程序的执行代码
CODESEG SEGMENT
	ASSUME CS:CODESEG,DS:DATASEG	; 告诉汇编器CS指向代码段，DS指向数据段
MAIN PROC FAR				; 定义主程序，FAR表示远过程调用
	MOV AX,DATASEG			; 将数据段的段地址加载到AX寄存器
	MOV DS,AX			; 将AX的值赋给DS寄存器，设置数据段寄存器
	MOV AH,9			; 设置DOS功能号9(显示字符串)到AH寄存器
	MOV DX,OFFSET MSG		; 将字符串MSG的偏移地址加载到DX寄存器
	INT 21H				; 调用DOS中断21H，执行字符串显示功能
	MOV AX,4C00H			; 设置程序正常结束功能号(4CH)和返回码(00H)
	INT 21H				; 调用DOS中断21H，结束程序并返回到DOS
MAIN ENDP				; 主程序结束
CODESEG ENDS				; 代码段结束
	END MAIN			; 程序结束，指定程序入口点为MAIN