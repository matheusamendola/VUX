; Bootloader - Carrega o kernel e pula para ele
; Compilar com: nasm -f bin boot.asm -o boot.bin

[BITS 16]
[ORG 0x7C00]

KERNEL_OFFSET equ 0x1000  ; Endereco onde o kernel sera carregado

start:
    ; Configurar segmentos
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00        ; Stack cresce para baixo a partir do bootloader

    ; Salvar drive de boot
    mov [BOOT_DRIVE], dl

    ; Imprimir mensagem de boot
    mov si, MSG_BOOT
    call print_string

    ; Carregar kernel do disco
    call load_kernel

    ; Mudar para modo protegido 32-bit
    call switch_to_pm

    jmp $                 ; Nunca deve chegar aqui

;--------------------------------------------------
; Funcao: print_string
; Imprime string terminada em null apontada por SI
;--------------------------------------------------
print_string:
    pusha
.loop:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0E
    int 0x10
    jmp .loop
.done:
    popa
    ret

;--------------------------------------------------
; Funcao: load_kernel
; Carrega o kernel do disco para a memoria
;--------------------------------------------------
load_kernel:
    mov si, MSG_LOAD
    call print_string

    mov bx, KERNEL_OFFSET ; ES:BX = destino
    mov dh, 15            ; Numero de setores a ler
    mov dl, [BOOT_DRIVE]
    call disk_load

    ret

;--------------------------------------------------
; Funcao: disk_load
; Carrega DH setores do drive DL para ES:BX
;--------------------------------------------------
disk_load:
    pusha
    push dx

    mov ah, 0x02          ; Funcao de leitura do BIOS
    mov al, dh            ; Numero de setores
    mov ch, 0             ; Cilindro 0
    mov cl, 2             ; Setor 2 (1 = bootloader)
    mov dh, 0             ; Cabeca 0

    int 0x13              ; Interrupcao do BIOS para disco
    jc disk_error

    pop dx
    cmp al, dh            ; Verificar se leu todos os setores
    jne disk_error

    popa
    ret

disk_error:
    mov si, MSG_DISK_ERR
    call print_string
    jmp $

;--------------------------------------------------
; GDT - Global Descriptor Table
;--------------------------------------------------
gdt_start:
    ; Descriptor nulo (obrigatorio)
    dq 0

gdt_code:
    ; Segmento de codigo: base=0, limite=0xFFFFF
    dw 0xFFFF             ; Limite (bits 0-15)
    dw 0                  ; Base (bits 0-15)
    db 0                  ; Base (bits 16-23)
    db 10011010b          ; Flags: present, ring 0, code segment, executable, readable
    db 11001111b          ; Flags: granularity 4KB, 32-bit mode + Limite (bits 16-19)
    db 0                  ; Base (bits 24-31)

gdt_data:
    ; Segmento de dados: base=0, limite=0xFFFFF
    dw 0xFFFF
    dw 0
    db 0
    db 10010010b          ; Flags: present, ring 0, data segment, writable
    db 11001111b
    db 0

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Tamanho da GDT
    dd gdt_start                ; Endereco da GDT

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

;--------------------------------------------------
; Funcao: switch_to_pm
; Muda para modo protegido 32-bit
;--------------------------------------------------
switch_to_pm:
    cli                   ; Desabilitar interrupcoes
    lgdt [gdt_descriptor] ; Carregar GDT

    ; Ativar modo protegido (bit 0 do CR0)
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Far jump para limpar pipeline e carregar CS
    jmp CODE_SEG:init_pm

;--------------------------------------------------
; Codigo de 32-bit - Modo Protegido
;--------------------------------------------------
[BITS 32]
init_pm:
    ; Configurar segmentos para modo protegido
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000      ; Stack no topo da memoria livre
    mov esp, ebp

    call KERNEL_OFFSET    ; Pular para o kernel!

    jmp $                 ; Loop infinito (nunca deve chegar aqui)

;--------------------------------------------------
; Dados
;--------------------------------------------------
BOOT_DRIVE:   db 0
MSG_BOOT:     db "Bootloader iniciado...", 13, 10, 0
MSG_LOAD:     db "Carregando kernel...", 13, 10, 0
MSG_DISK_ERR: db "Erro de disco!", 0

;--------------------------------------------------
; Padding e Magic Number
;--------------------------------------------------
times 510 - ($ - $$) db 0
dw 0xAA55
