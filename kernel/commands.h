#ifndef COMMANDS_H
#define COMMANDS_H

/* Funcoes do kernel disponiveis para comandos */
void print(const char* str);
void clear(void);
void outb(unsigned short port, unsigned char data);
void outw(unsigned short port, unsigned short data);

/* Comandos */
void cmd_clear(void);
void cmd_reboot(void);
void cmd_shutdown(void);

/* Estrutura de comando */
typedef struct {
    const char* name;
    void (*func)(void);
} Command;

/* Lista de comandos */
extern Command commands[];
extern int num_commands;

#endif
