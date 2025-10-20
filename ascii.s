 #使用的指令：gcc -S -masm=intel -fverbose-asm ascii.c -o ascii.s
 #验证指令：gcc -c ascii.s -o ascii.o

.file	"ascii.c"                    # 源文件名：ascii.c
	.intel_syntax noprefix           # 使用Intel语法，无前缀
	.text                            # 代码段开始
	.globl	main                     # 声明main为全局符号
	.def	main;	.scl	2;	.type	32;	.endef  # 定义main函数信息
	.seh_proc	main                 # SEH（结构化异常处理）过程开始
									 # 以上是编译器提示，并非程序代码，为了阅读方便，主程序中的编译器提示已删除

main:
	push	rbp	                     # 保存旧的基址指针
	mov	rbp, rsp	                 # 建立新的栈帧指针
	sub	rsp, 48	                     # 在栈上分配48字节空间
  								 	 # ascii.c:2: int main()
	call	__main	                 # 调用GCC的初始化例程
  								 	 # ascii.c:3:     for (char i = 'a'; i <= 'z'; i++)
	mov	BYTE PTR -1[rbp], 97	     # 将字符'a'（ASCII 97）存入局部变量i
  								 	 # ascii.c:3:     for (char i = 'a'; i <= 'z'; i++)
	jmp	.L2	                     	 # 无条件跳转到循环条件检查标签.L2
.L5:
 								 	 # ascii.c:4:         printf("%c", i);
	movsx	eax, BYTE PTR -1[rbp]	 # 将字符i符号扩展为32位存入eax
	mov	ecx, eax	                 # 将字符值作为参数传入ecx（调用约定）
	call	putchar	                 # 调用putchar打印字符
 									 # ascii.c:5:         if (i == 'a' + 12)
	cmp	BYTE PTR -1[rbp], 109	     # 比较i是否等于'm'（'a'+12=109）
	jne	.L3	                     	 # 如果不等于'm'，跳转到.L3
  								 	 # ascii.c:6:             printf("\n");
	mov	ecx, 10	                     # 将换行符'\n'（ASCII 10）传入ecx
	call	putchar	                 # 调用putchar打印换行符
	jmp	.L4	                     	 # 无条件跳转到.L4（跳过空格打印）
.L3:
 								 	 # ascii.c:9:    printf(" ");
	mov	ecx, 32	                     # 将空格字符' '（ASCII 32）传入ecx
	call	putchar	                 # 调用putchar打印空格
.L4:
 								 	 # ascii.c:3:     for (char i = 'a'; i <= 'z'; i++)
	movzx	eax, BYTE PTR -1[rbp]	 # 将i零扩展为32位（虽然这里用movsx可能更一致）
	add	eax, 1	                     # i值加1
	mov	BYTE PTR -1[rbp], al	     # 将新值存回i
.L2:
 								 	 # ascii.c:3:     for (char i = 'a'; i <= 'z'; i++)
	cmp	BYTE PTR -1[rbp], 122	     # 比较i是否小于等于'z'（ASCII 122）
	jle	.L5	                     	 # 如果i <= 'z'，继续循环
 								 	 # ascii.c:12:     return 0;
	mov	eax, 0	                     # 返回值0存入eax
	add	rsp, 48	                     # 释放栈空间
	pop	rbp	                         # 恢复旧的基址指针
	ret	                             # 从函数返回

									 # 以下是编译器提示，并非程序代码
	.seh_endproc                     # SEH过程结束
	.def	__main;	.scl	2;	.type	32;	.endef  # 定义__main函数信息
	.ident	"GCC: (Rev2, Built by MSYS2 project) 14.2.0"  # 编译器标识
	.def	putchar;	.scl	2;	.type	32;	.endef  # 定义putchar函数信息
	