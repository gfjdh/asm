#include <stdio.h>
#include <dos.h>
#include <conio.h>

/* 
   兼容性修复：
   如果不是在 Turbo C 环境下（例如在 VS Code 中查看），
   定义 interrupt 关键字为空，避免语法报错。
*/
#ifndef __TURBOC__
    #define interrupt
    /* 解决 VS Code 中 asm 关键字报错 (假设使用 MSVC IntelliSense) */
    #ifndef asm
        #define asm __asm
    #endif
#endif

/* 保存旧的中断处理程序指针 */
void interrupt (*old_int4)(void);

/* 标志变量，用于指示是否发生了溢出中断 */
int overflow_flag = 0;

/* 
   新的 INT 4 (INTO) 中断服务程序 
*/
void interrupt new_int4(void) {
    overflow_flag = 1;
    printf("\n[ISR] Overflow Interrupt (INT 4) triggered!\n");
    printf("[ISR] Handling overflow error...\n");
}

int main() {
    /* 定义两个相加会溢出的16位有符号整数 */
    /* 32000 (0x7D00) + 1000 (0x03E8) = 33000 (0x80E8) */
    /* 33000 > 32767, 对于 signed int 是溢出的，结果会变成负数 */
    int a = 32000;
    int b = 1000;
    int result = 0;

    printf("System: Preparing to rewrite INT 4 vector...\n");

    /* 1. 获取并保存旧的 INT 4 中断向量 */
    old_int4 = getvect(4);

    /* 2. 设置新的 INT 4 中断向量指向我们的函数 */
    setvect(4, new_int4);

    printf("System: INT 4 vector updated.\n");
    printf("Calculation: %d + %d\n", a, b);

    asm {
        mov ax, a
        add ax, b      /* 执行加法，此时 OF (Overflow Flag) 会被置位 */
        mov result, ax /* 保存（错误的）结果 */
        
        /* 
           INTO 指令：
           如果 OF=1，则产生 INT 4 中断。
           如果 OF=0，则什么也不做。
        */
        into 
    }

    /* 检查是否触发了中断 */
    if (overflow_flag) {
        printf("Main: Overflow detected and handled.\n");
        printf("Main: Incorrect Result: %d (due to overflow)\n", result);
    } else {
        printf("Main: No overflow occurred.\n");
        printf("Main: Result: %d\n", result);
    }

    /* 3. 恢复旧的中断向量，否则退出后系统可能不稳定 */
    setvect(4, old_int4);
    printf("System: INT 4 vector restored.\n");

    return 0;
}
