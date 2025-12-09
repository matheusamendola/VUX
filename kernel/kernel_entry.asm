; Kernel Entry Point
; Este arquivo e o ponto de entrada do kernel e chama a funcao main() do C

[BITS 32]
[EXTERN kernel_main]    ; Declarar funcao externa do C

section .text
    global _start

_start:
    call kernel_main    ; Chamar a funcao principal do kernel em C
    jmp $               ; Loop infinito caso o kernel retorne
