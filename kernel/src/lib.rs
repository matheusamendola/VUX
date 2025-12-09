//! Kernel em Rust - CLI simples
//!
//! Este kernel implementa uma interface de linha de comando basica
//! rodando em Long Mode x86_64.

#![no_std]
#![no_main]
#![allow(static_mut_refs)]

mod io;
mod vga;
mod keyboard;
mod commands;

use core::panic::PanicInfo;
use vga::{print, clear, putchar, set_cursor_x, rewrite_input};
use keyboard::{read_key, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT};
use commands::process_cmd;

const PROMPT_LEN: usize = 2;  // "> "
const MAX_INPUT: usize = 256;
const MAX_HISTORY: usize = 10;

/// Buffer de entrada
static mut INPUT_BUFFER: [u8; MAX_INPUT] = [0; MAX_INPUT];
static mut INPUT_LEN: usize = 0;
static mut CURSOR_POS: usize = 0;

/// Historico de comandos
static mut HISTORY: [[u8; MAX_INPUT]; MAX_HISTORY] = [[0; MAX_INPUT]; MAX_HISTORY];
static mut HISTORY_LEN: [usize; MAX_HISTORY] = [0; MAX_HISTORY];
static mut HISTORY_COUNT: usize = 0;
static mut HISTORY_INDEX: usize = 0;
static mut BROWSING_HISTORY: bool = false;

/// Imprime o prompt
fn prompt() {
    print("> ");
}

/// Copia um buffer para outro
fn copy_buffer(src: &[u8], dst: &mut [u8], len: usize) {
    for i in 0..len {
        dst[i] = src[i];
    }
}

/// Adiciona comando ao historico
unsafe fn add_to_history() {
    if INPUT_LEN == 0 {
        return;
    }

    // Mover historico para cima
    if HISTORY_COUNT < MAX_HISTORY {
        HISTORY_COUNT += 1;
    }

    for i in (1..HISTORY_COUNT).rev() {
        copy_buffer(&HISTORY[i - 1], &mut HISTORY[i], HISTORY_LEN[i - 1]);
        HISTORY_LEN[i] = HISTORY_LEN[i - 1];
    }

    // Adicionar novo comando no inicio
    copy_buffer(&INPUT_BUFFER, &mut HISTORY[0], INPUT_LEN);
    HISTORY_LEN[0] = INPUT_LEN;
}

/// Carrega comando do historico
unsafe fn load_from_history(index: usize) {
    if index < HISTORY_COUNT {
        INPUT_LEN = HISTORY_LEN[index];
        copy_buffer(&HISTORY[index], &mut INPUT_BUFFER, INPUT_LEN);
        CURSOR_POS = INPUT_LEN;

        // Reescrever na tela
        rewrite_input(PROMPT_LEN, &INPUT_BUFFER, INPUT_LEN);
        set_cursor_x(PROMPT_LEN + CURSOR_POS);
    }
}

/// Insere caractere na posicao do cursor
unsafe fn insert_char(c: u8) {
    if INPUT_LEN >= MAX_INPUT - 1 {
        return;
    }

    // Mover caracteres para a direita
    for i in (CURSOR_POS..INPUT_LEN).rev() {
        INPUT_BUFFER[i + 1] = INPUT_BUFFER[i];
    }

    INPUT_BUFFER[CURSOR_POS] = c;
    INPUT_LEN += 1;
    CURSOR_POS += 1;

    // Reescrever linha
    rewrite_input(PROMPT_LEN, &INPUT_BUFFER, INPUT_LEN);
    set_cursor_x(PROMPT_LEN + CURSOR_POS);
}

/// Remove caractere antes do cursor (backspace)
unsafe fn delete_char() {
    if CURSOR_POS == 0 {
        return;
    }

    // Mover caracteres para a esquerda
    for i in CURSOR_POS - 1..INPUT_LEN - 1 {
        INPUT_BUFFER[i] = INPUT_BUFFER[i + 1];
    }

    INPUT_LEN -= 1;
    CURSOR_POS -= 1;

    // Reescrever linha
    rewrite_input(PROMPT_LEN, &INPUT_BUFFER, INPUT_LEN);
    set_cursor_x(PROMPT_LEN + CURSOR_POS);
}

/// Ponto de entrada do kernel (chamado pelo assembly)
#[no_mangle]
pub extern "C" fn kernel_main() -> ! {
    clear();
    print("Kernel Rust 64-bit iniciado!\n");
    prompt();

    loop {
        let c = read_key();

        unsafe {
            match c {
                b'\n' => {
                    putchar(b'\n');
                    INPUT_BUFFER[INPUT_LEN] = 0;

                    // Adicionar ao historico
                    add_to_history();

                    // Processar comando
                    let cmd = core::str::from_utf8_unchecked(&INPUT_BUFFER[..INPUT_LEN]);
                    process_cmd(cmd);

                    // Reset
                    INPUT_LEN = 0;
                    CURSOR_POS = 0;
                    HISTORY_INDEX = 0;
                    BROWSING_HISTORY = false;

                    prompt();
                }
                b'\x08' => {
                    // Backspace
                    delete_char();
                }
                KEY_LEFT => {
                    if CURSOR_POS > 0 {
                        CURSOR_POS -= 1;
                        set_cursor_x(PROMPT_LEN + CURSOR_POS);
                    }
                }
                KEY_RIGHT => {
                    if CURSOR_POS < INPUT_LEN {
                        CURSOR_POS += 1;
                        set_cursor_x(PROMPT_LEN + CURSOR_POS);
                    }
                }
                KEY_UP => {
                    if HISTORY_COUNT > 0 {
                        if !BROWSING_HISTORY {
                            BROWSING_HISTORY = true;
                            HISTORY_INDEX = 0;
                        } else if HISTORY_INDEX < HISTORY_COUNT - 1 {
                            HISTORY_INDEX += 1;
                        }
                        load_from_history(HISTORY_INDEX);
                    }
                }
                KEY_DOWN => {
                    if BROWSING_HISTORY && HISTORY_INDEX > 0 {
                        HISTORY_INDEX -= 1;
                        load_from_history(HISTORY_INDEX);
                    }
                }
                c if c >= b' ' && c < 0x80 => {
                    insert_char(c);
                    BROWSING_HISTORY = false;
                }
                _ => {}
            }
        }
    }
}

/// Handler de panic
#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    print("\n!!! KERNEL PANIC !!!\n");
    if let Some(location) = info.location() {
        print("Em: ");
        print(location.file());
        print("\n");
    }
    loop {}
}
