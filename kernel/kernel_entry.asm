; Kernel Entry Point (64-bit)
; Este arquivo e o ponto de entrada do kernel e chama kernel_main() do Rust

[BITS 64]
[EXTERN kernel_main]

section .text
    global _start

_start:
    ; Limpar registradores
    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    xor rdx, rdx
    xor rsi, rsi
    xor rdi, rdi
    xor rbp, rbp
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15

    ; Chamar kernel_main
    call kernel_main

    ; Loop infinito caso retorne
.halt:
    hlt
    jmp .halt
