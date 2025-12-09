# Makefile para compilar o Bootloader e Kernel

# Ferramentas (ajuste conforme necessario)
ASM = nasm
CC = gcc
LD = ld

# Flags
ASM_FLAGS = -f bin
ASM_FLAGS_ELF = -f elf32
CFLAGS = -m32 -ffreestanding -fno-pie -fno-stack-protector -nostdlib -nostdinc -fno-builtin -Wall -Wextra -c
LDFLAGS = -m elf_i386 -T linker.ld --oformat binary

# Diretorios
BOOT_DIR = boot
KERNEL_DIR = kernel
BUILD_DIR = build

# Arquivos de saida
BOOTLOADER = $(BUILD_DIR)/boot.bin
KERNEL = $(BUILD_DIR)/kernel.bin
OS_IMAGE = $(BUILD_DIR)/os-image.bin

# Arquivos fonte
BOOT_SRC = $(BOOT_DIR)/boot.asm
KERNEL_ENTRY_SRC = $(KERNEL_DIR)/kernel_entry.asm
KERNEL_SRC = $(KERNEL_DIR)/kernel.c

# Arquivos objeto
KERNEL_ENTRY_OBJ = $(BUILD_DIR)/kernel_entry.o
KERNEL_OBJ = $(BUILD_DIR)/kernel.o

# Alvo padrao
all: $(BUILD_DIR) $(OS_IMAGE)

# Criar diretorio de build
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compilar bootloader
$(BOOTLOADER): $(BOOT_SRC)
	$(ASM) $(ASM_FLAGS) $< -o $@

# Compilar kernel entry (assembly)
$(KERNEL_ENTRY_OBJ): $(KERNEL_ENTRY_SRC)
	$(ASM) $(ASM_FLAGS_ELF) $< -o $@

# Compilar kernel (C)
$(KERNEL_OBJ): $(KERNEL_SRC)
	$(CC) $(CFLAGS) $< -o $@

# Linkar kernel
$(KERNEL): $(KERNEL_ENTRY_OBJ) $(KERNEL_OBJ)
	$(LD) $(LDFLAGS) -o $@ $^

# Criar imagem do OS (bootloader + kernel)
$(OS_IMAGE): $(BOOTLOADER) $(KERNEL)
	cat $(BOOTLOADER) $(KERNEL) > $@
	@# Padding para completar setores (opcional)
	@truncate -s 32768 $@ 2>/dev/null || true

# Executar no QEMU
run: $(OS_IMAGE)
	qemu-system-i386 -fda $(OS_IMAGE)

# Executar com debug (GDB)
debug: $(OS_IMAGE)
	qemu-system-i386 -fda $(OS_IMAGE) -s -S &
	@echo "QEMU aguardando conexao GDB na porta 1234"
	@echo "Execute: gdb -ex 'target remote localhost:1234'"

# Limpar arquivos gerados
clean:
	rm -rf $(BUILD_DIR)

# Mostrar informacoes
info:
	@echo "Bootloader: $(BOOTLOADER)"
	@echo "Kernel: $(KERNEL)"
	@echo "Imagem OS: $(OS_IMAGE)"

.PHONY: all run debug clean info
