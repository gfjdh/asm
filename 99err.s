TABLE:
	.word	7
	.word	2
	.word	3
	.word	4
	.word	5
	.word	6
	.word	7
	.word	8
	.word	9
	.word	2
	.word	4
	.word	7
	.word	8
	.word	10
	.word	12
	.word	14
	.word	16
	.word	18
	.word	3
	.word	6
	.word	9
	.word	12
	.word	15
	.word	18
	.word	21
	.word	24
	.word	27
	.word	4
	.word	8
	.word	12
	.word	16
	.word	7
	.word	24
	.word	28
	.word	32
	.word	36
	.word	5
	.word	10
	.word	15
	.word	20
	.word	25
	.word	30
	.word	35
	.word	40
	.word	45
	.word	6
	.word	12
	.word	18
	.word	24
	.word	30
	.word	7
	.word	42
	.word	48
	.word	54
	.word	7
	.word	14
	.word	21
	.word	28
	.word	35
	.word	42
	.word	49
	.word	56
	.word	63
	.word	8
	.word	16
	.word	24
	.word	32
	.word	40
	.word	48
	.word	56
	.word	7
	.word	72
	.word	9
	.word	18
	.word	27
	.word	36
	.word	45
	.word	54
	.word	63
	.word	72
	.word	81
.LC0:
	.ascii "x y\15\0"
.LC1:
	.ascii "%d %d  error\15\12\0"
.LC2:
	.ascii "accomplish!\15\0"
	.text
	.globl	main
	.def	main;	.scl	2;	.type	32;	.endef
	.seh_proc	main
main:
	push	rbp	 # 保存调用者的rbp，函数序言开始
	.seh_pushreg	rbp
	mov	rbp, rsp	 # 建立新的栈帧：rbp <- rsp
	.seh_setframe	rbp, 0
	sub	rsp, 48	 # 为局部变量分配48字节栈空间
	.seh_stackalloc	48
	.seh_endprologue	 # SEH序言结束
 # 99err.c:16: int main(void) {
	call	__main	 # 运行时初始化（GCC/MSYS2 入口准备）
 # 99err.c:17: 	printf("x y\r\n");
	lea	rax, .LC0[rip]	 # 取常量字符串"x y\r\n"地址 -> rax
	mov	rcx, rax	 # Windows x64调用约定：RCX=第1参数
	call	puts	 # 调用puts输出一行
 # 99err.c:19: 	for (int i = 0; i < 9; ++i) {
	mov	DWORD PTR -4[rbp], 0	 # i=0（局部变量i存于[rbp-4]）
 # 99err.c:19: 	for (int i = 0; i < 9; ++i) {
	jmp	.L2	 # 跳转到i循环条件检查
.L6:
 # 99err.c:20: 		for (int j = 0; j < 9; ++j) {
	mov	DWORD PTR -8[rbp], 0	 # j=0（局部变量j存于[rbp-8]）
 # 99err.c:20: 		for (int j = 0; j < 9; ++j) {
	jmp	.L3	 # 跳转到j循环条件检查
.L5:
 # 99err.c:21: 			uint16_t expected = (uint16_t)((i + 1) * (j + 1));
	mov	eax, DWORD PTR -4[rbp]	 # 取i -> eax
	add	eax, 1	 # eax = i + 1
 # 99err.c:21: 			uint16_t expected = (uint16_t)((i + 1) * (j + 1));
	mov	edx, eax	 # edx = (i+1)
 # 99err.c:21: 			uint16_t expected = (uint16_t)((i + 1) * (j + 1));
	mov	eax, DWORD PTR -8[rbp]	 # 取j -> eax
	add	eax, 1	 # eax = j + 1
 # 99err.c:21: 			uint16_t expected = (uint16_t)((i + 1) * (j + 1));
	imul	eax, edx	 # eax = (i+1)*(j+1)
	mov	WORD PTR -10[rbp], ax	 # 写入expected（16位）到[rbp-10]
 # 99err.c:22: 			uint16_t actual   = TABLE[i][j];
	mov	eax, DWORD PTR -8[rbp]	 # eax = j
	movsx	rcx, eax	 # rcx = (int64)j
	mov	eax, DWORD PTR -4[rbp]	 # eax = i
	movsx	rdx, eax	 # rdx = (int64)i
	mov	rax, rdx	 # rax = i
	sal	rax, 3	 # rax = i << 3 = i*8
	add	rax, rdx	 # rax = i*8 + i = i*9（行偏移）
	add	rax, rcx	 # rax = i*9 + j（二维索引 -> 线性索引）
	lea	rdx, [rax+rax]	 # rdx = (i*9+j)*2（每项2字节）
	lea	rax, TABLE[rip]	 # rax = &TABLE[0][0]
	movzx	eax, WORD PTR [rdx+rax]	 # eax = *(uint16_t*)&TABLE[i][j]
	mov	WORD PTR -12[rbp], ax	 # actual = 16位值，保存到[rbp-12]
 # 99err.c:23: 			if (expected != actual) {
	movzx	eax, WORD PTR -10[rbp]	 # eax = expected（零扩展）
	cmp	ax, WORD PTR -12[rbp]	 # 比较 expected vs actual（16位）
	je	.L4	 # 相等则跳过打印
 # 99err.c:24: 				printf("%d %d  error\r\n", i + 1, j + 1);
	mov	eax, DWORD PTR -8[rbp]	 # eax = j
	lea	edx, 1[rax]	 # edx = j+1（第2个整型参数）
	mov	eax, DWORD PTR -4[rbp]	 # eax = i
	add	eax, 1	 # eax = i+1（第1个整型参数）
	mov	r8d, edx	 # r8d = j+1（第3参数）
	mov	edx, eax	 # edx = i+1（第2参数）
	lea	rax, .LC1[rip]	 # rax = 格式串"%d %d  error\r\n"
	mov	rcx, rax	 # rcx = 第1参数（格式串）
	call	printf	 # 打印错误坐标
.L4:
 # 99err.c:20: 		for (int j = 0; j < 9; ++j) {
	add	DWORD PTR -8[rbp], 1	 # j++
.L3:
 # 99err.c:20: 		for (int j = 0; j < 9; ++j) {
	cmp	DWORD PTR -8[rbp], 8	 # 判断 j <= 8
	jle	.L5	 # 是则继续内层循环
 # 99err.c:19: 	for (int i = 0; i < 9; ++i) {
	add	DWORD PTR -4[rbp], 1	 # i++
.L2:
 # 99err.c:19: 	for (int i = 0; i < 9; ++i) {
	cmp	DWORD PTR -4[rbp], 8	 # 判断 i <= 8
	jle	.L6	 # 是则继续外层循环
 # 99err.c:29: 	printf("accomplish!\r\n");
	lea	rax, .LC2[rip]	 # 取"accomplish!\r\n"地址
	mov	rcx, rax	 # RCX=第1参数
	call	puts	 # 打印完成提示
 # 99err.c:30: 	return 0;
	mov	eax, 0	 # 返回值=0
 # 99err.c:31: }
	add	rsp, 48	 # 释放栈空间
	pop	rbp	 # 恢复调用者rbp
	ret		 # 返回调用者
	.seh_endproc
	.def	__main;	.scl	2;	.type	32;	.endef
	.ident	"GCC: (Rev2, Built by MSYS2 project) 14.2.0"
	.def	puts;	.scl	2;	.type	32;	.endef
	.def	printf;	.scl	2;	.type	32;	.endef
