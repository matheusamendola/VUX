# Mini OS

Sistema operacional minimalista com kernel escrito em Rust, rodando em Long Mode x86_64 (64-bit).

## Funcionalidades

- Bootloader customizado em Assembly x86 com Long Mode
- Kernel em Rust (no_std) 64-bit
- Paginação com páginas de 2MB (huge pages)
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
qemu-system-x86_64 -drive format=raw,file=build/os-image.bin,index=0,if=floppy
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
├── x86_64-unknown-none.json  # Target spec customizado (64-bit)
├── linker.ld                 # Script do linker
├── Makefile                  # Build para Linux/WSL
└── build.bat                 # Build para Windows
```

## Como Funciona

1. **BIOS** carrega o bootloader (primeiro setor do disco) em `0x7C00`
2. **Bootloader** (`boot.asm`):
   - Carrega o kernel do disco para `0x1000`
   - Verifica suporte a Long Mode (CPUID)
   - Configura GDT 32-bit temporária
   - Muda para modo protegido 32-bit
   - Configura page tables (PML4 -> PDPT -> PDT com 2MB pages)
   - Ativa PAE e Long Mode no EFER MSR
   - Carrega GDT 64-bit
   - Salta para o kernel em Long Mode
3. **Kernel Entry** (`kernel_entry.asm`):
   - Define `_start` como ponto de entrada (64-bit)
   - Limpa registradores
   - Chama `kernel_main()` do Rust
4. **Kernel Rust** (`lib.rs`):
   - Inicializa VGA e limpa a tela
   - Loop infinito lendo teclado e processando comandos

## Mapa de Memória

| Endereço | Conteúdo |
|----------|----------|
| `0x0000 - 0x0FFF` | Área reservada |
| `0x1000 - ...` | Kernel |
| `0x7C00 - 0x7DFF` | Bootloader (512 bytes) |
| `0x70000 - 0x72FFF` | Page Tables (PML4, PDPT, PDT) |
| `0x90000` | Stack (cresce para baixo) |
| `0xB8000` | Buffer VGA (texto) |

## Paginação

O bootloader configura paginação com páginas de 2MB (huge pages):
- PML4[0] -> PDPT em 0x71000
- PDPT[0] -> PDT em 0x72000
- PDT[0-3] -> 4 páginas de 2MB (0-8MB mapeados)

## Licença

MIT
