@echo off
REM Script de Build para Windows (Kernel em Rust)
REM Requer: NASM, Rust (nightly), i686-elf-ld ou lld, QEMU

echo ========================================
echo   Compilando Sistema Operacional (Rust)
echo ========================================

REM Criar diretorio de build
if not exist build mkdir build

echo.
echo [1/4] Compilando bootloader...
nasm -f bin boot/boot.asm -o build/boot.bin
if errorlevel 1 (
    echo ERRO: Falha ao compilar bootloader
    exit /b 1
)
echo       OK!

echo.
echo [2/4] Compilando kernel entry...
nasm -f elf32 kernel/kernel_entry.asm -o build/kernel_entry.o
if errorlevel 1 (
    echo ERRO: Falha ao compilar kernel entry
    exit /b 1
)
echo       OK!

echo.
echo [3/4] Compilando kernel Rust...
cd kernel
cargo build --release
if errorlevel 1 (
    echo ERRO: Falha ao compilar kernel Rust
    cd ..
    exit /b 1
)
cd ..
echo       OK!

echo.
echo [4/4] Linkando kernel...
REM Tente usar i686-elf-ld primeiro, senao use lld
where i686-elf-ld >nul 2>nul
if errorlevel 1 (
    REM Usar rust-lld
    rust-lld -flavor gnu -m elf_i386 -T linker.ld --oformat binary --gc-sections -o build/kernel.bin build/kernel_entry.o kernel/target/i686-unknown-none/release/libkernel.a
) else (
    i686-elf-ld -m elf_i386 -T linker.ld --oformat binary --gc-sections -o build/kernel.bin build/kernel_entry.o kernel/target/i686-unknown-none/release/libkernel.a
)
if errorlevel 1 (
    echo ERRO: Falha ao linkar kernel
    exit /b 1
)
echo       OK!

echo.
echo Criando imagem final...
copy /b build\boot.bin + build\kernel.bin build\os-image.bin >nul
echo       OK!

echo.
echo ========================================
echo   Build concluido com sucesso!
echo   Imagem: build\os-image.bin
echo ========================================
echo.
echo Para executar: qemu-system-i386 -fda build\os-image.bin
