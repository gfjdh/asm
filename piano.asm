; 钢琴 TSR 程序
; 汇编器: MASM
; 环境: DOSBox
; 功能: 按 F1 切换钢琴模式。
;       在钢琴模式中，按键 A-K 演奏 C 到高音 C（多-多）。

.model tiny
.code
org 100h

start:
    jmp install

    ; =============================================================
    ; 常驻数据
    ; =============================================================
    old_int9_off dw ?
    old_int9_seg dw ?
    piano_active db 0 ; 0 = 关, 1 = 开

    ; 扫描码到频率除数的映射
    ; 格式: 扫描码, 除数低字节, 除数高字节
    ; 频率 = 1193180 / 除数
    note_table label byte
        db 1Eh, 0CAh, 11h ; A - 多 (262Hz) -> 4554 (11CAh)
        db 1Fh, 0DAh, 0Fh ; S - 来 (294Hz) -> 4058 (0FDAh)
        db 20h, 20h, 0Eh  ; D - 咪 (330Hz) -> 3616 (0E20h)
        db 21h, 5Bh, 0Dh  ; F - 发 (349Hz) -> 3419 (0D5Bh)
        db 22h, 0E4h, 0Bh ; G - 索 (392Hz) -> 3044 (0BE4h)
        db 23h, 98h, 0Ah  ; H - 拉 (440Hz) -> 2712 (0A98h)
        db 24h, 6Fh, 09h  ; J - 西 (494Hz) -> 2415 (096Fh)
        db 25h, 0E9h, 08h ; K - 高音多 (523Hz) -> 2281 (08E9h)
        db 0 ; 表结束标记

    ; =============================================================
    ; 新的 09h 中断处理程序
    ; =============================================================
new_int9 proc far
    push ax
    push bx
    push cx
    push dx
    push si
    push ds
    push es

    ; 将 DS 设为 CS，因为处于 TSR 环境且无法确定 DS
    push cs
    pop ds

    in al, 60h ; 从键盘端口读取扫描码
    
    ; -------------------------------------------------------------
    ; 检查热键 (F1)
    ; -------------------------------------------------------------
    cmp al, 3Bh ; F1 按下代码
    je toggle_mode
    
    cmp al, 0BBh ; F1 松开代码 (3Bh + 80h)
    je consume_key_f1 ; 消费按键但不切换模式

    ; -------------------------------------------------------------
    ; 检查钢琴模式是否激活
    ; -------------------------------------------------------------
    cmp piano_active, 1
    je piano_handler

    ; -------------------------------------------------------------
    ; 传递给旧的处理程序（普通模式）
    ; -------------------------------------------------------------
    pop es
    pop ds
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    
    ; 远跳转到旧的中断处理程序
    jmp dword ptr cs:[old_int9_off]

toggle_mode:
    xor piano_active, 1 ; 切换状态 (0->1 或 1->0)
    
    ; 若关闭，立即确保声音关闭
    cmp piano_active, 0
    jne consume_key_f1
    call speaker_off
    jmp consume_key_f1

consume_key_f1:
    jmp consume_key_ack

    ; -------------------------------------------------------------
    ; 钢琴模式逻辑
    ; -------------------------------------------------------------
piano_handler:
    ; 检查是否为松开代码（按键释放）
    test al, 80h
    jnz key_release

    ; 按键按下（Make 代码）
    ; 在表中查找
    mov si, offset note_table
check_loop:
    mov ah, [si]
    cmp ah, 0
    je consume_key_ack ; 不在表中，忽略但消费以防止输入字符
    cmp ah, al
    je play_note
    add si, 3
    jmp check_loop

play_note:
    ; 找到音符。除数位于 [si+1]（低字节）和 [si+2]（高字节）
    mov bl, [si+1]
    mov bh, [si+2]
    call speaker_on
    jmp consume_key_ack

key_release:
    ; 如果按键释放，检查是否是我们的钢琴按键之一
    and al, 7Fh ; 取原始扫描码
    
    mov si, offset note_table
release_loop:
    mov ah, [si]
    cmp ah, 0
    je consume_key_ack
    cmp ah, al
    je stop_sound
    add si, 3
    jmp release_loop

stop_sound:
    call speaker_off
    jmp consume_key_ack

    ; -------------------------------------------------------------
    ; 消耗按键并发送中断结束信号
    ; -------------------------------------------------------------
consume_key_ack:
    ; 重置键盘控制器（消费 int 9 时必须）
    in al, 61h
    mov ah, al
    or al, 80h
    out 61h, al
    mov al, ah
    out 61h, al

    ; 发送 EOI（中断结束）到 PIC
    mov al, 20h
    out 20h, al

    pop es
    pop ds
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    iret
new_int9 endp

    ; =============================================================
    ; 扬声器控制例程
    ; =============================================================
speaker_on proc near
    ; 设置定时器 2（端口 42h）
    ; BX 包含频率除数
    mov al, 0B6h ; 10110110b : Channel 2, Mode 3, 读写低高字节
    out 43h, al
    
    mov al, bl
    out 42h, al
    mov al, bh
    out 42h, al

    ; 启用扬声器（端口 61h）
    in al, 61h
    or al, 3 ; 置位位0（门2）和位1（扬声器数据）
    out 61h, al
    ret
speaker_on endp

speaker_off proc near
    in al, 61h
    and al, 0FCh ; 清除位0和位1
    out 61h, al
    ret
speaker_off endp

    ; =============================================================
    ; 安装代码（临时）
    ; =============================================================
install:
    ; 确保安装部分 DS=CS
    push cs
    pop ds

    ; 获取旧的 09h 中断向量
    mov ax, 3509h
    int 21h
    mov old_int9_off, bx
    mov old_int9_seg, es

    ; 设置新的 09h 中断向量
    mov dx, offset new_int9
    mov ax, 2509h
    int 21h

    ; 打印安装信息
    mov dx, offset msg
    mov ah, 09h
    int 21h

    ; 终止并保留常驻
    ; DX 必须指向空闲内存的第一个字节（常驻代码末尾）
    mov dx, offset install
    int 27h 

msg db 'Piano TSR Installed.', 13, 10
    db 'Press F1 to toggle Piano Mode.', 13, 10
    db 'Keys: A S D F G H J K -> Do Re Mi Fa Sol La Si Do', 13, 10, '$'

end start
