# Makefile para compilar o Bootloader e Kernel (Rust)

# Ferramentas
ASM = nasm
LD = ld

# Flags
ASM_FLAGS = -f bin
ASM_FLAGS_ELF = -f elf32
LDFLAGS = -m elf_i386 -T linker.ld --oformat binary --gc-sections

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

# Arquivos objeto
KERNEL_ENTRY_OBJ = $(BUILD_DIR)/kernel_entry.o
RUST_LIB = $(KERNEL_DIR)/target/i686-unknown-none/release/libkernel.a

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

# Compilar kernel Rust
$(RUST_LIB): FORCE
	cd $(KERNEL_DIR) && cargo build --release

# Linkar kernel
$(KERNEL): $(KERNEL_ENTRY_OBJ) $(RUST_LIB)
	$(LD) $(LDFLAGS) -o $@ $(KERNEL_ENTRY_OBJ) $(RUST_LIB)

# Criar imagem do OS (bootloader + kernel)
$(OS_IMAGE): $(BOOTLOADER) $(KERNEL)
	cat $(BOOTLOADER) $(KERNEL) > $@
	@# Padding para completar setores
	@truncate -s 32768 $@ 2>/dev/null || true

# Executar no QEMU
run: $(OS_IMAGE)
	qemu-system-i386 -drive format=raw,file=$(OS_IMAGE),index=0,if=floppy

# Executar com debug (GDB)
debug: $(OS_IMAGE)
	qemu-system-i386 -fda $(OS_IMAGE) -s -S &
	@echo "QEMU aguardando conexao GDB na porta 1234"
	@echo "Execute: gdb -ex 'target remote localhost:1234'"

# Limpar arquivos gerados
clean:
	rm -rf $(BUILD_DIR)
	-cd $(KERNEL_DIR) && cargo clean 2>/dev/null || rm -rf $(KERNEL_DIR)/target

# Mostrar informacoes
info:
	@echo "Bootloader: $(BOOTLOADER)"
	@echo "Kernel: $(KERNEL)"
	@echo "Imagem OS: $(OS_IMAGE)"
	@echo "Rust lib: $(RUST_LIB)"

FORCE:

.PHONY: all run debug clean info FORCE
