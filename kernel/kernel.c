/**
 * Kernel com CLI
 */

#include "commands.h"

#define VGA_ADDRESS 0xB8000
#define VGA_WIDTH   80
#define VGA_HEIGHT  25
#define COLOR_WHITE 0x0F

volatile unsigned short* video = (unsigned short*)VGA_ADDRESS;
int cursor_x = 0;
int cursor_y = 0;

char input_buffer[256];
int input_pos = 0;

/* Portas I/O */
unsigned char inb(unsigned short port) {
    unsigned char result;
    __asm__ __volatile__("inb %1, %0" : "=a"(result) : "Nd"(port));
    return result;
}

void outb(unsigned short port, unsigned char data) {
    __asm__ __volatile__("outb %0, %1" : : "a"(data), "Nd"(port));
}

void outw(unsigned short port, unsigned short data) {
    __asm__ __volatile__("outw %0, %1" : : "a"(data), "Nd"(port));
}

/* Atualizar cursor de hardware */
void update_cursor(void) {
    unsigned short pos = cursor_y * VGA_WIDTH + cursor_x;
    outb(0x3D4, 14);
    outb(0x3D5, pos >> 8);
    outb(0x3D4, 15);
    outb(0x3D5, pos & 0xFF);
}

/* Funcoes de video */
void scroll(void) {
    if (cursor_y >= VGA_HEIGHT) {
        for (int i = 0; i < (VGA_HEIGHT - 1) * VGA_WIDTH; i++) {
            video[i] = video[i + VGA_WIDTH];
        }
        for (int i = (VGA_HEIGHT - 1) * VGA_WIDTH; i < VGA_HEIGHT * VGA_WIDTH; i++) {
            video[i] = ' ' | (COLOR_WHITE << 8);
        }
        cursor_y = VGA_HEIGHT - 1;
    }
}

void putchar(char c) {
    if (c == '\n') {
        cursor_x = 0;
        cursor_y++;
    } else if (c == '\b') {
        if (cursor_x > 0) {
            cursor_x--;
            video[cursor_y * VGA_WIDTH + cursor_x] = ' ' | (COLOR_WHITE << 8);
        }
    } else if (c >= ' ') {
        video[cursor_y * VGA_WIDTH + cursor_x] = c | (COLOR_WHITE << 8);
        cursor_x++;
        if (cursor_x >= VGA_WIDTH) {
            cursor_x = 0;
            cursor_y++;
        }
    }
    scroll();
    update_cursor();
}

void print(const char* str) {
    while (*str) putchar(*str++);
}

void clear(void) {
    for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        video[i] = ' ' | (COLOR_WHITE << 8);
    }
    cursor_x = 0;
    cursor_y = 0;
    update_cursor();
}

/* Comparar strings */
int strcmp(const char* a, const char* b) {
    while (*a && *a == *b) { a++; b++; }
    return *a - *b;
}

/* Teclado - scancode para ASCII */
char scancode_to_ascii(unsigned char sc) {
    static char map[128] = {
        0, 27, '1','2','3','4','5','6','7','8','9','0','-','=','\b',
        '\t','q','w','e','r','t','y','u','i','o','p','[',']','\n',
        0,'a','s','d','f','g','h','j','k','l',';','\'','`',
        0,'\\','z','x','c','v','b','n','m',',','.','/',0,
        '*',0,' '
    };
    if (sc < 128) return map[sc];
    return 0;
}

char read_key(void) {
    unsigned char sc;
    while (1) {
        if (inb(0x64) & 1) {
            sc = inb(0x60);
            if (!(sc & 0x80)) {
                return scancode_to_ascii(sc);
            }
        }
    }
}

/* Prompt */
void prompt(void) {
    print("> ");
}

/* Processar comando */
void process_cmd(char* cmd) {
    while (*cmd == ' ') cmd++;
    if (*cmd == 0) return;

    for (int i = 0; i < num_commands; i++) {
        if (strcmp(cmd, commands[i].name) == 0) {
            commands[i].func();
            return;
        }
    }

    print("Comando desconhecido: ");
    print(cmd);
    print("\n");
}

/* Main */
void kernel_main(void) {
    clear();
    prompt();

    while (1) {
        char c = read_key();

        if (c == '\n') {
            putchar('\n');
            input_buffer[input_pos] = 0;
            process_cmd(input_buffer);
            input_pos = 0;
            prompt();
        } else if (c == '\b') {
            if (input_pos > 0) {
                input_pos--;
                putchar('\b');
            }
        } else if (c && input_pos < 255) {
            input_buffer[input_pos++] = c;
            putchar(c);
        }
    }
}
