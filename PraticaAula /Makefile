# Nome do executável
OUTPUT = program

# Todos os arquivos .asm no diretório
ASM_SRCS = $(wildcard *.asm)

# Gera os nomes de .o e .lst a partir dos .asm
OBJ_FILES = $(ASM_SRCS:.asm=.o)
LST_FILES = $(ASM_SRCS:.asm=.lst)

# Compilador NASM
ASM = nasm
ASMFLAGS = -f elf

# Linker
LD = ld
LDFLAGS = -m elf_i386

# Regra principal
all: $(OUTPUT)


# Vincula todos os .o em um binário
$(OUTPUT): $(OBJ_FILES)
	$(LD) $(LDFLAGS) -o $@ $^

# Compila cada .asm para .o e gera .lst
%.o: %.asm
	$(ASM) $(ASMFLAGS) -l $*.lst -o $@ $<

# Regra para executar o programa
run: clean all
	./$(OUTPUT)

# Limpa todos os arquivos gerados
clean:
	rm -f $(OBJ_FILES) $(OUTPUT) $(LST_FILES)