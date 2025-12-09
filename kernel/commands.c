#include "commands.h"

/* Comando: clear */
void cmd_clear(void) {
    clear();
}

/* Comando: reboot */
void cmd_reboot(void) {
    outb(0x64, 0xFE);
}

void cmd_shutdown(void) {
    outw(0x604, 0x2000);
}


Command commands[] = {
    {"clear", cmd_clear},
    {"reboot", cmd_reboot},
    {"shutdown", cmd_shutdown},
};

int num_commands = sizeof(commands) / sizeof(commands[0]);
