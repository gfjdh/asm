STKSEG SEGMENT STACK        ; 定义堆栈段
    DW 32 DUP(0)            ; 分配堆栈空间
STKSEG ENDS                 ; 堆栈段结束

DATASEG SEGMENT             ; 定义数据段
    TABLE DW 7, 2, 3, 4, 5, 6, 7, 8, 9      ; 定义9x9乘法表数据（字类型）
          DW 2, 4, 7, 8, 10, 12, 14, 16, 18
          DW 3, 6, 9, 12, 15, 18, 21, 24, 27
          DW 4, 8, 12, 16, 7, 24, 28, 32, 36
          DW 5, 10, 15, 20, 25, 30, 35, 40, 45
          DW 6, 12, 18, 24, 30, 7, 42, 48, 54
          DW 7, 14, 21, 28, 35, 42, 49, 56, 63
          DW 8, 16, 24, 32, 40, 48, 56, 7, 72
          DW 9, 18, 27, 36, 45, 54, 63, 72, 81
    MSG1 DB "x y$"          ; 定义字符串"x y"
    MSG2 DB "  error$"      ; 定义字符串"  error"
    MSG3 DB "accomplish!$"  ; 定义字符串"accomplish!"
    NEWLINE DB 0DH, 0AH, '$' ; 定义回车换行字符串
DATASEG ENDS                ; 数据段结束

CODESEG SEGMENT             ; 定义代码段
    ASSUME CS:CODESEG, DS:DATASEG, SS:STKSEG ; 设置段寄存器关联
MAIN PROC FAR               ; 主程序（远过程）
    MOV AX, DATASEG         ; 将数据段地址加载到AX
    MOV DS, AX              ; 设置DS指向数据段
    ; 初始化堆栈段和栈指针（必须，否则中断/调用可能破坏内存或导致死机）
    MOV AX, STKSEG         ; 将堆栈段地址加载到AX
    MOV SS, AX             ; 设置SS指向堆栈段
    MOV SP, 64             ; 设置SP到堆栈顶部（32个字 = 64字节）

    ; 打印"x y"后跟换行
    MOV AH, 09H             ; DOS功能号09H（显示字符串）
    MOV DX, OFFSET MSG1     ; 加载MSG1的偏移地址
    INT 21H                 ; 调用DOS中断
    MOV DX, OFFSET NEWLINE  ; 加载换行字符串的偏移地址
    INT 21H                 ; 打印换行

    ; 初始化循环变量：SI为行索引（i），DI为列索引（j）
    MOV SI, 0               ; SI = 0（i从0开始）
OUTER_LOOP:
    CMP SI, 9               ; 比较SI是否小于9
    JGE END_OUTER           ; 如果SI >= 9，跳出外循环
    MOV DI, 0               ; DI = 0（j从0开始）
INNER_LOOP:
    CMP DI, 9               ; 比较DI是否小于9
    JGE END_INNER           ; 如果DI >= 9，跳出内循环

    ; 计算期望值 (i+1) * (j+1)
    MOV AX, SI              ; AX = i
    INC AX                  ; AX = i+1
    MOV BX, DI              ; BX = j
    INC BX                  ; BX = j+1
    MUL BL                  ; AX = AL * BL = (i+1) * (j+1)（结果在AX中）
    MOV CX, AX              ; 保存期望值到CX

    ; 计算数组元素地址：TABLE + (i*9 + j)*2
    MOV AX, SI              ; AX = i
    MOV BX, 9               ; BX = 9
    MUL BX                  ; AX = i * 9
    ADD AX, DI              ; AX = i*9 + j
    SHL AX, 1               ; AX = (i*9 + j)*2（乘以2，因为元素为字类型）
    MOV BX, AX              ; BX = 偏移量
    MOV DX, TABLE[BX]       ; DX = 数组中的实际值

    ; 比较实际值和期望值
    CMP CX, DX              ; 比较CX（期望值）和DX（实际值）
    JE SKIP_ERROR           ; 如果相等，跳过错误处理

    ; 打印错误信息：行号(i+1)、空格、列号(j+1)、空格、"error"
    MOV AX, SI              ; AX = i
    INC AX                  ; AX = i+1
    ADD AL, '0'             ; 转换为ASCII字符
    MOV DL, AL              ; DL = 行号的ASCII字符
    MOV AH, 02H             ; DOS功能号02H（显示字符）
    INT 21H                 ; 打印行号
    MOV DL, ' '             ; DL = 空格
    MOV AH, 02H             ; 确保功能号为显示字符
    INT 21H                 ; 打印空格
    MOV AX, DI              ; AX = j
    INC AX                  ; AX = j+1
    ADD AL, '0'             ; 转换为ASCII字符
    MOV DL, AL              ; DL = 列号的ASCII字符
    MOV AH, 02H             ; 确保功能号为显示字符
    INT 21H                 ; 打印列号
    MOV AH, 09H             ; DOS功能号09H（显示字符串）
    MOV DX, OFFSET MSG2     ; 加载MSG2的偏移地址（"  error"）
    INT 21H                 ; 打印错误字符串
    MOV DX, OFFSET NEWLINE  ; 加载换行字符串的偏移地址
    INT 21H                 ; 打印换行

SKIP_ERROR:
    INC DI                  ; j++
    JMP INNER_LOOP          ; 继续内循环
END_INNER:
    INC SI                  ; i++
    JMP OUTER_LOOP          ; 继续外循环
END_OUTER:

    ; 打印"accomplish!"后跟换行
    MOV AH, 09H             ; DOS功能号09H（显示字符串）
    MOV DX, OFFSET MSG3     ; 加载MSG3的偏移地址
    INT 21H                 ; 打印字符串
    MOV DX, OFFSET NEWLINE  ; 加载换行字符串的偏移地址
    INT 21H                 ; 打印换行

    ; 程序结束
    MOV AX, 4C00H           ; DOS功能号4CH（程序结束）
    INT 21H                 ; 调用DOS中断
MAIN ENDP                   ; 主程序结束
CODESEG ENDS                ; 代码段结束
    END MAIN                ; 程序入口点