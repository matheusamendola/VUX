  #include "commands.h"


void cmd_echo(const char* arg) {
    print(arg);
    print("\n");
}

void cmd_clear(const char* arg) {
    clear();
}

void cmd_cls(const char* arg) {
    cmd_clear(arg);
}

void cmd_reboot(const char* arg) {
    outb(0x64, 0xFE);
}

void cmd_shutdown(const char* arg) {
    outw(0x604, 0x2000);
}

void cmd_help(const char* arg) {
    for (int i = 0; i < num_commands; i++) {
        print(commands[i].name);
        print(" - ");
        print(commands[i].desc);
        print("\n");
    }
}

Command commands[] = {
    {"help",     "mostra esta ajuda",   cmd_help},
    {"clear",    "limpa a tela",        cmd_clear},
    {"cls",      "alias para clear",    cmd_cls},
    {"reboot",   "reinicia o sistema",  cmd_reboot},
    {"shutdown", "desliga o sistema",   cmd_shutdown},
    {"echo",     "imprime texto",       cmd_echo},
};

  int num_commands = sizeof(commands) / sizeof(commands[0]);