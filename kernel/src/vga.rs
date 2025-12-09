//! Driver VGA em modo texto

use crate::io::outb;

const VGA_ADDRESS: u64 = 0xB8000;
const VGA_WIDTH: usize = 80;
const VGA_HEIGHT: usize = 25;
const COLOR_WHITE: u8 = 0x0F;

/// Estado global do cursor
static mut CURSOR_X: usize = 0;
static mut CURSOR_Y: usize = 0;

/// Retorna ponteiro para o buffer VGA
#[inline]
fn vga_buffer() -> *mut u16 {
    VGA_ADDRESS as *mut u16
}

/// Atualiza o cursor de hardware
pub fn update_cursor() {
    unsafe {
        let pos = CURSOR_Y * VGA_WIDTH + CURSOR_X;
        outb(0x3D4, 14);
        outb(0x3D5, (pos >> 8) as u8);
        outb(0x3D4, 15);
        outb(0x3D5, (pos & 0xFF) as u8);
    }
}

/// Rola a tela para cima se necessario
fn scroll() {
    unsafe {
        if CURSOR_Y >= VGA_HEIGHT {
            let vga = vga_buffer();
            // Move tudo uma linha para cima
            for i in 0..((VGA_HEIGHT - 1) * VGA_WIDTH) {
                *vga.add(i) = *vga.add(i + VGA_WIDTH);
            }
            // Limpa a ultima linha
            for i in ((VGA_HEIGHT - 1) * VGA_WIDTH)..(VGA_HEIGHT * VGA_WIDTH) {
                *vga.add(i) = (b' ' as u16) | ((COLOR_WHITE as u16) << 8);
            }
            CURSOR_Y = VGA_HEIGHT - 1;
        }
    }
}

/// Imprime um caractere na tela
pub fn putchar(c: u8) {
    unsafe {
        let vga = vga_buffer();

        match c {
            b'\n' => {
                CURSOR_X = 0;
                CURSOR_Y += 1;
            }
            b'\x08' => {
                // Backspace
                if CURSOR_X > 0 {
                    CURSOR_X -= 1;
                    let offset = CURSOR_Y * VGA_WIDTH + CURSOR_X;
                    *vga.add(offset) = (b' ' as u16) | ((COLOR_WHITE as u16) << 8);
                }
            }
            c if c >= b' ' => {
                let offset = CURSOR_Y * VGA_WIDTH + CURSOR_X;
                *vga.add(offset) = (c as u16) | ((COLOR_WHITE as u16) << 8);
                CURSOR_X += 1;
                if CURSOR_X >= VGA_WIDTH {
                    CURSOR_X = 0;
                    CURSOR_Y += 1;
                }
            }
            _ => {}
        }

        scroll();
        update_cursor();
    }
}

/// Imprime uma string na tela
pub fn print(s: &str) {
    for byte in s.bytes() {
        putchar(byte);
    }
}

/// Limpa a tela
pub fn clear() {
    unsafe {
        let vga = vga_buffer();
        for i in 0..(VGA_WIDTH * VGA_HEIGHT) {
            *vga.add(i) = (b' ' as u16) | ((COLOR_WHITE as u16) << 8);
        }
        CURSOR_X = 0;
        CURSOR_Y = 0;
        update_cursor();
    }
}
