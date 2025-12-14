	.intel_syntax noprefix      # 使用 Intel 格式的汇编语法，不使用寄存器前缀 (%)
	.text                       # 代码段开始

	# 只读数据段，包含程序中使用的字符串常量
	.section .rdata,"dr"
.LC0:
	.ascii "[System] getvect(%d) called (Simulated)\12\0"
	
	.text
	.globl	getvect             # 导出 getvect 函数符号
getvect:
	push	rbp                 # 保存调用者的栈底指针
	mov	rbp, rsp            # 设置当前函数的栈底指针
	sub	rsp, 32             # 分配 32 字节的栈空间 (Shadow Space，Windows x64 调用约定)
	
	mov	DWORD PTR 16[rbp], ecx  # 将第一个参数 (中断号) 保存到栈中 (Shadow Space 区域)
	mov	eax, DWORD PTR 16[rbp]  # 将中断号加载到 eax
	mov	edx, eax                # 将中断号作为 printf 的第二个参数 (rdx/edx)
	lea	rax, .LC0[rip]          # 加载格式化字符串 .LC0 的地址
	mov	rcx, rax                # 将字符串地址作为 printf 的第一个参数 (rcx)
	call	printf                  # 调用 C 库函数 printf
	
	mov	eax, 0                  # 设置返回值为 0
	add	rsp, 32                 # 释放栈空间
	pop	rbp                     # 恢复调用者的栈底指针
	ret                         # 函数返回

	# 只读数据段，setvect 使用的字符串
	.section .rdata,"dr"
.LC1:
	.ascii "[System] setvect(%d, %p) called (Simulated)\12\0"
	
	.text
	.globl	setvect             # 导出 setvect 函数符号
setvect:
	push	rbp                 # 保存栈底指针
	mov	rbp, rsp            # 设置栈底指针
	sub	rsp, 32             # 分配栈空间
	
	mov	DWORD PTR 16[rbp], ecx  # 保存第一个参数 (中断号)
	mov	QWORD PTR 24[rbp], rdx  # 保存第二个参数 (中断处理函数指针)
	
	mov	rdx, QWORD PTR 24[rbp]  # 准备 printf 参数3: 函数指针
	mov	eax, DWORD PTR 16[rbp]  # 加载中断号
	mov	r8, rdx                 # 将函数指针放入 r8 (printf 的第3个参数)
	mov	edx, eax                # 将中断号放入 rdx (printf 的第2个参数)
	lea	rax, .LC1[rip]          # 加载格式化字符串 .LC1
	mov	rcx, rax                # 将字符串放入 rcx (printf 的第1个参数)
	call	printf                  # 调用 printf
	
	nop                         # 空指令 (对齐或填充)
	add	rsp, 32                 # 释放栈空间
	pop	rbp                     # 恢复栈底指针
	ret                         # 返回

	# 全局变量定义
	.globl	overflow_flag       # 导出 overflow_flag 变量
	.bss                        # 未初始化数据段
	.align 4
overflow_flag:
	.space 4                    # 分配 4 字节空间

	# 只读数据段，中断处理函数使用的字符串
	.section .rdata,"dr"
.LC2:
	.ascii "\12[ISR] Overflow Interrupt (INT 4) triggered! (Simulated)\0"
	
	.text
	.globl	new_int4            # 导出 new_int4 函数 (新的中断处理程序)
new_int4:
	push	rbp                 # 保存栈底指针
	mov	rbp, rsp            # 设置栈底指针
	sub	rsp, 32             # 分配栈空间
	
	mov	DWORD PTR overflow_flag[rip], 1 # 将全局变量 overflow_flag 设置为 1
	lea	rax, .LC2[rip]                  # 加载提示字符串 .LC2
	mov	rcx, rax                        # 作为 puts 的参数
	call	puts                            # 调用 puts 输出信息
	
	nop
	add	rsp, 32                 # 释放栈空间
	pop	rbp                     # 恢复栈底指针
	ret                         # 返回

	# 主函数使用的字符串常量
	.section .rdata,"dr"
.LC3:
	.ascii "System: Preparing to rewrite INT 4 vector...\0"
.LC4:
	.ascii "Calculation: %d + %d\12\0"
.LC5:
	.ascii "Warning: 'INTO' instruction is NOT supported in 64-bit mode.\0"
.LC6:
	.ascii "Please compile with '-m32' flag to use INTO instruction.\0"
.LC7:
	.ascii "Main: Overflow detected and handled.\0"
.LC8:
	.ascii "Main: Incorrect Result: %d (due to overflow)\12\0"
.LC9:
	.ascii "Main: No overflow occurred (or signal not caught).\0"
.LC10:
	.ascii "Main: Result: %d\12\0"
	
	.text
	.globl	main                # 导出 main 函数
main:
	push	rbp                 # 保存栈底指针
	mov	rbp, rsp            # 设置栈底指针
	sub	rsp, 48             # 分配 48 字节栈空间 (局部变量 + Shadow Space)
	
	call	__main              # 调用 GCC 初始化函数 (如果有)
	
	# 初始化局部变量
	mov	WORD PTR -2[rbp], 32000 # 变量 a = 32000 (short 类型)
	mov	WORD PTR -4[rbp], 1000  # 变量 b = 1000 (short 类型)
	mov	WORD PTR -6[rbp], 0     # 变量 result = 0 (short 类型)
	
	# 打印准备重写中断向量的信息
	lea	rax, .LC3[rip]
	mov	rcx, rax
	call	puts
	
	# 获取旧的中断向量: getvect(4)
	mov	ecx, 4                  # 参数: 4
	call	getvect
	mov	QWORD PTR -16[rbp], rax # 保存返回值 (旧的中断处理函数指针) 到栈变量
	
	# 设置新的中断向量: setvect(4, new_int4)
	lea	rax, new_int4[rip]      # 获取 new_int4 函数的地址
	mov	rdx, rax                # 参数2: new_int4 地址
	mov	ecx, 4                  # 参数1: 4
	call	setvect
	
	# 打印计算公式: printf("Calculation: %d + %d\n", a, b)
	movsx	edx, WORD PTR -4[rbp] # 将 b (short) 符号扩展为 int，放入 edx
	movsx	eax, WORD PTR -2[rbp] # 将 a (short) 符号扩展为 int，放入 eax
	mov	r8d, edx                # printf 参数3: b
	mov	edx, eax                # printf 参数2: a
	lea	rax, .LC4[rip]          # printf 参数1: 格式串
	mov	rcx, rax
	call	printf
	
	# 打印关于 INTO 指令的警告 (64位模式不支持 INTO)
	lea	rax, .LC5[rip]
	mov	rcx, rax
	call	puts
	lea	rax, .LC6[rip]
	mov	rcx, rax
	call	puts
	
	# 执行加法运算: result = a + b
	movzx	edx, WORD PTR -2[rbp] # 零扩展加载 a
	movzx	eax, WORD PTR -4[rbp] # 零扩展加载 b
	add	eax, edx                  # 执行加法
	mov	WORD PTR -6[rbp], ax      # 将结果的低16位存入 result (发生截断)
	
	# 手动模拟溢出检测 (因为没有 INTO 指令)
	# 逻辑: 检查是否 (a>0 && b>0 && res<0) 或 (a<0 && b<0 && res>0)
	
	cmp	WORD PTR -2[rbp], 0     # 比较 a 和 0
	jle	.L6                     # 如果 a <= 0，跳转到 .L6 (检查负数溢出情况)
	cmp	WORD PTR -4[rbp], 0     # 比较 b 和 0
	jle	.L6                     # 如果 b <= 0，跳转到 .L6
	cmp	WORD PTR -6[rbp], 0     # 比较 result 和 0
	js	.L7                     # 如果 result < 0 (符号位为1)，说明正数加法溢出，跳转到 .L7
.L6:
	cmp	WORD PTR -2[rbp], 0     # 比较 a 和 0
	jns	.L8                     # 如果 a >= 0，跳转到 .L8 (不是负数溢出)
	cmp	WORD PTR -4[rbp], 0     # 比较 b 和 0
	jns	.L8                     # 如果 b >= 0，跳转到 .L8
	cmp	WORD PTR -6[rbp], 0     # 比较 result 和 0
	jle	.L8                     # 如果 result <= 0，跳转到 .L8 (结果正确，未溢出)
	# 如果 result > 0，说明负数加法溢出，继续执行到 .L7
.L7:
	# 溢出处理
	call	new_int4            # 调用新的中断处理函数 (模拟 INT 4)
.L8:
	# 检查溢出标志位
	mov	eax, DWORD PTR overflow_flag[rip] # 加载 overflow_flag
	test	eax, eax                # 测试 eax 是否为 0
	je	.L9                     # 如果为 0 (无溢出)，跳转到 .L9
	
	# 溢出发生时的输出
	lea	rax, .LC7[rip]          # "Overflow detected..."
	mov	rcx, rax
	call	puts
	movsx	eax, WORD PTR -6[rbp] # 符号扩展 result
	mov	edx, eax                # 参数2
	lea	rax, .LC8[rip]          # "Incorrect Result..."
	mov	rcx, rax
	call	printf
	jmp	.L10                    # 跳转到结束部分

.L9:
	# 无溢出时的输出
	lea	rax, .LC9[rip]          # "No overflow..."
	mov	rcx, rax
	call	puts
	movsx	eax, WORD PTR -6[rbp] # 符号扩展 result
	mov	edx, eax                # 参数2
	lea	rax, .LC10[rip]         # "Result..."
	mov	rcx, rax
	call	printf

.L10:
	# 恢复原来的中断向量: setvect(4, old_int4)
	mov	rax, QWORD PTR -16[rbp] # 从栈中取出保存的旧函数指针
	mov	rdx, rax                # 参数2
	mov	ecx, 4                  # 参数1
	call	setvect
	
	mov	eax, 0                  # main 函数返回 0
	add	rsp, 48                 # 释放栈空间
	pop	rbp                     # 恢复栈底指针
	ret                         # 返回
