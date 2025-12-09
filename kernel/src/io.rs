//! Funcoes de I/O para portas x86

use core::arch::asm;

/// Le um byte de uma porta I/O
#[inline(never)]
pub fn inb(port: u16) -> u8 {
    let result: u8;
    unsafe {
        asm!(
            "in al, dx",
            out("al") result,
            in("dx") port,
            options(nostack, preserves_flags)
        );
    }
    result
}

/// Escreve um byte em uma porta I/O
#[inline(never)]
pub fn outb(port: u16, data: u8) {
    unsafe {
        asm!(
            "out dx, al",
            in("dx") port,
            in("al") data,
            options(nostack, preserves_flags)
        );
    }
}

/// Escreve uma word (16 bits) em uma porta I/O
#[inline(never)]
pub fn outw(port: u16, data: u16) {
    unsafe {
        asm!(
            "out dx, ax",
            in("dx") port,
            in("ax") data,
            options(nostack, preserves_flags)
        );
    }
}
