//! Sistema de comandos da CLI

use crate::vga::{print, clear};
use crate::io::{outb, outw};

/// Estrutura que representa um comando
pub struct Command {
    pub name: &'static str,
    pub desc: &'static str,
    pub func: fn(&str),
}

/// Lista de comandos disponiveis
pub static COMMANDS: &[Command] = &[
    Command { name: "help", desc: "mostra esta ajuda", func: cmd_help },
    Command { name: "clear", desc: "limpa a tela", func: cmd_clear },
    Command { name: "cls", desc: "alias para clear", func: cmd_clear },
    Command { name: "reboot", desc: "reinicia o sistema", func: cmd_reboot },
    Command { name: "shutdown", desc: "desliga o sistema", func: cmd_shutdown },
    Command { name: "echo", desc: "imprime texto", func: cmd_echo },
];

/// Comando: help
fn cmd_help(_arg: &str) {
    for cmd in COMMANDS {
        print(cmd.name);
        print(" - ");
        print(cmd.desc);
        print("\n");
    }
}

/// Comando: clear/cls
fn cmd_clear(_arg: &str) {
    clear();
}

/// Comando: reboot
fn cmd_reboot(_arg: &str) {
    outb(0x64, 0xFE);
}

/// Comando: shutdown (QEMU/Bochs)
fn cmd_shutdown(_arg: &str) {
    outw(0x604, 0x2000);
}

/// Comando: echo
fn cmd_echo(arg: &str) {
    print(arg);
    print("\n");
}

/// Verifica se o input corresponde ao nome do comando
fn cmd_match(input: &str, name: &str) -> bool {
    let input_bytes = input.as_bytes();
    let name_bytes = name.as_bytes();

    if input_bytes.len() < name_bytes.len() {
        return false;
    }

    for i in 0..name_bytes.len() {
        if input_bytes[i] != name_bytes[i] {
            return false;
        }
    }

    // Deve terminar ou ter espaco apos o comando
    input_bytes.len() == name_bytes.len() || input_bytes[name_bytes.len()] == b' '
}

/// Processa um comando
pub fn process_cmd(cmd: &str) {
    // Remove espacos iniciais
    let cmd = cmd.trim_start();

    if cmd.is_empty() {
        return;
    }

    for command in COMMANDS {
        if cmd_match(cmd, command.name) {
            // Extrai argumento (apos o nome do comando)
            let arg = if cmd.len() > command.name.len() {
                cmd[command.name.len()..].trim_start()
            } else {
                ""
            };
            (command.func)(arg);
            return;
        }
    }

    print("Comando desconhecido: ");
    print(cmd);
    print("\n");
}
