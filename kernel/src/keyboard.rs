//! Driver de teclado PS/2 com suporte a teclas especiais

use crate::io::inb;

/// Teclas especiais
pub const KEY_UP: u8 = 0x80;
pub const KEY_DOWN: u8 = 0x81;
pub const KEY_LEFT: u8 = 0x82;
pub const KEY_RIGHT: u8 = 0x83;

/// Mapa de scancodes para ASCII
static SCANCODE_MAP: [u8; 58] = [
    0, 27, b'1', b'2', b'3', b'4', b'5', b'6', b'7', b'8', b'9', b'0', b'-', b'=', b'\x08',
    b'\t', b'q', b'w', b'e', b'r', b't', b'y', b'u', b'i', b'o', b'p', b'[', b']', b'\n',
    0, b'a', b's', b'd', b'f', b'g', b'h', b'j', b'k', b'l', b';', b'\'', b'`',
    0, b'\\', b'z', b'x', b'c', b'v', b'b', b'n', b'm', b',', b'.', b'/', 0,
    b'*', 0, b' ',
];

/// Converte scancode para ASCII
fn scancode_to_ascii(sc: u8) -> u8 {
    if (sc as usize) < SCANCODE_MAP.len() {
        SCANCODE_MAP[sc as usize]
    } else {
        0
    }
}

/// Le uma tecla (bloqueante) - suporta teclas estendidas (setas)
pub fn read_key() -> u8 {
    loop {
        // Verifica se ha dados disponiveis
        if inb(0x64) & 1 != 0 {
            let scancode = inb(0x60);

            // Scancode estendido (0xE0 prefix)
            if scancode == 0xE0 {
                // Esperar pelo proximo byte
                while inb(0x64) & 1 == 0 {}
                let extended = inb(0x60);

                // Ignorar key release
                if extended & 0x80 != 0 {
                    continue;
                }

                // Mapear teclas estendidas
                match extended {
                    0x48 => return KEY_UP,
                    0x50 => return KEY_DOWN,
                    0x4B => return KEY_LEFT,
                    0x4D => return KEY_RIGHT,
                    _ => continue,
                }
            }

            // Ignora key release (bit 7 setado)
            if scancode & 0x80 == 0 {
                let ascii = scancode_to_ascii(scancode);
                if ascii != 0 {
                    return ascii;
                }
            }
        }
    }
}
