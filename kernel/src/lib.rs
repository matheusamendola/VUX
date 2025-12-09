//! Kernel em Rust - CLI simples
//!
//! Este kernel implementa uma interface de linha de comando basica
//! rodando em modo protegido i386.

#![no_std]
#![no_main]

mod io;
mod vga;
mod keyboard;
mod commands;

use core::panic::PanicInfo;
use vga::{print, clear, putchar};
use keyboard::read_key;
use commands::process_cmd;

/// Buffer de entrada
static mut INPUT_BUFFER: [u8; 256] = [0; 256];
static mut INPUT_POS: usize = 0;

/// Imprime o prompt
fn prompt() {
    print("> ");
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
                    INPUT_BUFFER[INPUT_POS] = 0;

                    // Converte buffer para string
                    let cmd = core::str::from_utf8_unchecked(&INPUT_BUFFER[..INPUT_POS]);
                    process_cmd(cmd);

                    INPUT_POS = 0;
                    prompt();
                }
                b'\x08' => {
                    // Backspace
                    if INPUT_POS > 0 {
                        INPUT_POS -= 1;
                        putchar(b'\x08');
                    }
                }
                c if c != 0 && INPUT_POS < 255 => {
                    INPUT_BUFFER[INPUT_POS] = c;
                    INPUT_POS += 1;
                    putchar(c);
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
