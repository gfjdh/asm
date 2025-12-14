DATA SEGMENT
    MSG_START   DB 'Homework 6: Rewrite Overflow Interrupt Handler', 0Dh, 0Ah, '$'
    MSG_INSTALL DB 'New interrupt handler installed.', 0Dh, 0Ah, '$'
    MSG_TRIG    DB 'Triggering overflow...', 0Dh, 0Ah, '$'
    MSG_CAUGHT  DB 0Dh, 0Ah, 'Overflow Interrupt (Int 4) Triggered', 0Dh, 0Ah, '$'
    MSG_RESTORE DB 'Old interrupt handler restored.', 0Dh, 0Ah, '$'
    
    OLD_IP      DW ?    ; 保存旧中断向量的 IP
    OLD_CS      DW ?    ; 保存旧中断向量的 CS
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STACK

START:
    MOV AX, DATA
    MOV DS, AX

    ; 打印开始信息
    LEA DX, MSG_START
    MOV AH, 09H
    INT 21H

    ; 1. 保存旧的 INT 4 中断向量
    MOV AH, 35H     ; 功能号：获取中断向量
    MOV AL, 04H     ; 中断号：4 (Overflow)
    INT 21H         ; 返回：ES:BX = 中断向量
    MOV OLD_IP, BX
    MOV OLD_CS, ES

    ; 2. 设置新的 INT 4 中断向量
    PUSH DS         ; 保存 DS
    MOV DX, OFFSET NEW_INT4_HANDLER ; DX = 偏移地址
    MOV AX, SEG NEW_INT4_HANDLER    ; AX = 段地址
    MOV DS, AX      ; DS:DX 指向新的中断处理程序
    MOV AH, 25H     ; 功能号：设置中断向量
    MOV AL, 04H     ; 中断号：4
    INT 21H
    POP DS          ; 恢复 DS

    ; 打印安装成功信息
    LEA DX, MSG_INSTALL
    MOV AH, 09H
    INT 21H

    ; 3. 制造溢出并触发 INTO
    LEA DX, MSG_TRIG
    MOV AH, 09H
    INT 21H

    MOV AX, 7FFFH   ; AX = 32767
    ADD AX, 1       ; AX = 8000H (-32768), OF=1
    INTO            ; 触发 INT 4

    ; 4. 恢复旧的中断向量
    PUSH DS
    MOV DX, OLD_IP
    MOV AX, OLD_CS
    MOV DS, AX
    MOV AH, 25H
    MOV AL, 04H
    INT 21H
    POP DS

    ; 打印恢复成功信息
    LEA DX, MSG_RESTORE
    MOV AH, 09H
    INT 21H

    ; 退出程序
    MOV AH, 4CH
    INT 21H

; ---------------------------------------------------------
; 自定义中断服务程序
; ---------------------------------------------------------
NEW_INT4_HANDLER PROC FAR
    ; 保存寄存器
    PUSH AX
    PUSH DX
    PUSH DS

    ; 设置 DS 指向数据段 (因为进入中断时 DS 未知)
    ; 这里假设 DATA 段地址与主程序相同，且我们能通过某种方式知道它
    ; 简单起见，我们直接加载 DATA 段。
    ; 在 DOS EXE 中，这通常是可行的，或者将数据放在 CS 段中。
    MOV AX, DATA
    MOV DS, AX

    ; 打印捕获信息
    LEA DX, MSG_CAUGHT
    MOV AH, 09H
    INT 21H

    ; 恢复寄存器
    POP DS
    POP DX
    POP AX
    IRET            ; 中断返回
NEW_INT4_HANDLER ENDP

CODE ENDS

STACK SEGMENT STACK
    DB 128 DUP(?)
STACK ENDS

END START
