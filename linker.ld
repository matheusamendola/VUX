/* Linker Script para o Kernel (Rust + ASM) */

/* Ponto de entrada do kernel */
ENTRY(_start)

/* Endereco onde o kernel sera carregado */
KERNEL_OFFSET = 0x1000;

SECTIONS
{
    /* Carregar o kernel no endereco 0x1000 */
    . = KERNEL_OFFSET;

    /* Secao de codigo */
    .text : ALIGN(4)
    {
        *(.text._start)
        *(.text)
        *(.text.*)
    }

    /* Secao de dados somente leitura */
    .rodata : ALIGN(4)
    {
        *(.rodata)
        *(.rodata.*)
    }

    /* Secao de dados inicializados */
    .data : ALIGN(4)
    {
        *(.data)
        *(.data.*)
    }

    /* Secao de dados nao inicializados (BSS) */
    .bss : ALIGN(4)
    {
        __bss_start = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
        __bss_end = .;
    }

    /* Descartar secoes desnecessarias */
    /DISCARD/ :
    {
        *(.comment)
        *(.note.*)
        *(.eh_frame)
        *(.eh_frame_hdr)
    }
}
