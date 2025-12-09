# Mini OS

Sistema operacional minimalista com kernel escrito em Rust, rodando em modo protegido i386.

## Funcionalidades

- Bootloader customizado em Assembly x86
- Kernel em Rust (no_std)
- CLI interativa com comandos
- Driver VGA em modo texto (80x25)
- Driver de teclado PS/2

## Comandos Disponíveis

| Comando | Descrição |
|---------|-----------|
| `help` | Mostra lista de comandos |
| `clear` / `cls` | Limpa a tela |
| `echo <texto>` | Imprime texto na tela |
| `reboot` | Reinicia o sistema |
| `shutdown` | Desliga o sistema (QEMU) |

## Requisitos

### Linux / WSL
```bash
# Rust nightly
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup default nightly
rustup component add rust-src llvm-tools-preview

# NASM e QEMU
sudo apt install nasm qemu-system-x86
```

### Windows
- [Rust](https://rustup.rs) (nightly)
- [NASM](https://www.nasm.us)
- [QEMU](https://www.qemu.org/download/#windows)

## Compilar e Executar

### Linux / WSL
```bash
make clean && make && make run
```

### Windows
```batch
build.bat
qemu-system-i386 -drive format=raw,file=build/os-image.bin,index=0,if=floppy
```

### VS Code
Pressione `Ctrl+Shift+B` para compilar e executar.

## Estrutura do Projeto

```
OS/
├── boot/
│   └── boot.asm              # Bootloader (16-bit -> 32-bit)
├── kernel/
│   ├── kernel_entry.asm      # Entry point (chama kernel_main)
│   ├── src/
│   │   ├── lib.rs            # Kernel principal
│   │   ├── io.rs             # I/O de portas x86
│   │   ├── vga.rs            # Driver VGA
│   │   ├── keyboard.rs       # Driver de teclado
│   │   └── commands.rs       # Sistema de comandos
│   ├── Cargo.toml
│   ├── .cargo/config.toml
│   └── rust-toolchain.toml
├── i686-unknown-none.json    # Target spec customizado
├── linker.ld                 # Script do linker
├── Makefile                  # Build para Linux/WSL
└── build.bat                 # Build para Windows
```

## Como Funciona

1. **BIOS** carrega o bootloader (primeiro setor do disco) em `0x7C00`
2. **Bootloader** (`boot.asm`):
   - Carrega o kernel do disco para `0x1000`
   - Configura a GDT (Global Descriptor Table)
   - Muda para modo protegido 32-bit
   - Salta para o kernel
3. **Kernel Entry** (`kernel_entry.asm`):
   - Define `_start` como ponto de entrada
   - Chama `kernel_main()` do Rust
4. **Kernel Rust** (`lib.rs`):
   - Inicializa VGA e limpa a tela
   - Loop infinito lendo teclado e processando comandos

## Mapa de Memória

| Endereço | Conteúdo |
|----------|----------|
| `0x0000 - 0x7BFF` | Área livre / Stack |
| `0x7C00 - 0x7DFF` | Bootloader (512 bytes) |
| `0x1000 - ...` | Kernel |
| `0xB8000` | Buffer VGA (texto) |

## Licença

MIT
