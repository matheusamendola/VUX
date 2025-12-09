; Bootloader Stage 2 - Configura Long Mode e pula para o kernel
; Carregado em 0x7E00 (setores 2-5)

[BITS 16]
[ORG 0x7E00]

KERNEL_ADDR equ 0x10000

stage2_start:
    ; Configurar segmentos novamente
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; Mostrar mensagem
    mov si, MSG_STAGE2
    call print_string_16

    ; Verificar Long Mode
    call check_long_mode

    ; Desabilitar interrupcoes
    cli

    ; Desabilitar NMI
    in al, 0x70
    or al, 0x80
    out 0x70, al

    ; Carregar GDT 32-bit
    lgdt [gdt32_descriptor]

    ; Entrar em modo protegido
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Far jump para modo protegido
    jmp CODE32_SEG:protected_mode

;--------------------------------------------------
; Funcoes 16-bit
;--------------------------------------------------
print_string_16:
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

check_long_mode:
    ; Verificar CPUID
    pushfd
    pop eax
    mov ecx, eax
    xor eax, 1 << 21
    push eax
    popfd
    pushfd
    pop eax
    push ecx
    popfd
    cmp eax, ecx
    je .no_long_mode

    ; Verificar extended CPUID
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb .no_long_mode

    ; Verificar Long Mode
    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29
    jz .no_long_mode
    ret

.no_long_mode:
    mov si, MSG_NO_LONG
    call print_string_16
    jmp $

;--------------------------------------------------
; GDT 32-bit
;--------------------------------------------------
gdt32_start:
    dq 0                        ; Null
gdt32_code:
    dw 0xFFFF, 0x0000
    db 0x00, 10011010b, 11001111b, 0x00
gdt32_data:
    dw 0xFFFF, 0x0000
    db 0x00, 10010010b, 11001111b, 0x00
gdt32_end:

gdt32_descriptor:
    dw gdt32_end - gdt32_start - 1
    dd gdt32_start

CODE32_SEG equ gdt32_code - gdt32_start
DATA32_SEG equ gdt32_data - gdt32_start

;--------------------------------------------------
; 32-bit Protected Mode
;--------------------------------------------------
[BITS 32]
protected_mode:
    mov ax, DATA32_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; Configurar paginacao
    call setup_paging

    ; Ativar Long Mode
    call enable_long_mode

    ; Carregar GDT 64-bit
    lgdt [gdt64_descriptor]

    ; Far jump para Long Mode
    jmp CODE64_SEG:long_mode

;--------------------------------------------------
; Configurar Paginacao
;--------------------------------------------------
setup_paging:
    ; Limpar tabelas de paginas
    mov edi, 0x70000
    xor eax, eax
    mov ecx, 0x4000 / 4
    rep stosd

    ; PML4[0] -> PDPT
    mov dword [0x70000], 0x71003

    ; PDPT[0] -> PD
    mov dword [0x71000], 0x72003

    ; PD[0] -> 2MB page identity mapped
    mov dword [0x72000], 0x000083      ; 0-2MB
    mov dword [0x72008], 0x200083      ; 2-4MB
    mov dword [0x72010], 0x400083      ; 4-6MB
    mov dword [0x72018], 0x600083      ; 6-8MB

    ; Carregar CR3
    mov eax, 0x70000
    mov cr3, eax

    ret

;--------------------------------------------------
; Ativar Long Mode
;--------------------------------------------------
enable_long_mode:
    ; Ativar PAE
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; Ativar Long Mode no EFER MSR
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; Ativar Paging
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ret

;--------------------------------------------------
; GDT 64-bit
;--------------------------------------------------
gdt64_start:
    dq 0                        ; Null
gdt64_code:
    dw 0x0000, 0x0000
    db 0x00, 10011010b, 00100000b, 0x00
gdt64_data:
    dw 0x0000, 0x0000
    db 0x00, 10010010b, 00000000b, 0x00
gdt64_end:

gdt64_descriptor:
    dw gdt64_end - gdt64_start - 1
    dq gdt64_start

CODE64_SEG equ gdt64_code - gdt64_start
DATA64_SEG equ gdt64_data - gdt64_start

;--------------------------------------------------
; 64-bit Long Mode
;--------------------------------------------------
[BITS 64]
long_mode:
    ; Configurar segmentos
    mov ax, DATA64_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Stack
    mov rsp, 0x90000

    ; Pular para o kernel em 0x10000
    mov rax, 0x10000
    jmp rax

    ; Nunca deve chegar aqui
    hlt

;--------------------------------------------------
; Dados
;--------------------------------------------------
MSG_STAGE2:  db "Long Mode setup...", 13, 10, 0
MSG_NO_LONG: db "ERROR: No 64-bit support!", 0

; Padding para ocupar exatamente 4 setores (2048 bytes)
times 2048 - ($ - $$) db 0
