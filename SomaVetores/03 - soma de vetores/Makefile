# Nome do executável
OUTPUT = program

# Arquivos .asm e .c no diretório
ASM_SRCS = $(wildcard *.asm)
C_SRCS   = $(wildcard *.c)

# Gera os nomes de .o e .lst a partir dos .asm e .c
ASM_OBJS = $(ASM_SRCS:.asm=.o)
C_OBJS   = $(C_SRCS:.c=.o)
OBJ_FILES = $(ASM_OBJS) $(C_OBJS)
LST_FILES = $(ASM_SRCS:.asm=.lst)

# Compilador NASM
ASM = nasm
ASMFLAGS = -f elf64

# Compilador C
CC = gcc
CFLAGS = -Wall -c

# Regra principal
all: $(OUTPUT)

# Vincula tudo com gcc em modo 64 bits
$(OUTPUT): $(OBJ_FILES)
	$(CC) -o $@ $^

# Compila cada .asm em .o e gera .lst
%.o: %.asm
	$(ASM) $(ASMFLAGS) -l $*.lst -o $@ $<

# Compila cada .c em .o
%.o: %.c
	$(CC) $(CFLAGS) -o $@ $<

# Executa
run: all
	./$(OUTPUT)

# Limpa arquivos gerados
clean:
	rm -f $(OBJ_FILES) $(OUTPUT) $(LST_FILES)

