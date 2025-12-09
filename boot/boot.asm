; Bootloader Stage 1 - Carrega o Stage 2 e Kernel
; Tamanho: 512 bytes (1 setor)

[BITS 16]
[ORG 0x7C00]

STAGE2_ADDR equ 0x7E00       ; Stage 2 logo apos bootloader
KERNEL_SEG  equ 0x1000       ; Kernel em 0x10000 (segmento)

start:
    ; Configurar segmentos
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Salvar drive de boot
    mov [BOOT_DRIVE], dl

    ; Mostrar mensagem
    mov si, MSG_BOOT
    call print_string

    ; Carregar Stage 2 (setores 2-5, 4 setores = 2KB) para 0x7E00
    mov ah, 0x02
    mov al, 4
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [BOOT_DRIVE]
    mov bx, STAGE2_ADDR
    int 0x13
    jc disk_error

    ; Carregar Kernel (setores 6+) para 0x10000
    mov ax, KERNEL_SEG
    mov es, ax
    xor bx, bx

    mov ah, 0x02
    mov al, 60
    mov ch, 0
    mov cl, 6
    mov dh, 0
    mov dl, [BOOT_DRIVE]
    int 0x13
    jc disk_error

    ; Restaurar ES
    xor ax, ax
    mov es, ax

    ; Pular para Stage 2
    jmp 0x0000:STAGE2_ADDR

disk_error:
    mov si, MSG_ERR
    call print_string
    jmp $

print_string:
    pusha
.loop:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .loop
.done:
    popa
    ret

; Dados
BOOT_DRIVE: db 0
MSG_BOOT:   db "Booting...", 13, 10, 0
MSG_ERR:    db "Disk Error!", 0

; Padding e assinatura
times 510 - ($ - $$) db 0
dw 0xAA55
