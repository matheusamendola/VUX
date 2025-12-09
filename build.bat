@echo off
REM Script de Build para Windows
REM Requer: NASM, i686-elf-gcc (cross-compiler), QEMU

echo ========================================
echo   Compilando Sistema Operacional
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
echo [3/4] Compilando kernel C...
i686-elf-gcc -m32 -ffreestanding -fno-pie -fno-stack-protector -nostdlib -nostdinc -Wall -Wextra -c kernel/kernel.c -o build/kernel.o
if errorlevel 1 (
    echo ERRO: Falha ao compilar kernel
    exit /b 1
)
echo       OK!

echo.
echo [4/4] Linkando kernel...
i686-elf-ld -m elf_i386 -T linker.ld --oformat binary -o build/kernel.bin build/kernel_entry.o build/kernel.o
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
