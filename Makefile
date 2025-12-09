# Makefile para compilar o Bootloader e Kernel 64-bit (Rust)

# Ferramentas
ASM = nasm
LD = ld

# Flags
ASM_FLAGS = -f bin
ASM_FLAGS_ELF = -f elf64
LDFLAGS = -m elf_x86_64 -T linker.ld --oformat binary --gc-sections

# Diretorios
BOOT_DIR = boot
KERNEL_DIR = kernel
BUILD_DIR = build

# Arquivos de saida
BOOTLOADER = $(BUILD_DIR)/boot.bin
STAGE2 = $(BUILD_DIR)/stage2.bin
KERNEL = $(BUILD_DIR)/kernel.bin
OS_IMAGE = $(BUILD_DIR)/os-image.bin

# Arquivos fonte
BOOT_SRC = $(BOOT_DIR)/boot.asm
STAGE2_SRC = $(BOOT_DIR)/stage2.asm
KERNEL_ENTRY_SRC = $(KERNEL_DIR)/kernel_entry.asm

# Arquivos objeto
KERNEL_ENTRY_OBJ = $(BUILD_DIR)/kernel_entry.o
RUST_LIB = $(KERNEL_DIR)/target/x86_64-unknown-none/release/libkernel.a

# Alvo padrao
all: $(BUILD_DIR) $(OS_IMAGE)

# Criar diretorio de build
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compilar bootloader stage 1 (512 bytes)
$(BOOTLOADER): $(BOOT_SRC)
	$(ASM) $(ASM_FLAGS) $< -o $@

# Compilar stage 2 (2048 bytes = 4 setores)
$(STAGE2): $(STAGE2_SRC)
	$(ASM) $(ASM_FLAGS) $< -o $@

# Compilar kernel entry (assembly 64-bit)
$(KERNEL_ENTRY_OBJ): $(KERNEL_ENTRY_SRC)
	$(ASM) $(ASM_FLAGS_ELF) $< -o $@

# Compilar kernel Rust
$(RUST_LIB): FORCE
	cd $(KERNEL_DIR) && cargo build --release

# Linkar kernel
$(KERNEL): $(KERNEL_ENTRY_OBJ) $(RUST_LIB)
	$(LD) $(LDFLAGS) -o $@ $(KERNEL_ENTRY_OBJ) $(RUST_LIB)

# Criar imagem do OS
# Layout: boot(512) + stage2(2048) + kernel
# Setor 1: boot, Setores 2-5: stage2, Setores 6+: kernel
$(OS_IMAGE): $(BOOTLOADER) $(STAGE2) $(KERNEL)
	cat $(BOOTLOADER) $(STAGE2) $(KERNEL) > $@
	truncate -s 131072 $@

# Executar no QEMU (64-bit)
run: $(OS_IMAGE)
	qemu-system-x86_64 -drive format=raw,file=$(OS_IMAGE),index=0,if=floppy

# Executar com debug (GDB)
debug: $(OS_IMAGE)
	qemu-system-x86_64 -drive format=raw,file=$(OS_IMAGE),index=0,if=floppy -s -S &
	@echo "QEMU aguardando conexao GDB na porta 1234"

# Limpar arquivos gerados
clean:
	rm -rf $(BUILD_DIR)
	-cd $(KERNEL_DIR) && cargo clean 2>/dev/null || rm -rf $(KERNEL_DIR)/target

info:
	@echo "Layout da imagem:"
	@echo "  Setor 1:    Boot (512 bytes)"
	@echo "  Setores 2-5: Stage2 (2048 bytes)"
	@echo "  Setores 6+:  Kernel"

FORCE:

.PHONY: all run debug clean info FORCE
