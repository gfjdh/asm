main:
	push	rbp	 #
	.seh_pushreg	rbp
	mov	rbp, rsp	 #,
	.seh_setframe	rbp, 0
	sub	rsp, 48	 #,
	.seh_stackalloc	48
	.seh_endprologue
 # 100sum.c:2: int main() {
	call	__main	 #
 # 100sum.c:3:     int sum = 0;
	mov	DWORD PTR -8[rbp], 0	 # sum,
 # 100sum.c:4:     scanf("%d", &sum);
	lea	rax, -8[rbp]	 # tmp104,
	mov	rdx, rax	 #, tmp104
	lea	rax, .LC0[rip]	 # tmp105,
	mov	rcx, rax	 #, tmp105
	call	scanf	 #
 # 100sum.c:5:     for (int i = sum - 1; i > 0; i--) {
	mov	eax, DWORD PTR -8[rbp]	 # sum.0_1, sum
 # 100sum.c:5:     for (int i = sum - 1; i > 0; i--) {
	sub	eax, 1	 # tmp106,
	mov	DWORD PTR -4[rbp], eax	 # i, tmp106
 # 100sum.c:5:     for (int i = sum - 1; i > 0; i--) {
	jmp	.L2	 #
.L3:
 # 100sum.c:6:         sum += i;
	mov	edx, DWORD PTR -8[rbp]	 # sum.1_2, sum
	mov	eax, DWORD PTR -4[rbp]	 # tmp107, i
	add	eax, edx	 # _3, sum.1_2
	mov	DWORD PTR -8[rbp], eax	 # sum, _3
 # 100sum.c:5:     for (int i = sum - 1; i > 0; i--) {
	sub	DWORD PTR -4[rbp], 1	 # i,
.L2:
 # 100sum.c:5:     for (int i = sum - 1; i > 0; i--) {
	cmp	DWORD PTR -4[rbp], 0	 # i,
	jg	.L3	 #,
 # 100sum.c:8:     printf("%d\n", sum);
	mov	eax, DWORD PTR -8[rbp]	 # sum.2_4, sum
	mov	edx, eax	 #, sum.2_4
	lea	rax, .LC1[rip]	 # tmp108,
	mov	rcx, rax	 #, tmp108
	call	printf	 #
 # 100sum.c:9:     return 0;
	mov	eax, 0	 # _12,
 # 100sum.c:10: }
	add	rsp, 48	 #,
	pop	rbp	 #
	ret	
