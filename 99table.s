.LC0:
	.ascii "ThE 9mul9 table:\0"
.LC1:
	.ascii "%d*%d=%-2d \0"
main:
	call	__main			# 调用初始化函数
	lea	rax, .LC0[rip]		# 加载字符串 .LC0 的地址到 rax
	mov	rcx, rax		# 将地址移动到 rcx (puts 的第一个参数)
	call	puts			# 调用 puts 函数打印标题
	mov	DWORD PTR -4[rbp], 1	# 初始化外层循环变量 i = 1 (存储在栈上 rbp-4)
	jmp	.L2			# 跳转到外层循环条件检查
.L5:
	mov	DWORD PTR -8[rbp], 1	# 初始化内层循环变量 j = 1 (存储在栈上 rbp-8)
	jmp	.L3			# 跳转到内层循环条件检查
.L4:
	mov	eax, DWORD PTR -4[rbp]	# 将 i 加载到 eax
	imul	eax, DWORD PTR -8[rbp]	# eax = i * j
	mov	ecx, eax		# 将乘积保存到 ecx
	mov	edx, DWORD PTR -4[rbp]	# 将 i 加载到 edx
	mov	eax, DWORD PTR -8[rbp]	# 将 j 加载到 eax
	mov	r9d, ecx		# 第4个参数: 乘积 (i*j)
	mov	r8d, edx		# 第3个参数: i
	mov	edx, eax		# 第2个参数: j
	lea	rax, .LC1[rip]		# 加载格式字符串 .LC1 的地址
	mov	rcx, rax		# 第1个参数: 格式字符串地址
	call	printf			# 调用 printf 打印 "j*i=product "
	add	DWORD PTR -8[rbp], 1	# j++
.L3:
	mov	eax, DWORD PTR -8[rbp]	# 将 j 加载到 eax
	cmp	eax, DWORD PTR -4[rbp]	# 比较 j 和 i
	jle	.L4			# 如果 j <= i，跳转到 .L4 继续循环
	mov	ecx, 10			# 将换行符 (ASCII 10) 放入 ecx
	call	putchar			# 调用 putchar 打印换行
	add	DWORD PTR -4[rbp], 1	# i++
.L2:
	cmp	DWORD PTR -4[rbp], 9	# 比较 i 和 9
	jle	.L5			# 如果 i <= 9，跳转到 .L5 继续循环
	mov	eax, 0			# 设置返回值为 0
	ret				# 返回	
